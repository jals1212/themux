#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

core() { tmux show -gqv "@_tmx_module_$1_core"; }

# cpu (block style): the live threshold rides in as the icon override only when
# the alert toggle includes it; off keeps the calm (low) colour.
tmux set -g @themux_status_line_1 "cpu"
tmux set -g @themux_module_indicator_highlight "both"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
printf "\ncpu_both_live "
core cpu | grep -c 'cpu_bg_color' || true
printf "cpu_both_calm "
core cpu | grep -c 'cpu_low_bg_color' || true

tmux set -g @themux_module_indicator_highlight "off"
tmux set -g @themux_module_text_highlight "off"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
printf "\ncpu_off_live "
core cpu | grep -c 'cpu_bg_color' || true
printf "cpu_off_calm "
core cpu | grep -c 'cpu_low_bg_color' || true

# session (block style): the prefix red rides in as the icon override only when
# the toggle includes it; off leaves the base colour (no client_prefix).
tmux set -g @themux_status_line_1 "session"
tmux set -g @themux_module_indicator_highlight "both"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
printf "\nsession_both_prefix "
core session | grep -c 'client_prefix' || true

tmux set -g @themux_module_indicator_highlight "off"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
printf "\nsession_off_prefix "
core session | grep -c 'client_prefix' || true
