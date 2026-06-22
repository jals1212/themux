#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

tmux set -g @themux_pane_status "top"

tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option pane-border-format

# Switch the number position to the right
tmux set -g @themux_pane_leading_position "right"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

tmux set -g @themux_pane_leading_position "left" # reset

# Whole label one colour: both blocks solid
tmux set -g @themux_pane_leading_variant "solid"
tmux set -g @themux_pane_text_variant "solid"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

# Neutral, no accent: both blocks soft
tmux set -g @themux_pane_leading_variant "soft"
tmux set -g @themux_pane_text_variant "soft"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format
