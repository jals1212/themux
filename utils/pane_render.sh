#!/usr/bin/env bash
# Assemble pane-border-format from the v3 props: @themux_pane_{shape,leading,
# text,notch}. The leading (pane number) and text blocks are styled
# independently through the shared resolver; the shape draws the caps; notch
# shapes the leading<->text seam.
#
# A pane has ONE format whose accent brightens for the active pane at draw time
# via #{?pane_active,...}. As in window_render.sh, load-time colours are resolved
# through one `tmux set -F` pass and captured; draw-time refs stay literal #{...}
# (no ## doubling), since the format is stored with `tmux set` (no -F).

# shellcheck source=render_style.sh
. "$(dirname "$0")/render_style.sh"

expand() {
  tmux set -gF @_tmx_render_tmp "$1"
  tmux show -gv @_tmx_render_tmp
}

position=$(themux_prop pane leading_position)
leading=$(themux_prop pane leading)
text_style=$(themux_prop pane text)
notch=$(themux_prop pane notch)
shape=$(themux_prop pane shape)
# Active highlight per part/channel (off|bg|fg|both, default both): which of the
# active pane's colours actually switch; the rest stay frozen at the inactive
# colour. Applied by resolving each block twice (active accent vs frozen) below.
lead_hl=$(themux_prop pane leading_highlight); [ -n "$lead_hl" ] || lead_hl=both
txt_hl=$(themux_prop pane text_highlight); [ -n "$txt_hl" ] || txt_hl=both

# Shape glyphs (octal UTF-8). squared has none — the block padding is its edge.
case "$shape" in
  rounded)   left_glyph=$(printf '\356\202\266'); right_glyph=$(printf '\356\202\264') ;;
  slanted)   left_glyph=$(printf '\356\202\272'); right_glyph=$(printf '\356\202\274') ;;
  powerline) left_glyph=$(printf '\356\202\262'); right_glyph=$(printf '\356\202\260') ;;
  *)         left_glyph=""; right_glyph="" ;;
esac

# Per-part colour roles. Each part's accent brightens for the active pane (its
# highlight colour when active, base colour when not); accent_fr is the frozen
# base for the channels the highlight toggles exclude. surface/crust/fg static.
lead_base=$(expand "#{E:@themux_pane_leading_color}")
lead_hi=$(expand "#{E:@themux_pane_leading_highlight_color}")
txt_base=$(expand "#{E:@themux_pane_text_color}")
txt_hi=$(expand "#{E:@themux_pane_text_highlight_color}")
lead_accent_hl="#{?pane_active,${lead_hi},${lead_base}}"; lead_accent_fr="$lead_base"
txt_accent_hl="#{?pane_active,${txt_hi},${txt_base}}"; txt_accent_fr="$txt_base"
surface=$(expand "#{E:@themux_pane_background_color}")
crust=$(expand "#{@thm_crust}")
fg=$(expand "#{@thm_fg}")

index='#{pane_index}'
text=$(expand "#{E:@themux_pane_default_text}")

# Resolve each block with its highlighting accent and its frozen accent, then
# pick per channel per toggle. The cap colour follows the bg channel (it is the
# block bg, or the accent that bg uses when the block is transparent/naked).
resolve_style "$leading" "$lead_accent_hl" "$surface" "$crust" "$fg"; ibg_hl=$RS_BG ifg_hl=$RS_FG
resolve_style "$leading" "$lead_accent_fr" "$surface" "$crust" "$fg"; ibg_fr=$RS_BG ifg_fr=$RS_FG
case "$lead_hl" in
  bg)  lead_bg=$ibg_hl lead_fg=$ifg_fr ;;
  fg)  lead_bg=$ibg_fr lead_fg=$ifg_hl ;;
  off) lead_bg=$ibg_fr lead_fg=$ifg_fr ;;
  *)   lead_bg=$ibg_hl lead_fg=$ifg_hl ;;
esac
case "$lead_hl" in bg|both) lead_acc=$lead_accent_hl ;; *) lead_acc=$lead_accent_fr ;; esac
lead_cap=$lead_bg; [ "$lead_bg" = default ] && lead_cap=$lead_acc

resolve_style "$text_style" "$txt_accent_hl" "$surface" "$crust" "$fg"; tbg_hl=$RS_BG tfg_hl=$RS_FG
resolve_style "$text_style" "$txt_accent_fr" "$surface" "$crust" "$fg"; tbg_fr=$RS_BG tfg_fr=$RS_FG
case "$txt_hl" in
  bg)  txt_bg=$tbg_hl txt_fg=$tfg_fr ;;
  fg)  txt_bg=$tbg_fr txt_fg=$tfg_hl ;;
  off) txt_bg=$tbg_fr txt_fg=$tfg_fr ;;
  *)   txt_bg=$tbg_hl txt_fg=$tfg_hl ;;
esac
case "$txt_hl" in bg|both) txt_acc=$txt_accent_hl ;; *) txt_acc=$txt_accent_fr ;; esac
txt_cap=$txt_bg; [ "$txt_bg" = default ] && txt_cap=$txt_acc

# The notch seam glyph mirrors the shape's right cap (octal UTF-8): slanted E0BC,
# rounded E0B4, powerline E0B0, squared █ block.
seam_glyph=""
[ "$notch" = on ] && case "$shape" in
  slanted)   seam_glyph=$(printf '\356\202\274') ;;
  rounded)   seam_glyph=$(printf '\356\202\264') ;;
  powerline) seam_glyph=$(printf '\356\202\260') ;;
  squared)   seam_glyph=$(printf '\342\226\210') ;;
esac

# Centred blocks: " idx " on the leading bg, " text " on the text bg.
lead_block="#[fg=$lead_fg,bg=$lead_bg] $index "
txt_block="#[fg=$txt_fg,bg=$txt_bg] $text "

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
