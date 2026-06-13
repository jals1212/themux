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
tmux show -gv 'status-format[0]' | grep -oE '#\[align=(left|centre|right)\]' | tr '\n' ' '
printf "\none_left_divider "
tmux show -gv 'status-format[0]' | grep -c '@themux_status_session}#{E:@_tmx_status_divider}#{E:@themux_status_application' || true
printf "one_windows_centre "
tmux show -gv 'status-format[0]' | grep -c 'list=on align=centre' || true
printf "one_right_module "
tmux show -gv 'status-format[0]' | grep -c 'align=right]#{E:@themux_status_host}' || true

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
