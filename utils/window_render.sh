#!/usr/bin/env bash
# Assemble window-status-format and window-status-current-format from the v3
# props @themux_window_{shape,indicator,name,notch}, mirroring pane_render.sh:
# the indicator (number) and name blocks are styled independently through the
# shared resolver. The two sides differ only by their accent/surface brightness
# (inactive: number_color/text_color; active: current_number_color/
# current_text_color). Load-time colours are resolved now; draw-time refs (the
# per-window name, its visibility) stay literal #{...} for tmux to resolve.

# shellcheck source=render_style.sh
. "$(dirname "$0")/render_style.sh"

expand() {
  tmux set -gF @_tmx_render_tmp "$1"
  tmux show -gv @_tmx_render_tmp
}

position=$(tmux show -gqv @themux_window_number_position)
indicator=$(tmux show -gqv @themux_window_indicator)
name_style=$(tmux show -gqv @themux_window_name)
notch=$(tmux show -gqv @themux_window_notch)
shape=$(tmux show -gqv @themux_window_shape)
# Active highlight per part/channel (off|bg|fg|both, default both): which of the
# active window's colours actually switch; the rest stay frozen at the inactive
# colour. Applied only to the active side (cw), mixing active vs inactive below.
ind_hl=$(tmux show -gqv @themux_window_indicator_highlight); [ -n "$ind_hl" ] || ind_hl=both
txt_hl=$(tmux show -gqv @themux_window_text_highlight); [ -n "$txt_hl" ] || txt_hl=both
crust=$(expand "#{@thm_crust}")
fg=$(expand "#{@thm_fg}")
flags=$(expand "#{@_tmx_w_flags}")

# Shape glyphs (octal UTF-8). squared has none — the block padding is its edge.
case "$shape" in
  rounded) lglyph=$(printf '\356\202\266'); rglyph=$(printf '\356\202\264') ;;
  slanted) lglyph=$(printf '\356\202\272'); rglyph=$(printf '\356\202\274') ;;
  *)       lglyph=""; rglyph="" ;;
esac

# Connected (powerline) ribbon: when the inter-window divider is emptied and the
# shape has caps (rounded/slanted, left numbers), windows draw blocks only and a
# neighbour-aware separator carries the seam. tmux exposes active_window_index
# inside #{W:}, so each window knows whether its neighbour is the active one;
# that lets the seam be bi-coloured (gapless) and the active window's caps overlay
# both neighbours, so it reads as raised. Index math (window_index ± 1) assumes
# contiguous indices — pair with `renumber-windows on` to avoid gaps.
divider=$(tmux show -gqv @themux_window_divider)
connected=0
[ -z "$divider" ] && [ -n "$lglyph" ] && [ "$position" = left ] && connected=1
# First window index (for the ribbon's opening left cap). With contiguous indices
# it is base-index; baked as a literal so the draw-time test stays cheap.
base=$(tmux show -gwv base-index 2>/dev/null); [ -n "$base" ] || base=0
# The notch seam mirrors the shape's right cap; left layout only (like panes).
seam_glyph=""
[ "$notch" = on ] && case "$shape" in
  slanted) seam_glyph=$(printf '\356\202\274') ;;
  rounded) seam_glyph=$(printf '\356\202\264') ;;
  squared) seam_glyph=$(printf '\342\226\210') ;;
esac

# A cap. With a glyph (rounded/slanted) it is the shape glyph over the bare bar
# in the cap colour $2 ($2 falls back to the accent when a block is naked). With
# no glyph (squared) it is an equal-width colour pad in the block bg $3, so a
# squared window matches the other shapes' cap width — a default $3 (naked) keeps
# the pad transparent.
cap() {
  if [ -n "$1" ]; then
    printf '#[fg=%s,bg=default]%s' "$2" "$1"
  else
    printf '#[bg=%s] ' "$3"
  fi
}

