#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# Tests the two-line layout: window list moves to status line 1
tmux set -g @themux_windows_line "1"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

printf "\nstatus "
tmux show -gv status

printf "format1 "
tmux show -gv 'status-format[1]' | cut -c1-60

# Line 0 must not contain the window list (grep exits 1 on zero matches)
printf "format0_has_list "
tmux show -gv 'status-format[0]' | grep -c 'list=on align' || true
