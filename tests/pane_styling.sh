#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

tmux set -g @themux_pane_status_enabled "yes"

tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option pane-border-format

# Switch the number position to the right
tmux set -g @themux_pane_number_position "right"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

tmux set -g @themux_pane_number_position "left" # reset

# Fill option "all"
tmux set -g @themux_pane_default_fill "all"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

tmux set -g @themux_pane_default_fill "number" # reset

# Fill option "none"
tmux set -g @themux_pane_default_fill "none"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format
