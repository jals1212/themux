#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# Tests the naked status module and window status style
tmux set -g @themux_module_indicator "naked"
tmux set -g @themux_module_text "naked"
tmux set -g @themux_window_variant "naked"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option @themux_module_application | grep -q "@thm_" &&
  echo "@themux_module_application did not expand all colors"

print_option @themux_module_application | sed -E 's/(bash|fish|zsh)/<application>/'
print_option @themux_module_session
print_option @_tmx_module_divider
print_option @themux_module_zoom
print_option window-status-format
print_option window-status-current-format
print_option window-status-style
print_option window-status-current-style
print_option window-status-separator
