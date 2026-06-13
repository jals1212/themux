#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# Tests the flat status module and window status style
tmux set -g @themux_status_variant "flat"
tmux set -g @themux_windows_variant "flat"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option @themux_status_application | grep -q "@thm_" &&
  echo "@themux_status_application did not expand all colors"

print_option @themux_status_application | sed -E 's/(bash|fish|zsh)/<application>/'
print_option @themux_status_session
print_option @themux_status_divider
print_option @themux_status_zoom
print_option window-status-format
print_option window-status-current-format
print_option window-status-style
print_option window-status-current-style
print_option window-status-separator
