#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

core() { tmux show -gqv "@_tmx_module_$1_core"; }
src() {
  tmux source "${script_dir}/../themux_options.conf"
  tmux source "${script_dir}/../themux.conf"
}

# A metric module's accent is tmux-cpu's live level colour: the solid icon makes it
# a coloured block (green at rest → red when hot), the subtle text rides it on the
# digits (grey block, live fg). Both escalate together and neither can go blank.
tmux set -g @themux_status_line_1 "cpu session host"
src
printf "\ncpu_live "
core cpu | grep -c 'cpu_bg_color' || true
printf "cpu_not_blank "
{ core cpu | grep -qF 'fg=#{l:#{cpu_bg_color}},bg=#{l:#{cpu_bg_color}}'; } && printf "blank" || printf "ok"
printf "\ncpu_icon_solid "
# solid icon: the live colour is the block bg
{ core cpu | grep -q 'bg=#{l:#{cpu_bg_color}}'; } && printf "Y" || printf "n"
printf "\ncpu_text_subtle "
# subtle text: the live colour is the digit fg, on a static grey block
{ core cpu | grep -q 'fg=#{l:#{cpu_bg_color}}'; } && printf "Y" || printf "n"

# Per-single-module override beats the all-modules tier: @themux_host_text_variant
# naked wins over @themux_module_text_variant solid, so host's text drops its block.
tmux set -g @themux_module_text_variant "solid"
tmux set -g @themux_host_text_variant "naked"
src
printf "\nhost_text_naked "
{ core host | grep -qF 'bg=default]#{E:@themux_host_text}'; } && printf "Y" || printf "n"
tmux set -gu @themux_module_text_variant
tmux set -gu @themux_host_text_variant

# A stateful module: session carries its prefix accent at draw time through
# @themux_<name>_active_when, so the active reference is always in the segment.
src
printf "\nsession_prefix "
core session | grep -c 'client_prefix' || true

# Leading position: right swaps the block order, so the left/right edge colours
# swap too (icon-then-text -> text-then-icon).
tmux set -g @themux_status_line_1 "host"
tmux set -g @themux_module_leading_position "left"
src
ll=$(tmux show -gqv @_tmx_module_host_lbg) lr=$(tmux show -gqv @_tmx_module_host_rbg)
tmux set -g @themux_module_leading_position "right"
src
rl=$(tmux show -gqv @_tmx_module_host_lbg) rr=$(tmux show -gqv @_tmx_module_host_rbg)
printf "\nposition_swaps_edges "
{ [ "$ll" = "$rr" ] && [ "$lr" = "$rl" ] && [ "$ll" != "$lr" ]; } && printf "Y" || printf "n"

# notch=off lets the icon and text blocks abut (compact, catppuccin-style — no seam
# cell). notch=on draws the shape's tapered cap as the seam between them, so the
# notched module is wider. The metric's solid icon over its subtle text differs in
# bg like any module, so the seam is drawn there too.
tmux set -gu @themux_module_leading_position
tmux set -g @themux_status_line_1 "host cpu"
tmux set -g @themux_all_shape "rounded"
tmux set -g @themux_all_notch "on"; src
hon=$(core host | wc -c | tr -d ' '); con=$(core cpu | wc -c | tr -d ' ')
tmux set -g @themux_all_notch "off"; src
hoff=$(core host | wc -c | tr -d ' '); coff=$(core cpu | wc -c | tr -d ' ')
printf "\nnotch_adds_seam_host_icon "; { [ "$hon" -gt "$hoff" ]; } && printf "Y" || printf "n"
printf "\nnotch_adds_seam_metric_icon "; { [ "$con" -gt "$coff" ]; } && printf "Y" || printf "n"

# Badge padding "<L> <S> <T>": a bigger value widens the module, and S widens the
# icon<->text separator on its own (leading/trailing left at 0).
tmux set -g @themux_status_line_1 "host"
tmux set -g @themux_module_padding "0"; src
p0=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "3"; src
p3=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "0 3 0"; src
psep=$(core host | wc -c | tr -d ' ')
tmux set -gu @themux_module_padding
printf "\npadding_widens_badge "; { [ "$p3" -gt "$p0" ]; } && printf "Y" || printf "n"
printf "\npadding_sep_widens "; { [ "$psep" -gt "$p0" ]; } && printf "Y" || printf "n"

# Plugin-data modules carry their value as a #{var} literal that only resolves
# through the plugin's do_interpolation; _expand + _plugin let the layout apply it
# in any zone (the live interpolation is verified outside the harness, which has no
# plugins installed).
src
printf "\nbattery_interp_wired "; { [ "$(tmux show -gqv @themux_battery_expand)" = "yes" ] && [ -n "$(tmux show -gqv @themux_battery_plugin)" ]; } && printf "Y" || printf "n"
printf "\ncpu_interp_wired "; { [ "$(tmux show -gqv @themux_cpu_expand)" = "yes" ] && [ -n "$(tmux show -gqv @themux_cpu_plugin)" ]; } && printf "Y" || printf "n"
