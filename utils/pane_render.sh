#!/usr/bin/env bash
# Assemble pane-border-format for the squared/rounded/slanted pane variants,
# mirroring utils/window_render.sh so the active pane reads like the active
# window — number block then a padded name block, each centred, with the variant
# cap glyphs — only the accent colour differs (pane_color vs the window colour).
#
# Unlike windows (two separate options for inactive/current), a pane has ONE
# format whose accent is chosen per pane at draw time via #{?pane_active,...}.
# As in window_render.sh: load-time colours are resolved through one `tmux set -F`
# pass and captured; draw-time refs stay literal #{...} (no ## doubling), since
# the format is stored with `tmux set` (no -F).

expand() {
  tmux set -gF @_tmx_render_tmp "$1"
  tmux show -gv @_tmx_render_tmp
}

position=$(tmux show -gqv @themux_pane_number_position)
fill=$(tmux show -gqv @_tmx_pane_fill)
left_glyph=$(tmux show -gqv @themux_pane_left_border)
right_glyph=$(tmux show -gqv @themux_pane_right_border)

panebg=$(expand "#{E:@themux_pane_background_color}")
fg=$(expand "#{@thm_fg}")
surface0=$(expand "#{@thm_surface_0}")
# Per-pane accent: pane_color when active, overlay_0 when not (resolved at draw).
accent="#{?pane_active,$(expand "#{E:@themux_pane_color}"),$(expand "#{@thm_overlay_0}")}"
# Drawn per pane; keep #{pane_index} / the default-text template as draw-time refs.
index='#{pane_index}'
text=$(expand "#{E:@themux_pane_default_text}")

# naked: inactive panes are accent text on the transparent border; the active
# pane is a solid accent block. (The shape's caps on the active pane are added in
# a later step.)
if [ "$fill" = naked ]; then
  pc=$(expand "#{E:@themux_pane_color}")
  cr=$(expand "#{@thm_crust}")
  tmux set -wg pane-border-format \
    "#[fg=#{?pane_active,${cr},${pc}},bg=#{?pane_active,${pc},default}] ${index} ${text} "
  tmux set -gu @_tmx_render_tmp
  exit 0
fi

# Block styles + their bg colour (used as the cap fg so the cap tapers the block
# into the transparent border). icon: only the number takes the accent; fill: the
# whole label does; none: no accent, a neutral surface block.
case "$fill" in
  none)
    nstyle="#[fg=$fg,bg=$surface0]"; tstyle="$nstyle"; ncol="$surface0"; tcol="$surface0" ;;
  fill)
    nstyle="#[fg=$panebg,bg=$accent]"; tstyle="$nstyle"; ncol="$accent"; tcol="$accent" ;;
  *) # icon
    nstyle="#[fg=$panebg,bg=$accent]"; tstyle="#[fg=$accent,bg=$panebg]"; ncol="$accent"; tcol="$panebg" ;;
esac

# A cap is the variant glyph in its block colour over the transparent border;
# empty glyph (squared) -> just the block's own bg fill, no cap.
cap() { [ -n "$1" ] && printf '#[fg=%s,bg=default]%s' "$2" "$1"; }

# Centred blocks: " idx " on the number bg, " text " on the text bg.
num_block="$nstyle $index "
txt_block="$tstyle $text "

if [ "$position" = "right" ]; then
  fmt="$(cap "$left_glyph" "$tcol")$txt_block$num_block$(cap "$right_glyph" "$ncol")"
else
  fmt="$(cap "$left_glyph" "$ncol")$num_block$txt_block$(cap "$right_glyph" "$tcol")"
fi

tmux set -wg pane-border-format "$fmt"
tmux set -gu @_tmx_render_tmp
exit 0
