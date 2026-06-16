#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# Tests that the default options are set correctly
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

print_option @themux_module_application | grep -q "@thm_" &&
  echo "@themux_module_application did not expand all colors"

print_option @themux_module_application | sed -E 's/(bash|fish|zsh)/<application>/'

# Notch: the icon<->text seam takes the shape's right cap instead of the plain
# middle separator (the module color tapering into the text background).
tmux set -g @themux_module_shape "rounded"
tmux set -g @themux_module_notch "on"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
print_option @themux_module_application | sed -E 's/(bash|fish|zsh)/<application>/'
