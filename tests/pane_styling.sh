#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

tmux set -g @themux_pane_status "top"

tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option pane-border-format

# Switch the number position to the right
tmux set -g @themux_pane_number_position "right"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

tmux set -g @themux_pane_number_position "left" # reset

# Fill "fill" (whole label one color), via the variant grammar
tmux set -g @themux_pane_variant "squared fill"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

tmux set -g @themux_pane_variant "squared" # reset

# Fill "none" (neutral, no accent)
tmux set -g @themux_pane_variant "squared none"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format
