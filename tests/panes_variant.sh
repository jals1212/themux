#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# Flat panes: plain borders on the default background
tmux set -g @themux_panes_variant "flat"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-style
print_option pane-active-border-style

# Rounded panes: cap glyphs in the pane-status separators
tmux set -g @themux_panes_variant "rounded"
tmux set -g @themux_pane_status "top"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option @themux_pane_left_separator
print_option @themux_pane_right_separator

# Unstyled panes: themux leaves pane styling untouched
tmux set -gu @themux_pane_status
tmux set -g @themux_panes_variant "unstyled"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
printf "pane_border_style_unstyled "
tmux show -gwv pane-border-style
