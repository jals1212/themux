#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# stacked: window list on its own line below status-left/right
tmux set -g @themux_windows_line "stacked"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

printf "\nstacked_status "
tmux show -gv status
printf "stacked_line1_has_list "
tmux show -gv 'status-format[1]' | grep -c 'list=on align' || true
# Line 0 keeps status-left/right, not the window list
printf "stacked_line0_has_list "
tmux show -gv 'status-format[0]' | grep -c 'list=on align' || true

# stacked + top: window list moves to line 0
tmux set -g @themux_windows_position "top"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
printf "\ntop_line0_has_list "
tmux show -gv 'status-format[0]' | grep -c 'list=on align' || true
tmux set -g @themux_windows_position "bottom" # reset

# spaced: window list on line 2 with a blank line 1
tmux set -g @themux_windows_line "spaced"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

printf "\nspaced_status "
tmux show -gv status
printf "spaced_line1_blank [%s]\n" "$(tmux show -gv 'status-format[1]')"
printf "spaced_line2_has_list "
tmux show -gv 'status-format[2]' | grep -c 'list=on align' || true
