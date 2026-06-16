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
crust=$(expand "#{@thm_crust}")
fg=$(expand "#{@thm_fg}")
flags=$(expand "#{@_tmx_w_flags}")

# Shape glyphs (octal UTF-8). squared has none — the block padding is its edge.
case "$shape" in
  rounded) lglyph=$(printf '\356\202\266'); rglyph=$(printf '\356\202\264') ;;
  slanted) lglyph=$(printf '\356\202\272'); rglyph=$(printf '\356\202\274') ;;
  *)       lglyph=""; rglyph="" ;;
esac
# The notch seam mirrors the shape's right cap; left layout only (like panes).
seam_glyph=""
[ "$notch" = on ] && case "$shape" in
  slanted) seam_glyph=$(printf '\356\202\274') ;;
  rounded) seam_glyph=$(printf '\356\202\264') ;;
  squared) seam_glyph=$(printf '\342\226\210') ;;
esac

# A cap is the shape glyph over the bare bar in a block's colour (empty glyph ->
# none). cap_col falls back to the accent when a block is transparent (naked).
cap() { [ -n "$1" ] && printf '#[fg=%s,bg=default]%s' "$2" "$1"; }

# Render one side. $1: var prefix (w|cw); $2: option infix (""|current_).
render_side() {
  local p="$1" o="$2"
  local accent surface ibg ifg tbg tfg icap tcap number text seam lcap rcap nblock nameblock
  accent=$(expand "#{E:@themux_window_${o}number_color}")
  surface=$(expand "#{E:@themux_window_${o}text_color}")
  resolve_style "$indicator" "$accent" "$surface" "$crust" "$fg"
  ibg="$RS_BG" ifg="$RS_FG"
  resolve_style "$name_style" "$accent" "$surface" "$crust" "$fg"
  tbg="$RS_BG" tfg="$RS_FG"
  icap="$ibg"; [ "$ibg" = default ] && icap="$accent"
  tcap="$tbg"; [ "$tbg" = default ] && tcap="$accent"
  number=$(expand "#{@themux_window_${o}number}")
  text="#{E:@_tmx_${p}_text}" # draw-time; "" when the name is hidden

  nblock="#[fg=$ifg,bg=$ibg] $number "

  if [ "$position" = left ]; then
    # number block, then the name block (only when the window has a name). The
    # right cap follows the rightmost block: the name bg when a name shows, the
    # number bg when it does not.
    lcap=$(cap "$lglyph" "$icap")
    seam=""
    [ -n "$seam_glyph" ] && [ "$ibg" != "$tbg" ] && seam="#[fg=$icap,bg=$tbg]$seam_glyph"
    nameblock="#{?${text},${seam}#[fg=$tfg,bg=$tbg] ${text} ,}"
    rcap=$(cap "$rglyph" "#{?${text},${tcap},${icap}}")
    printf '%s%s%s%s%s' "$lcap" "$nblock" "$nameblock" "$flags" "$rcap"
  elif [ -n "$(tmux show -gqv "@_tmx_${p}_text")" ]; then
    # number on the right: name block first, then the number block.
    lcap=$(cap "$lglyph" "$tcap")
    nameblock="#[fg=$tfg,bg=$tbg] ${text} "
    rcap=$(cap "$rglyph" "$icap")
    printf '%s%s%s%s%s' "$lcap" "$nameblock" "$flags" "$nblock" "$rcap"
  else
    # number on the right, no name: just the number block.
    lcap=$(cap "$lglyph" "$icap")
    rcap=$(cap "$rglyph" "$icap")
    printf '%s%s%s%s' "$lcap" "$nblock" "$flags" "$rcap"
  fi
}

tmux set -g window-status-format "$(render_side w "")"
tmux set -g window-status-current-format "$(render_side cw current_)"

tmux set -gu @_tmx_render_tmp
tmux set -ug @_tmx_w_flags
exit 0
