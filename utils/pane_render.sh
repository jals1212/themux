#!/usr/bin/env bash
# Assemble pane-border-format from the v3 props: @themux_pane_{shape,indicator,
# text,notch}. The indicator (pane number) and text blocks are styled
# independently through the shared resolver; the shape draws the caps; notch
# shapes the indicator<->text seam.
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

position=$(tmux show -gqv @themux_pane_number_position)
indicator=$(tmux show -gqv @themux_pane_indicator)
text_style=$(tmux show -gqv @themux_pane_text)
notch=$(tmux show -gqv @themux_pane_notch)
shape=$(tmux show -gqv @themux_pane_shape)
left_glyph=$(tmux show -gqv @themux_pane_left_border)
right_glyph=$(tmux show -gqv @themux_pane_right_border)

# Colour roles. The accent brightens per pane at draw time (pane_color when
# active, overlay_0 when not); surface, crust and the plain fg are static.
accent="#{?pane_active,$(expand "#{E:@themux_pane_color}"),$(expand "#{@thm_overlay_0}")}"
surface=$(expand "#{E:@themux_pane_background_color}")
crust=$(expand "#{@thm_crust}")
fg=$(expand "#{@thm_fg}")

index='#{pane_index}'
text=$(expand "#{E:@themux_pane_default_text}")

# Resolve the indicator and text blocks independently.
resolve_style "$indicator" "$accent" "$surface" "$crust" "$fg"
ind_bg="$RS_BG" ind_fg="$RS_FG"
resolve_style "$text_style" "$accent" "$surface" "$crust" "$fg"
txt_bg="$RS_BG" txt_fg="$RS_FG"

# The notch seam glyph mirrors the shape's right cap (octal UTF-8): slanted E0BC,
# rounded E0B4, squared █ block.
seam_glyph=""
[ "$notch" = on ] && case "$shape" in
  slanted) seam_glyph=$(printf '\356\202\274') ;;
  rounded) seam_glyph=$(printf '\356\202\264') ;;
  squared) seam_glyph=$(printf '\342\226\210') ;;
esac

# Centred blocks: " idx " on the indicator bg, " text " on the text bg.
ind_block="#[fg=$ind_fg,bg=$ind_bg] $index "
txt_block="#[fg=$txt_fg,bg=$txt_bg] $text "

# A cap is the shape glyph over the bare border, coloured by the block it tapers:
# the block's own bg, or the accent when that bg is transparent (the outline edge
# of a naked block / capsule). Empty glyph (squared) -> no cap, the block fills
# its own edge.
capcol() { [ "$1" = default ] && printf '%s' "$accent" || printf '%s' "$1"; }
cap() { [ -n "$1" ] && printf '#[fg=%s,bg=default]%s' "$2" "$1"; }

# Notch seam: the indicator's right cap tapering into the text bg, only on the
# number-on-the-left layout (matching windows) and only when the two blocks
# differ — same bg would render an invisible phantom cell.
seam() {
  [ -n "$seam_glyph" ] && [ "$ind_bg" != "$txt_bg" ] &&
    printf '#[fg=%s,bg=%s]%s' "$ind_bg" "$txt_bg" "$seam_glyph"
}

if [ "$position" = right ]; then
  fmt="$(cap "$left_glyph" "$(capcol "$txt_bg")")$txt_block$ind_block$(cap "$right_glyph" "$(capcol "$ind_bg")")"
else
  fmt="$(cap "$left_glyph" "$(capcol "$ind_bg")")$ind_block$(seam)$txt_block$(cap "$right_glyph" "$(capcol "$txt_bg")")"
fi

tmux set -wg pane-border-format "$fmt"
tmux set -gu @_tmx_render_tmp
exit 0
