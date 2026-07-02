#!/usr/bin/env bash
# Assemble window-status-format and window-status-current-format from the variant
# grammar @themux_window_{shape,leading_variant,text_variant,notch}, mirroring
# pane_render.sh: the leading (number) and name blocks are styled independently
# through the shared resolver. The two sides each resolve their OWN variant +
# accent — the inactive side from _leading_variant/_leading_color, the active
# (current) side from _leading_active_variant/_leading_active_color — so the
# active state is just a second appearance, with no per-channel toggles.
# Load-time colours are resolved now; draw-time refs (the per-window name, its
# visibility) stay literal #{...} for tmux to resolve.

# shellcheck source=render_style.sh
. "$(dirname "$0")/render_style.sh"

expand() {
  tmux set -gF @_tmx_render_tmp "$1"
  tmux show -gv @_tmx_render_tmp
}

position=$(themux_prop window leading_position)
leading=$(themux_prop window leading_variant)
name_style=$(themux_prop window text_variant)
leading_active=$(themux_prop window leading_active_variant)
name_active=$(themux_prop window text_active_variant)
# The active variant defaults to the resting one (same shape, colour swaps only).
[ -n "$leading_active" ] || leading_active="$leading"
[ -n "$name_active" ] || name_active="$name_style"
notch=$(themux_prop window notch)
shape=$(themux_prop window shape)
# Badge padding (@themux_window_padding):
# "<leading-left> <leading-right>|<text-left> <text-right>".
read -r pleft pright tleft tright <<<"$(pad_parse "$(themux_prop window padding)")"
crust=$(expand "#{@thm_crust}")
fg=$(expand "#{@thm_fg}")
flags=$(expand "#{@_tmx_w_flags}")
surface=$(expand "#{E:@themux_window_background_color}")

# Shape glyphs (octal UTF-8). squared has none — the block padding is its edge.
case "$shape" in
  rounded)   lglyph=$(printf '\356\202\266'); rglyph=$(printf '\356\202\264') ;;
  slanted)   lglyph=$(printf '\356\202\272'); rglyph=$(printf '\356\202\274') ;;
  powerline) lglyph=$(printf '\356\202\262'); rglyph=$(printf '\356\202\260') ;;
  *)         lglyph=""; rglyph="" ;;
esac

# Connected (powerline) ribbon: @themux_window_seam (mirrors the module connector
# vocabulary, symbols only) picks how adjacent windows meet — | separate pills
# (default, like a plain space between modules), <> raised (the active window's
# caps overlay both neighbours), > right, < left, = flat. Any value but | joins
# the list into one ribbon (needs a capped shape + left numbers, else it falls
# back to separate pills). When connected, windows draw blocks only and
# window-status-separator carries the seam; tmux exposes active_window_index
# inside #{W:}, so each window knows whether its neighbour is active — that lets
# the raised seam be bi-coloured (gapless). Index math (window_index ± 1) assumes
# contiguous indices — pair with `renumber-windows on` to avoid gaps.
wseam=$(tmux show -gqv @themux_window_seam); [ -n "$wseam" ] || wseam='|'
connected=0
[ "$wseam" != "|" ] && [ -n "$lglyph" ] && [ "$position" = left ] && connected=1
# First window index (for the ribbon's opening left cap). With contiguous indices
# it is base-index; baked as a literal so the draw-time test stays cheap.
base=$(tmux show -gwv base-index 2>/dev/null); [ -n "$base" ] || base=0
# Seam glyphs, direction-aware (octal UTF-8, mirrors utils/module_render.sh and
# utils/pane_render.sh): gt tapers the visually-first block's colour into the
# second via the shape's right cap; lt mirrors it, the second block's colour into
# the first via the left cap. Squared has no outer cap (lglyph/rglyph above are
# empty there), but the seam still draws a full block — same glyph both
# directions, only its colours differ.
case "$shape" in
  rounded)   seam_lglyph=$(printf '\356\202\266'); seam_rglyph=$(printf '\356\202\264') ;;
  slanted)   seam_lglyph=$(printf '\356\202\272'); seam_rglyph=$(printf '\356\202\274') ;;
  powerline) seam_lglyph=$(printf '\356\202\262'); seam_rglyph=$(printf '\356\202\260') ;;
  squared)   seam_lglyph=$(printf '\342\226\210'); seam_rglyph=$(printf '\342\226\210') ;;
  *)         seam_lglyph=""; seam_rglyph="" ;;
