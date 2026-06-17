#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# run-shell is synchronous, so status-format is built before we read it.
run_layout() { tmux run-shell "${script_dir}/../utils/layout.sh"; }

# One line: left modules (with a "|" divider), windows centred, right module.
tmux set -g @themux_status_line_1 "session|application / windows / host"
tmux set -g @themux_status_line_2 ""
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout

printf "\none_status "
tmux show -gv status
printf "one_zones "
tmux show -gv 'status-format[0]' | grep -oE '#\[nolist align=(left|centre|right)\]' | tr '\n' ' '
printf "\none_left_divider "
tmux show -gv 'status-format[0]' | grep -c '@themux_module_session}#{E:@_tmx_module_divider}#{E:@themux_module_application' || true
printf "one_windows_centre "
tmux show -gv 'status-format[0]' | grep -c 'list=on align=centre' || true
printf "one_right_module "
tmux show -gv 'status-format[0]' | grep -c 'nolist align=right]#{E:@themux_module_host}' || true

# Two lines: windows alone on the second row, right-aligned.
tmux set -g @themux_status_line_1 "session / / host"
tmux set -g @themux_status_line_2 " / / windows"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\ntwo_status "
tmux show -gv status
printf "two_line2_windows_right "
tmux show -gv 'status-format[1]' | grep -c 'list=on align=right' || true

# Back to a single row when the extra lines are blank.
tmux set -g @themux_status_line_2 ""
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nsingle_status "
tmux show -gv status

# An empty module divider connects across "|" (rounded): the run joins into one
# powerline run — bare cores, no divider segment between the modules.
tmux set -g @themux_status_line_1 "session|application"
tmux set -g @themux_module_shape "rounded"
tmux set -g @themux_module_divider ""
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nconnect_uses_core "
tmux show -gv 'status-format[0]' | grep -c '@_tmx_module_session_core' || true
printf "connect_no_divider "
tmux show -gv 'status-format[0]' | grep -c '@_tmx_module_divider' || true

# Lazy render: a module never referenced in any status line is not rendered.
printf "unused_not_rendered "
tmux show -gqv @themux_module_weather | grep -c . || true

# Powerline direction follows the zone: a left run taper L->R (one mpll glyph,
# the head cap), a right rounded run mirrors so the inner seam also bulges left
# (two mpll glyphs: head + seam).
tmux set -g @themux_status_line_1 "session host / / user uptime"
tmux set -g @themux_module_shape "rounded"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
mpll=$(printf '\356\202\266')
fmt=$(tmux show -gv 'status-format[0]')
printf "\nleft_run_mpll "
printf '%s' "$fmt" | sed -E 's/.*nolist align=left\]//; s/#\[nolist align=centre.*//' | grep -o "$mpll" | wc -l | tr -d ' '
printf "right_run_mpll "
printf '%s' "$fmt" | sed 's/.*nolist align=right]//' | grep -o "$mpll" | wc -l | tr -d ' '
