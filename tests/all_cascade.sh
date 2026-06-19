#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

run_layout() { tmux run-shell "${script_dir}/../utils/layout.sh"; }
src() {
  tmux source "${script_dir}/../themux_options.conf"
  tmux source "${script_dir}/../themux.conf"
}
rcap=$(printf '\356\202\266') # rounded left cap (E0B6)
# `|| true` so a zero count does not trip the harness ERR trap.
win_caps() { tmux show -gv window-status-format | { grep -o "$rcap" || true; } | wc -l | tr -d ' '; }
mod_caps() { tmux show -gv @themux_module_session | { grep -o "$rcap" || true; } | wc -l | tr -d ' '; }

tmux set -g @themux_status_line_1 "session"

# @themux_all_shape sets the shape for ALL items at once: a rounded value reaches
# both the window list and modules (rounded caps appear in their formats).
tmux set -g @themux_all_shape "rounded"
src
run_layout
printf "\nall_rounded_window "; win_caps
printf "all_rounded_module "; mod_caps

# Default (all back to squared): no rounded caps anywhere.
tmux set -gu @themux_all_shape
src
run_layout
printf "\ndefault_window "; win_caps
printf "default_module "; mod_caps

# Per-item beats @themux_all_*: window squared while the shared value is rounded;
# modules still follow the shared rounded value.
tmux set -g @themux_all_shape "rounded"
tmux set -g @themux_window_shape "squared"
src
run_layout
printf "\noverride_window "; win_caps
printf "override_module "; mod_caps