esac
mode=$(themux_notch_mode "$notch")

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

# Render one side into the stock tmux option plus four hidden variants consumed
# by the status-line grammar's `windows` token. The hidden variants differ only
# in the OUTER edge caps: none/left/right/both. That keeps edge flushing local to
# the `=` marker that selected this specific window-list occurrence instead of a
# global @_tmx_win_flush_left/right flag that leaks across rows.
#
# $1: var prefix (w|cw); $2: option infix (""|current_); $3: stock tmux option;
# $4: hidden option prefix (@_tmx_wfmt|@_tmx_cwfmt). Sets options directly (no
# command substitution) so cap colours survive for the connected separator.
# Each side resolves its own variant + accent: the inactive side the resting
# ones, the active side the _active_ ones — independent, so no channel is frozen.
render_side() {
  local p="$1" o="$2" opt="$3" prefix="$4"
  local lvar tvar lead_acc txt_acc ibg ifg tbg tfg icap tcap number text seam nblock nameblock
  local first_cap last_cap raw_lcap raw_rcap flags_out none_out left_out right_out both_out
  local fbg sbg fcap scap gt_txt lt_txt
  if [ "$p" = w ]; then
    lvar="$leading" tvar="$name_style"
    lead_acc=$(expand "#{E:@themux_window_leading_color}")
    txt_acc=$(expand "#{E:@themux_window_text_color}")
  else
    lvar="$leading_active" tvar="$name_active"
    lead_acc=$(expand "#{E:@themux_window_leading_active_color}")
    txt_acc=$(expand "#{E:@themux_window_text_active_color}")
  fi
  resolve_style "$lvar" "$lead_acc" "$surface" "$crust" "$fg"
  ibg="$RS_BG" ifg="$RS_FG"
  resolve_style "$tvar" "$txt_acc" "$surface" "$crust" "$fg"
  tbg="$RS_BG" tfg="$RS_FG"
  icap="$ibg"; [ "$ibg" = default ] && icap="$lead_acc"
  tcap="$tbg"; [ "$tbg" = default ] && tcap="$txt_acc"
  number=$(expand "#{@themux_window_${o}number}")
  text="#{E:@_tmx_${p}_text}" # draw-time; "" when the name is hidden

  # Notch seam: the block that is visually first tapers into the second (gt) or
  # vice versa (lt), gated on the two blocks actually differing — same bg would
  # render an invisible phantom cell. Block order follows position, like
  # utils/module_render.sh: left -> number first, name second; right -> reversed.
  # Style directives stay as two independent #[...] escapes (no comma) so the
  # seam is safe wherever it lands inside a #{?name,...,} conditional (a literal
  # comma there would be read as a branch separator, not a style attribute).
  # gt/lt bake directly; auto dispatches at draw time on the hidden global
  # @_tmx_window_notch_dir that utils/layout.sh sets per occurrence (left->gt,
  # right->lt) — window-status-format is ONE shared option, so this cannot
  # resolve per zone the way a module's marker splice does; last write wins if
  # "windows" appears in more than one zone (documented in the options/docs).
  seam=""
  if [ -n "$seam_rglyph" ]; then
    if [ "$position" = right ]; then fbg="$tbg" fcap="$tcap" sbg="$ibg" scap="$icap"
    else fbg="$ibg" fcap="$icap" sbg="$tbg" scap="$tcap"; fi
    if [ "$fbg" != "$sbg" ]; then
      gt_txt="#[fg=$fcap]#[bg=$sbg]$seam_rglyph"
      lt_txt="#[fg=$scap]#[bg=$fbg]$seam_lglyph"
      case "$mode" in
        gt)   seam="$gt_txt" ;;
        lt)   seam="$lt_txt" ;;
        auto) seam="#{?#{==:#{@_tmx_window_notch_dir},gt},${gt_txt},#{?#{==:#{@_tmx_window_notch_dir},lt},${lt_txt},}}" ;;
      esac
    fi
  fi

  # Cap colours are stashed for the connected separator (the bg channel is the
  # block colour, or the accent the block uses when transparent/naked).
  if [ "$p" = w ]; then
    W_ICAP="$icap" W_TCAP="$tcap" W_IBG="$ibg" W_TBG="$tbg"
  else
    CW_ICAP="$icap" CW_TCAP="$tcap" CW_IBG="$ibg" CW_TBG="$tbg"
  fi

  nblock="#[fg=$ifg,bg=$ibg]$(spaces "$pleft")$number$(spaces "$pright")"

  if [ "$position" = left ]; then
    # number block, then the name block (only when the window has a name). The
    # right cap follows the rightmost block: the name bg when a name shows, the
    # number bg when it does not.
    nameblock="#{?${text},${seam}#[fg=$tfg]#[bg=$tbg]$(spaces "$tleft")${text}$(spaces "$tright"),}"
    if [ "$connected" = 1 ]; then
      # Inner seams come from the separator. The first window opens the ribbon
      # with a left cap and the last closes it with a tail cap, both over the bar
      # — each can be dropped by choosing the left/right/both hidden variant.
      first_cap="#{?#{==:#{window_index},${base}},#[fg=${icap}]#[bg=default]${lglyph},}"
      last_cap="#{?loop_last_flag,#[fg=#{?${text},${tcap},${icap}}]#[bg=default]${rglyph},}"
    else
      raw_lcap=$(cap "$lglyph" "$icap" "$ibg")
      raw_rcap=$(cap "$rglyph" "#{?${text},${tcap},${icap}}" "#{?${text},${tbg},${ibg}}")
      first_cap="$raw_lcap"
      last_cap="$raw_rcap"
    fi
    flags_out="${nblock}${nameblock}${flags}"
  elif [ -n "$(tmux show -gqv "@_tmx_${p}_text")" ]; then
    # number on the right: name block first, then the number block. The seam
    # lands immediately after the name content, before the flags, so the state
    # icons stay adjacent to the number block. Wrapped in the same #{?${text},…,}
    # name-visibility conditional as the position=left nameblock above, so a
    # window whose name resolves empty at draw time doesn't leave a floating
    # seam taper with nothing to taper into.
    raw_lcap=$(cap "$lglyph" "$tcap" "$tbg")
    nameblock="#{?${text},#[fg=$tfg,bg=$tbg]${text} ${seam},}"
    raw_rcap=$(cap "$rglyph" "$icap" "$ibg")
    first_cap="$raw_lcap"
    last_cap="$raw_rcap"
    flags_out="${nameblock}${flags}${nblock}"
  else
    # number on the right, no name: just the number block.
    raw_lcap=$(cap "$lglyph" "$icap" "$ibg")
    raw_rcap=$(cap "$rglyph" "$icap" "$ibg")
    first_cap="$raw_lcap"
    last_cap="$raw_rcap"
    flags_out="${nblock}${flags}"
  fi

  none_out="${first_cap}${flags_out}${last_cap}"
  if [ "$connected" = 1 ]; then
    left_out="${flags_out}${last_cap}"
    right_out="${first_cap}${flags_out}"
    both_out="$flags_out"
  else
    left_out="#{?#{==:#{window_index},${base}},,${first_cap}}${flags_out}${last_cap}"
    right_out="${first_cap}${flags_out}#{?loop_last_flag,,${last_cap}}"
    both_out="#{?#{==:#{window_index},${base}},,${first_cap}}${flags_out}#{?loop_last_flag,,${last_cap}}"
  fi

  tmux set -g "$opt" "$none_out" \; \
    set -g "${prefix}_none" "$none_out" \; \
    set -g "${prefix}_left" "$left_out" \; \
    set -g "${prefix}_right" "$right_out" \; \
    set -g "${prefix}_both" "$both_out"
}

