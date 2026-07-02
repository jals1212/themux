#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# A module renders only when referenced in a status line (lazy render).
tmux set -g @themux_status_line_1 "application"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option @themux_module_application | grep -q "@thm_" &&
  echo "@themux_module_application did not expand all colors"

print_option @themux_module_application | sed -E 's/(bash|fish|zsh)/<application>/'

# Notch: the icon<->text seam takes the shape's right cap instead of the plain
# middle separator (the module color tapering into the text background). ">" is
# explicit (not zone-aware), so it bakes directly here without utils/layout.sh
# splicing in the seam — "auto"/"on" cannot resolve outside a real status line.
tmux set -g @themux_module_shape "rounded"
tmux set -g @themux_module_notch ">"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option @themux_module_application | sed -E 's/(bash|fish|zsh)/<application>/'

# Powerline shape: the module's outer caps are the powerline arrows (E0B2 left,
# E0B0 right) instead of the rounded bulges.
tmux set -g @themux_module_shape "powerline"
tmux set -g @themux_module_notch "off"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option @themux_module_application | sed -E 's/(bash|fish|zsh)/<application>/'
