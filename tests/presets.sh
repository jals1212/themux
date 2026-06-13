#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

load() {
  tmux source "${script_dir}/../themux_options.conf"
  tmux source "${script_dir}/../themux.conf"
}
reset_opts() {
  for o in @themux_preset @themux_status_variant @themux_windows_variant \
           @themux_panes_variant @themux_status_background @themux_divider_text \
           @themux_status_left_modules @themux_status_right_modules; do
    tmux set -gu "$o" 2>/dev/null
  done
}

# classic preset: rounded blocks, themed bg, module lists set
tmux set -g @themux_preset "classic"
load
print_option @themux_status_variant
print_option @themux_status_background
printf "classic_left_has_session "
tmux show -gv @themux_status_left_modules | grep -c "session" || true
printf "classic_right_has_ram "
tmux show -gv @themux_status_right_modules | grep -c "ram" || true

# A user option set before load wins over the preset
reset_opts
tmux set -g @themux_status_variant "squared"
tmux set -g @themux_preset "classic"
load
print_option @themux_status_variant

# minimal preset: flat, transparent, dividers in the lists
reset_opts
tmux set -g @themux_preset "minimal"
load
print_option @themux_status_variant
print_option @themux_status_background
printf "minimal_left_has_divider "
tmux show -gv @themux_status_left_modules | grep -c "divider" || true
