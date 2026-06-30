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
tmux set -g @themux_status_line_1 "cpu ram session host"
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
printf "\nram_live "
core ram | grep -c 'ram_bg_color' || true

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
sess=$(core session)
sess_before_icon=${sess%%*}
sess_after_icon=${sess#*}
printf "\nsession_state_default_leading "
{ [[ "$sess_before_icon" == *client_prefix* ]] && [[ "$sess_after_icon" != *client_prefix* ]]; } && printf "Y" || printf "n"
tmux set -g @themux_session_state_target "text"; src
sess=$(core session)
sess_before_icon=${sess%%*}
sess_after_icon=${sess#*}
printf "\nsession_state_text_moves_active "
{ [[ "$sess_before_icon" != *client_prefix* ]] && [[ "$sess_after_icon" == *client_prefix* ]]; } && printf "Y" || printf "n"
tmux set -g @themux_session_state_target "off"; src
printf "\nsession_state_off_removes_active "
{ ! core session | grep -q 'client_prefix'; } && printf "Y" || printf "n"
tmux set -g @themux_session_state_target "nonsense"; src
sess=$(core session)
sess_before_icon=${sess%%*}
sess_after_icon=${sess#*}
printf "\nsession_state_invalid_auto_visible_leading "
{ [[ "$sess_before_icon" == *client_prefix* ]] && [[ "$sess_after_icon" != *client_prefix* ]]; } && printf "Y" || printf "n"
tmux set -g @themux_session_state_target "auto"
tmux set -g @themux_session_leading_show "off"; src
printf "\nsession_state_auto_hidden_uses_text "
{ core session | grep -q 'client_prefix' && ! core session | grep -qF ''; } && printf "Y" || printf "n"
tmux set -gu @themux_session_leading_show
tmux set -gu @themux_session_state_target

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

# Badge padding "<leading-left> <leading-right>|<text-left> <text-right>":
# each side around the leading<->text seam can be widened independently.
tmux set -g @themux_status_line_1 "host"
tmux set -g @themux_module_padding "0 0|0 0"; src
p0=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "3 3|3 3"; src
p3=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "1"; src
pglobal=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "1 | 1"; src
pshort=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "1 1|1 1"; src
pfull=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "0 3 1"; src
pinvalid=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "0 3|0 0"; src
plr=$(core host | wc -c | tr -d ' ')
tmux set -g @themux_module_padding "0 0|3 0"; src
ptl=$(core host | wc -c | tr -d ' ')
tmux set -gu @themux_module_padding
printf "\npadding_widens_badge "; { [ "$p3" -gt "$p0" ]; } && printf "Y" || printf "n"
printf "\npadding_global_shorthand_matches "; { [ "$pglobal" -eq "$pfull" ]; } && printf "Y" || printf "n"
printf "\npadding_side_shorthand_matches "; { [ "$pshort" -eq "$pfull" ]; } && printf "Y" || printf "n"
printf "\npadding_invalid_falls_back "; { [ "$pinvalid" -eq "$pfull" ]; } && printf "Y" || printf "n"
printf "\npadding_leading_right_widens "; { [ "$plr" -gt "$p0" ]; } && printf "Y" || printf "n"
printf "\npadding_text_left_widens "; { [ "$ptl" -gt "$p0" ]; } && printf "Y" || printf "n"


# Module leading selector: icon is the default, label uses the optional module
# label, off hides leading, auto falls back icon -> label -> hidden, and invalid
# values behave like icon. The text slot stays separate in every mode.
tmux set -g @themux_status_line_1 "host session"
tmux set -g @themux_host_label "HOST_LABEL"
tmux set -g @themux_session_label "SESSION_LABEL"
tmux set -g @themux_module_leading_show "label"
src
printf "\nleading_label_uses_label "
{ core host | grep -qF 'HOST_LABEL' && ! core host | grep -qF '󰒋'; } && printf "Y" || printf "n"
printf "\nleading_label_keeps_text_slot "
{ core host | grep -qF '#{E:@themux_host_text}'; } && printf "Y" || printf "n"
tmux set -gu @themux_host_label; src
hidden_lbg=$(tmux show -gqv @_tmx_module_host_lbg)
hidden_rbg=$(tmux show -gqv @_tmx_module_host_rbg)
printf "\nleading_label_missing_label_hides_leading "
{ ! core host | grep -qF '󰒋' && core host | grep -qF '#{E:@themux_host_text}' && [ "$hidden_lbg" = "$hidden_rbg" ]; } && printf "Y" || printf "n"
tmux set -g @themux_module_middle_separator "MID"; src
printf "\nleading_hidden_drops_middle_separator "
{ ! core host | grep -qF 'MID'; } && printf "Y" || printf "n"
tmux set -gu @themux_module_middle_separator
tmux set -g @themux_module_leading_show "off"; src
off_lbg=$(tmux show -gqv @_tmx_module_host_lbg)
off_rbg=$(tmux show -gqv @_tmx_module_host_rbg)
printf "\nleading_off_hides_leading "
{ ! core host | grep -qF '󰒋' && ! core host | grep -qF 'HOST_LABEL' && core host | grep -qF '#{E:@themux_host_text}' && [ "$off_lbg" = "$off_rbg" ]; } && printf "Y" || printf "n"
tmux set -g @themux_module_leading_show "auto"
tmux set -g @themux_host_label "HOST_LABEL"
src
printf "\nleading_auto_prefers_icon "
{ core host | grep -qF '󰒋' && ! core host | grep -qF 'HOST_LABEL'; } && printf "Y" || printf "n"
tmux set -g @themux_host_icon ""; src
printf "\nleading_auto_falls_back_label "
{ core host | grep -qF 'HOST_LABEL' && core host | grep -qF '#{E:@themux_host_text}'; } && printf "Y" || printf "n"
tmux set -g @themux_session_leading_show "icon"
src
printf "\nleading_module_override_keeps_icon "
{ core session | grep -qF '' && ! core session | grep -qF 'SESSION_LABEL'; } && printf "Y" || printf "n"
tmux set -gu @themux_session_leading_show
tmux set -g @themux_module_leading_show "nonsense"
src
printf "\nleading_invalid_uses_icon "
{ core session | grep -qF '' && ! core session | grep -qF 'SESSION_LABEL'; } && printf "Y" || printf "n"
tmux set -gu @themux_module_leading_show
tmux set -gu @themux_host_label
tmux set -gu @themux_host_icon
tmux set -gu @themux_session_label
tmux set -gu @themux_session_leading_show

# Metric state target: cpu/ram default to both slots, but a metric override can
# move the live threshold colour to text only or suppress it entirely.
tmux set -g @themux_status_line_1 "cpu ram"
src
cpu=$(core cpu); cpu_before_icon=${cpu%%*}; cpu_after_icon=${cpu#*}
ram=$(core ram)
printf "\ncpu_state_default_both "
{ [[ "$cpu_before_icon" == *cpu_bg_color* ]] && [[ "$cpu_after_icon" == *cpu_bg_color* ]]; } && printf "Y" || printf "n"
printf "\nram_state_default_both "
{ [[ "$ram" == *ram_bg_color* ]] && [ "$(grep -o 'ram_bg_color' <<<"$ram" | wc -l | tr -d ' ')" -ge 2 ]; } && printf "Y" || printf "n"
tmux set -g @themux_cpu_state_target "text"; src
cpu=$(core cpu); cpu_before_icon=${cpu%%*}; cpu_after_icon=${cpu#*}
printf "\ncpu_state_text_moves_live "
{ [[ "$cpu_before_icon" != *cpu_bg_color* ]] && [[ "$cpu_after_icon" == *cpu_bg_color* ]]; } && printf "Y" || printf "n"
tmux set -g @themux_cpu_text_color "OVERRIDE"; src
printf "\nmetric_slot_override_wins "
{ core cpu | grep -qF 'OVERRIDE'; } && printf "Y" || printf "n"
tmux set -gu @themux_cpu_text_color
tmux set -g @themux_cpu_state_target "off"; src
printf "\ncpu_state_off_removes_live "
{ ! core cpu | grep -q 'cpu_bg_color'; } && printf "Y" || printf "n"
tmux set -g @themux_cpu_state_target "auto"
tmux set -g @themux_cpu_leading_show "off"; src
printf "\ncpu_state_auto_hidden_uses_text "
{ core cpu | grep -q 'cpu_bg_color' && ! core cpu | grep -qF ''; } && printf "Y" || printf "n"
tmux set -gu @themux_cpu_leading_show
tmux set -g @themux_cpu_state_target "nonsense"; src
cpu=$(core cpu); cpu_before_icon=${cpu%%*}; cpu_after_icon=${cpu#*}
printf "\ncpu_state_invalid_auto_visible_leading "
{ [[ "$cpu_before_icon" == *cpu_bg_color* ]] && [[ "$cpu_after_icon" != *cpu_bg_color* ]]; } && printf "Y" || printf "n"
tmux set -gu @themux_cpu_state_target

# Plugin-data modules carry their value as a #{var} literal that only resolves
# through the plugin's do_interpolation; _expand + _plugin let the layout apply it
# in any zone (the live interpolation is verified outside the harness, which has no
# plugins installed).
src
printf "\nbattery_interp_wired "; { [ "$(tmux show -gqv @themux_battery_expand)" = "yes" ] && [ -n "$(tmux show -gqv @themux_battery_plugin)" ]; } && printf "Y" || printf "n"
printf "\ncpu_interp_wired "; { [ "$(tmux show -gqv @themux_cpu_expand)" = "yes" ] && [ -n "$(tmux show -gqv @themux_cpu_plugin)" ]; } && printf "Y" || printf "n"
