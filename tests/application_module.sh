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
