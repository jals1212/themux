#!/usr/bin/env bash

# Unsets (removes) any styling options that will contaminate
# subsequent test runs.
function reset() {
  tmux set -gu @themux_window_shape
  tmux set -gu @themux_window_leading
  tmux set -gu @themux_window_text
  tmux set -gu @themux_window_notch
  tmux set -gu @themux_window_divider
  tmux set -gu @themux_window_seam
  tmux set -gu @themux_window_leading_highlight
  tmux set -gu @themux_window_text_highlight
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
tmux set -g @themux_window_shape "rounded"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format

# Test the basic style with the number on the right
reset
tmux set -g @themux_window_leading_position "right"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format

# Empty window text drops the text container: only the number block shows.
reset
tmux set -g @themux_window_leading_position "left"
tmux set -g @themux_window_name ""
tmux set -g @themux_window_current_name ""
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format

# Connected ribbon (@themux_window_seam "<>"): windows draw blocks only (the
# separator joins them), the first window (window_index == base-index) opens with
# a left cap, the last closes with a tail cap, and the raised separator is
# neighbour-aware so the active window's caps overlay both sides.
reset
tmux set -g @themux_window_leading_position "left"
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_seam "<>"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format
print_option window-status-separator

# Seam styles (rounded): > a uniform right-cap seam, < a uniform left-cap seam,
# = a flat seam (empty separator); each still connects the list.
reset
tmux set -g @themux_window_leading_position "left"
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_seam ">"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option window-status-separator

reset
tmux set -g @themux_window_leading_position "left"
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_seam "<"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option window-status-separator

reset
tmux set -g @themux_window_leading_position "left"
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_seam "="
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option window-status-separator

# Active highlight: leading_highlight=off freezes the active number block at
# the inactive (base) colour; the name block still takes its highlight colour.
reset
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_leading_highlight "off"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-current-format

# Powerline shape: separate window pills get the powerline arrow caps (E0B2 left,
# E0B0 right) on both sides.
reset
tmux set -g @themux_window_shape "powerline"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option window-status-format
print_option window-status-current-format
