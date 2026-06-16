#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# Tests that unstyled variants leave every item untouched
tmux set -g @themux_module_shape "unstyled"
tmux set -g @themux_window_shape "unstyled"
tmux set -g @themux_pane_shape "unstyled"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

# Modules are not rendered (grep exits 1 on zero matches)
printf "\nstatus_application_set "
tmux show -g | grep -c "@themux_module_application" || true

# Window and pane styling stay at tmux defaults
print_option window-status-format
print_option window-status-current-format
printf "pane_border_style "
tmux show -gwv pane-border-style
