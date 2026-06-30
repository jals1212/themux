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

# The notch seam glyph mirrors the shape's right cap (octal UTF-8): slanted E0BC,
# rounded E0B4, powerline E0B0, squared █ block.
seam_glyph=""
[ "$notch" = on ] && case "$shape" in
  slanted)   seam_glyph=$(printf '\356\202\274') ;;
  rounded)   seam_glyph=$(printf '\356\202\264') ;;
  powerline) seam_glyph=$(printf '\356\202\260') ;;
  squared)   seam_glyph=$(printf '\342\226\210') ;;
esac

# Padding owns all four inner sides, including the number<->text seam.
lead_block="#[fg=$lead_fg,bg=$lead_bg]$(spaces "$pleft")$index$(spaces "$pright")"
txt_block="#[fg=$txt_fg,bg=$txt_bg]$(spaces "$tleft")$text$(spaces "$tright")"

# A cap is the shape glyph over the bare border, coloured by the block it tapers
# (its cap colour). Empty glyph (squared) -> no cap, the block fills its own edge.
cap() { [ -n "$1" ] && printf '#[fg=%s,bg=default]%s' "$2" "$1"; }

# Notch seam: the leading's right cap tapering into the text bg, only on the
# number-on-the-left layout (matching windows) and only when the two blocks
# differ — same bg would render an invisible phantom cell.
seam() {
  [ -n "$seam_glyph" ] && [ "$lead_bg" != "$txt_bg" ] &&
    printf '#[fg=%s,bg=%s]%s' "$lead_bg" "$txt_bg" "$seam_glyph"
}

if [ "$position" = right ]; then
  fmt="$(cap "$left_glyph" "$txt_cap")$txt_block$lead_block$(cap "$right_glyph" "$lead_cap")"
else
  fmt="$(cap "$left_glyph" "$lead_cap")$lead_block$(seam)$txt_block$(cap "$right_glyph" "$txt_cap")"
fi

tmux set -wg pane-border-format "$fmt"
tmux set -gu @_tmx_render_tmp
exit 0
