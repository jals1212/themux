#!/usr/bin/env bash

# Unsets (removes) any styling options that will contaminate
# subsequent test runs.
function reset() {
  tmux set -gu @themux_window_current_left_border
  tmux set -gu @themux_window_current_middle_separator
  tmux set -gu @themux_window_current_right_border
  tmux set -gu @themux_window_variant
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format

# Test the rounded style
reset
tmux set -g @themux_window_variant "rounded"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format

# Test the basic style with the number on the right
reset
tmux set -g @themux_window_number_position "right"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format

# Empty window text drops the text container: only the number block shows.
reset
tmux set -g @themux_window_number_position "left"
tmux set -g @themux_window_text ""
tmux set -g @themux_window_current_text ""
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format
