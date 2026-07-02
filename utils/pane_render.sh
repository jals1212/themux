#!/usr/bin/env bash
# Assemble pane-border-format from the variant grammar: @themux_pane_{shape,
# leading_variant,text_variant,notch}. The leading (pane number) and text blocks
# are styled independently through the shared resolver; the shape draws the caps;
# notch shapes the leading<->text seam.
#
# A pane has ONE format whose appearance switches for the active pane at draw time
# via #{?pane_active,...}. Each block resolves its variant TWICE — the resting one
# with the resting accent, the active one (_active_variant) with the active accent
# — and a per-channel draw-time switch picks between them. As in window_render.sh,
# load-time colours are resolved through one `tmux set -F` pass and captured;
# draw-time refs stay literal #{...} (no ## doubling), since the format is stored
# with `tmux set` (no -F).

# shellcheck source=render_style.sh
. "$(dirname "$0")/render_style.sh"

expand() {
  tmux set -gF @_tmx_render_tmp "$1"
  tmux show -gv @_tmx_render_tmp
}

position=$(themux_prop pane leading_position)
leading=$(themux_prop pane leading_variant)
text_style=$(themux_prop pane text_variant)
leading_active=$(themux_prop pane leading_active_variant)
text_active=$(themux_prop pane text_active_variant)
# The active variant defaults to the resting one (same shape, colour swaps only).
[ -n "$leading_active" ] || leading_active="$leading"
[ -n "$text_active" ] || text_active="$text_style"
notch=$(themux_prop pane notch)
shape=$(themux_prop pane shape)
# Badge padding (@themux_pane_padding):
# "<leading-left> <leading-right>|<text-left> <text-right>".
read -r pleft pright tleft tright <<<"$(pad_parse "$(themux_prop pane padding)")"

# Shape glyphs (octal UTF-8). squared has none — the block padding is its edge.
case "$shape" in
  rounded)   left_glyph=$(printf '\356\202\266'); right_glyph=$(printf '\356\202\264') ;;
  slanted)   left_glyph=$(printf '\356\202\272'); right_glyph=$(printf '\356\202\274') ;;
  powerline) left_glyph=$(printf '\356\202\262'); right_glyph=$(printf '\356\202\260') ;;
  *)         left_glyph=""; right_glyph="" ;;
esac

# Per-part accents: a resting accent (inactive pane) and an active accent (active
# pane). surface/crust/fg are static.
lead_base=$(expand "#{E:@themux_pane_leading_color}")
lead_act=$(expand "#{E:@themux_pane_leading_active_color}")
txt_base=$(expand "#{E:@themux_pane_text_color}")
txt_act=$(expand "#{E:@themux_pane_text_active_color}")
surface=$(expand "#{E:@themux_pane_background_color}")
crust=$(expand "#{@thm_crust}")
fg=$(expand "#{@thm_fg}")

index='#{pane_index}'
text=$(expand "#{E:@themux_pane_default_text}")

# A draw-time per-channel switch between the active pane value and the resting
# one; collapses to a plain value when the two are equal.
sw() { [ "$1" = "$2" ] && printf '%s' "$2" || printf '#{?pane_active,%s,%s}' "$1" "$2"; }

# Resolve each block's resting and active variant+accent, then switch per channel.
# The cap colour follows the bg channel (the block bg, or the accent that bg uses
# when the block is transparent/naked) — computed per state, then switched.
resolve_style "$leading" "$lead_base" "$surface" "$crust" "$fg"; ribg=$RS_BG rifg=$RS_FG
resolve_style "$leading_active" "$lead_act" "$surface" "$crust" "$fg"; aibg=$RS_BG aifg=$RS_FG
lead_bg=$(sw "$aibg" "$ribg") lead_fg=$(sw "$aifg" "$rifg")
ricap=$ribg; [ "$ribg" = default ] && ricap=$lead_base
aicap=$aibg; [ "$aibg" = default ] && aicap=$lead_act
lead_cap=$(sw "$aicap" "$ricap")