render_side w "" window-status-format @_tmx_wfmt
render_side cw current_ window-status-current-format @_tmx_cwfmt

# Edge colours for status-line grammar seams around the `windows` token. The left
# edge follows the first window, the right edge the last (assuming contiguous
# indexes, same as the connected separator below). Which block sits at an edge
# depends on the layout: with numbers on the left the right edge is the name block
# and the left edge the number block; numbers on the right mirror it. The name
# (text) edge is text-aware — it falls back to the number cap when the window
# shows no name, matching the per-window last_cap and the separator. @_tmx_*_text
# resolves against the active window, so the text edge is exact for the always and
# never name modes and for the active edge; a manual-mode inactive edge degrades
# to the active window's name state, like the rest of this contiguous-index seam.
last_index="#{e|+:${base},#{e|-:#{window_count},1}}"
first_active="#{==:#{active_window_index},${base}}"
last_active="#{==:#{active_window_index},${last_index}}"
w_txt_col="#{?#{E:@_tmx_w_text},${W_TCAP},${W_ICAP}}"
w_txt_bg="#{?#{E:@_tmx_w_text},${W_TBG},${W_IBG}}"
cw_txt_col="#{?#{E:@_tmx_cw_text},${CW_TCAP},${CW_ICAP}}"
cw_txt_bg="#{?#{E:@_tmx_cw_text},${CW_TBG},${CW_IBG}}"
if [ "$position" = left ]; then
  # numbers left: number block on the left edge, name block on the right.
  win_lcol="#{?${first_active},${CW_ICAP},${W_ICAP}}"
  win_lbg="#{?${first_active},${CW_IBG},${W_IBG}}"
  win_rcol="#{?${last_active},${cw_txt_col},${w_txt_col}}"
  win_rbg="#{?${last_active},${cw_txt_bg},${w_txt_bg}}"
