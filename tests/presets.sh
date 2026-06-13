#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

load() {
  tmux source "${script_dir}/../themux_options.conf"
  tmux source "${script_dir}/../themux.conf"
}
# Unset what a preset/defaults set, so the next scenario applies fresh.
reset_opts() {
  for o in @themux_preset @themux_status_variant @themux_windows_variant \
           @themux_panes_variant @themux_status_background @themux_divider_text; do
    tmux set -gu "$o" 2>/dev/null
  done
}

# classic preset: rounded blocks, themed background, composed status-left
tmux set -g @themux_preset "classic"
load
print_option @themux_status_variant
print_option @themux_status_background
printf "classic_left_composed "
tmux show -gv status-left | grep -c "@themux_status_session" || true

# A user option set before load wins over the preset
reset_opts
tmux set -g @themux_status_variant "squared"
tmux set -g @themux_preset "classic"
load
print_option @themux_status_variant

# minimal preset: flat modules, transparent background
reset_opts
tmux set -g @themux_preset "minimal"
load
print_option @themux_status_variant
print_option @themux_status_background
