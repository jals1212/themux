#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# Naked panes: transparent blocks (indicator + text) on the default background
tmux set -g @themux_pane_indicator "naked"
tmux set -g @themux_pane_text "naked"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-style
print_option pane-active-border-style

# Naked panes render a status label when the status is enabled (regression: the
# naked variant used to set no pane-border-format at all).
tmux set -g @themux_pane_status "top"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-status
print_option pane-border-format

# Rounded panes: the shape adds its cap glyphs to the pane-status format.
tmux set -g @themux_pane_shape "rounded"
tmux set -g @themux_pane_status "top"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

# Rounded capsule: a solid indicator and a naked text framed by the rounded caps
# (the caps outline in the accent when the block background is transparent).
tmux set -g @themux_pane_shape "rounded"
tmux set -g @themux_pane_indicator "solid"
tmux set -g @themux_pane_text "naked"
tmux set -g @themux_pane_status "top"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

# Notch: the indicator block's right cap seams into the text block (number on the
# left). With indicator solid + text soft the backgrounds differ, so the seam
# shows; if they matched it would collapse to nothing (no phantom cell).
tmux set -g @themux_pane_shape "squared"
tmux set -g @themux_pane_indicator "solid"
tmux set -g @themux_pane_text "soft"
tmux set -g @themux_pane_notch "on"
tmux set -g @themux_pane_status "top"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option pane-border-format

# Unstyled panes: themux leaves pane styling untouched
tmux set -gu @themux_pane_status
tmux set -g @themux_pane_shape "unstyled"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
printf "pane_border_style_unstyled "
tmux show -gwv pane-border-style