# Render one side into option $3. $1: var prefix (w|cw); $2: option infix
# (""|current_). Sets the option directly (no command substitution) so the cap
# colours it stashes survive for the connected separator built afterwards.
render_side() {
  local p="$1" o="$2" opt="$3"
  local accent surface ibg ifg tbg tfg icap tcap number text seam lcap rcap nblock nameblock out
  # Per-part accents over a shared surface (mirrors pane_render): the number and
  # name each resolve from their own accent; the inactive side uses the base
  # colours, the active side the _highlight_color variants (the toggles below
  # then freeze the channels they exclude).
  local ind_acc txt_acc
  if [ "$p" = w ]; then
    ind_acc=$(expand "#{E:@themux_window_indicator_color}")
    txt_acc=$(expand "#{E:@themux_window_text_color}")
  else
    ind_acc=$(expand "#{E:@themux_window_indicator_highlight_color}")
    txt_acc=$(expand "#{E:@themux_window_text_highlight_color}")
  fi
  surface=$(expand "#{E:@themux_window_background_color}")
  resolve_style "$indicator" "$ind_acc" "$surface" "$crust" "$fg"
  ibg="$RS_BG" ifg="$RS_FG"
  resolve_style "$name_style" "$txt_acc" "$surface" "$crust" "$fg"
  tbg="$RS_BG" tfg="$RS_FG"
  icap="$ibg"; [ "$ibg" = default ] && icap="$accent"
  tcap="$tbg"; [ "$tbg" = default ] && tcap="$accent"
  number=$(expand "#{@themux_window_${o}number}")
  text="#{E:@_tmx_${p}_text}" # draw-time; "" when the name is hidden

  # The inactive side is the baseline; the active side freezes the channels the
  # highlight toggles exclude back to it (icap/tcap track the bg channel, since
  # they are the block colour). Colours are stashed for the connected separator.
  if [ "$p" = w ]; then
    W_IBG="$ibg" W_IFG="$ifg" W_TBG="$tbg" W_TFG="$tfg" W_ICAP="$icap" W_TCAP="$tcap"
  else
    case "$ind_hl" in
      bg)  ifg="$W_IFG" ;;
      fg)  ibg="$W_IBG" icap="$W_ICAP" ;;
      off) ibg="$W_IBG" ifg="$W_IFG" icap="$W_ICAP" ;;
    esac
    case "$txt_hl" in
      bg)  tfg="$W_TFG" ;;
      fg)  tbg="$W_TBG" tcap="$W_TCAP" ;;
      off) tbg="$W_TBG" tfg="$W_TFG" tcap="$W_TCAP" ;;
    esac
    CW_ICAP="$icap" CW_TCAP="$tcap"
  fi

  nblock="#[fg=$ifg,bg=$ibg] $number "

  if [ "$position" = left ]; then
    # number block, then the name block (only when the window has a name). The
    # right cap follows the rightmost block: the name bg when a name shows, the
    # number bg when it does not.
    seam=""
    # Styles inside the #{?name,...} conditional must not carry a literal comma
    # (#{?} splits on commas), so set fg and bg as separate #[...] directives.
    [ -n "$seam_glyph" ] && [ "$ibg" != "$tbg" ] && seam="#[fg=$icap]#[bg=$tbg]$seam_glyph"
    nameblock="#{?${text},${seam}#[fg=$tfg]#[bg=$tbg]${text} ,}"
    if [ "$connected" = 1 ]; then
      # Inner seams come from the separator. The first window opens the ribbon
      # with a left cap and the last closes it with a tail cap, both over the bar.
      lcap="#{?#{==:#{window_index},${base}},#[fg=${icap}]#[bg=default]${lglyph},}"
      rcap="#{?loop_last_flag,#[fg=#{?${text},${tcap},${icap}}]#[bg=default]${rglyph},}"
      out="${lcap}${nblock}${nameblock}${flags}${rcap}"
    else
      lcap=$(cap "$lglyph" "$icap" "$ibg")
      rcap=$(cap "$rglyph" "#{?${text},${tcap},${icap}}" "#{?${text},${tbg},${ibg}}")
      out="${lcap}${nblock}${nameblock}${flags}${rcap}"
    fi
  elif [ -n "$(tmux show -gqv "@_tmx_${p}_text")" ]; then
    # number on the right: name block first, then the number block.
    lcap=$(cap "$lglyph" "$tcap" "$tbg")
    nameblock="#[fg=$tfg,bg=$tbg]${text} "
    rcap=$(cap "$rglyph" "$icap" "$ibg")
    out="${lcap}${nameblock}${flags}${nblock}${rcap}"
  else
    # number on the right, no name: just the number block.
    lcap=$(cap "$lglyph" "$icap" "$ibg")
    rcap=$(cap "$rglyph" "$icap" "$ibg")
    out="${lcap}${nblock}${flags}${rcap}"
  fi
  tmux set -g "$opt" "$out"
}

render_side w "" window-status-format
render_side cw current_ window-status-current-format

# Neighbour-aware separator for the connected ribbon. Drawn after each window in
# that window's draw context, so window_active is the left window and a small
# index check tells whether the right window is the active one:
#   - left window active  -> its right cap (active colour) bulges over the next
#   - right window active  -> the active's left cap bulges back over this window
#   - neither             -> a plain inactive->inactive taper
# All four colours are known (the off side is always the opposite active state,
# and both states' colours are theme constants), so the seam is gapless and the
# active window's caps overlay both neighbours (raised).
if [ "$connected" = 1 ]; then
  w_rcol="#{?#{E:@_tmx_w_text},${W_TCAP},${W_ICAP}}"   # this (inactive) window's right colour
  cw_rcol="#{?#{E:@_tmx_cw_text},${CW_TCAP},${CW_ICAP}}" # the active window's right colour
  nextact="#{==:#{active_window_index},#{e|+:#{window_index},1}}"
  sep="#{?window_active,"
  sep+="#[fg=${cw_rcol}]#[bg=${W_ICAP}]${rglyph},"
  sep+="#{?${nextact},"
  sep+="#[fg=${CW_ICAP}]#[bg=${w_rcol}]${lglyph},"
  sep+="#[fg=${w_rcol}]#[bg=${W_ICAP}]${rglyph}"
  sep+="}}"
  tmux set -g window-status-separator "$sep"
fi

tmux set -gu @_tmx_render_tmp
tmux set -ug @_tmx_w_flags
exit 0