resolve_style "$text_style" "$txt_base" "$surface" "$crust" "$fg"; rtbg=$RS_BG rtfg=$RS_FG
resolve_style "$text_active" "$txt_act" "$surface" "$crust" "$fg"; atbg=$RS_BG atfg=$RS_FG
txt_bg=$(sw "$atbg" "$rtbg") txt_fg=$(sw "$atfg" "$rtfg")
rtcap=$rtbg; [ "$rtbg" = default ] && rtcap=$txt_base
atcap=$atbg; [ "$atbg" = default ] && atcap=$txt_act
txt_cap=$(sw "$atcap" "$rtcap")

# Seam glyphs, direction-aware (octal UTF-8, mirrors utils/module_render.sh): gt
# tapers the visually-first block's colour into the second via the shape's right
# cap; lt mirrors it, the second block's colour into the first via the left cap.
# Squared has no outer cap (see left_glyph/right_glyph above), but the seam still
# draws a full block — same glyph both directions, only its colours differ.
case "$shape" in
  rounded)   seam_lglyph=$(printf '\356\202\266'); seam_rglyph=$(printf '\356\202\264') ;;
  slanted)   seam_lglyph=$(printf '\356\202\272'); seam_rglyph=$(printf '\356\202\274') ;;
  powerline) seam_lglyph=$(printf '\356\202\262'); seam_rglyph=$(printf '\356\202\260') ;;
  squared)   seam_lglyph=$(printf '\342\226\210'); seam_rglyph=$(printf '\342\226\210') ;;
  *)         seam_lglyph=""; seam_rglyph="" ;; # unstyled: no seam
esac

# auto is position-aware: panes have no bar zone to key off (unlike modules and
# windows), so the direction instead follows leading_position — the leading
# block's colour penetrates rightward when it sits on the left (mirrors the
# pre-existing on behaviour), leftward when it sits on the right. Explicit gt/lt
# ignore position, the same way explicit modules ignore their zone.
mode=$(themux_notch_mode "$notch")
if [ "$mode" = auto ]; then
  [ "$position" = right ] && mode=lt || mode=gt
fi

# Padding owns all four inner sides, including the number<->text seam.
lead_block="#[fg=$lead_fg,bg=$lead_bg]$(spaces "$pleft")$index$(spaces "$pright")"
txt_block="#[fg=$txt_fg,bg=$txt_bg]$(spaces "$tleft")$text$(spaces "$tright")"

# A cap is the shape glyph over the bare border, coloured by the block it tapers
# (its cap colour). Empty glyph (squared) -> no cap, the block fills its own edge.
cap() { [ -n "$1" ] && printf '#[fg=%s,bg=default]%s' "$2" "$1"; }

# Notch seam: the block that is visually first tapers into the second (gt) or
# vice versa (lt), gated on the two blocks actually differing — same bg would
# render an invisible phantom cell. Block order follows leading_position, like
# utils/module_render.sh: left -> leading first, text second; right -> reversed.
# fg uses the cap-fallback colour ($lead_cap/$txt_cap, not the raw $lead_bg/
# $txt_bg) so a naked block (bg=default) still shows a coloured seam instead of
# an invisible fg=default one; bg stays the raw block colour since bg=default
# there is itself legitimate — a naked block's cap over the bare border.
seam() {
  local fbg sbg fcap scap glyph
  if [ "$position" = right ]; then
    fbg="$txt_bg" fcap="$txt_cap" sbg="$lead_bg" scap="$lead_cap"
  else
    fbg="$lead_bg" fcap="$lead_cap" sbg="$txt_bg" scap="$txt_cap"
  fi
  [ "$fbg" = "$sbg" ] && return
  case "$mode" in
    gt) glyph="$seam_rglyph"; [ -n "$glyph" ] && printf '#[fg=%s,bg=%s]%s' "$fcap" "$sbg" "$glyph" ;;
    lt) glyph="$seam_lglyph"; [ -n "$glyph" ] && printf '#[fg=%s,bg=%s]%s' "$scap" "$fbg" "$glyph" ;;
  esac
}

if [ "$position" = right ]; then
  fmt="$(cap "$left_glyph" "$txt_cap")$txt_block$(seam)$lead_block$(cap "$right_glyph" "$lead_cap")"
else
  fmt="$(cap "$left_glyph" "$lead_cap")$lead_block$(seam)$txt_block$(cap "$right_glyph" "$txt_cap")"
fi

tmux set -wg pane-border-format "$fmt"
tmux set -gu @_tmx_render_tmp
exit 0