else
  # numbers right: name block on the left edge, number block on the right.
  win_lcol="#{?${first_active},${cw_txt_col},${w_txt_col}}"
  win_lbg="#{?${first_active},${cw_txt_bg},${w_txt_bg}}"
  win_rcol="#{?${last_active},${CW_ICAP},${W_ICAP}}"
  win_rbg="#{?${last_active},${CW_IBG},${W_IBG}}"
fi
tmux set -g @_tmx_windows_lcol "$win_lcol" \; \
  set -g @_tmx_windows_lbg "$win_lbg" \; \
  set -g @_tmx_windows_rcol "$win_rcol" \; \
  set -g @_tmx_windows_rbg "$win_rbg"

# Neighbour-aware separator for the connected ribbon. Drawn after each window in
# that window's draw context, so window_active is the left window and a small
# index check tells whether the right window is the active one:
#   - left window active  -> its right cap (active colour) bulges over the next
#   - right window active  -> the active's left cap bulges back over this window
#   - neither             -> a plain inactive->inactive taper
# All four colours are known (each side resolved its own cap colour, and both
# states' colours are theme constants), so the seam is gapless and the active
# window's caps overlay both neighbours (raised).
if [ "$connected" = 1 ]; then
  w_rcol="#{?#{E:@_tmx_w_text},${W_TCAP},${W_ICAP}}"    # this window's right colour
  cw_rcol="#{?#{E:@_tmx_cw_text},${CW_TCAP},${CW_ICAP}}" # the active window's right colour
  nextact="#{==:#{active_window_index},#{e|+:#{window_index},1}}"
  this_rcol="#{?window_active,${cw_rcol},${w_rcol}}"     # right colour of THIS window
  next_lcol="#{?${nextact},${CW_ICAP},${W_ICAP}}"        # left colour of the NEXT window
  half=$(printf '\342\226\214')                          # ▌ — left half block
  case "$wseam" in
    '>') sep="#[fg=${this_rcol}]#[bg=${next_lcol}]${rglyph}" ;; # this penetrates right
    '<') sep="#[fg=${next_lcol}]#[bg=${this_rcol}]${lglyph}" ;; # next penetrates left
    '=') sep="#[fg=${this_rcol}]#[bg=${next_lcol}]${half}" ;;   # flat: a 1-cell boundary,
                                                               # left half this / right half next,
                                                               # so each number box stays centred
    *)   # <> raised: the active window's caps overlay both neighbours
      sep="#{?window_active,"
      sep+="#[fg=${cw_rcol}]#[bg=${W_ICAP}]${rglyph},"
      sep+="#{?${nextact},"
      sep+="#[fg=${CW_ICAP}]#[bg=${w_rcol}]${lglyph},"
      sep+="#[fg=${w_rcol}]#[bg=${W_ICAP}]${rglyph}"
      sep+="}}"
      ;;
  esac
  tmux set -g window-status-separator "$sep"
fi

tmux set -gu @_tmx_render_tmp
tmux set -ug @_tmx_w_flags
exit 0
