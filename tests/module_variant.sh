#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

core() { tmux show -gqv "@_tmx_module_$1_core"; }
src() {
  tmux source "${script_dir}/../themux_options.conf"
  tmux source "${script_dir}/../themux.conf"
}

# A metric module's live threshold colour is its accent; the default solid variant
# renders a contrast pill (crust text on the live bg) that can never go blank —
# the old per-channel "both" highlight collapsed fg and bg to the same colour.
tmux set -g @themux_status_line_1 "cpu session host"
src
printf "\ncpu_live "
core cpu | grep -c 'cpu_bg_color' || true
printf "cpu_not_blank "
{ core cpu | grep -qF 'fg=#{l:#{cpu_bg_color}},bg=#{l:#{cpu_bg_color}}'; } && printf "blank" || printf "ok"

# Per-single-module override beats the all-modules tier: @themux_cpu_text_variant
# naked wins over @themux_module_text_variant solid, so cpu's text drops its block.
tmux set -g @themux_module_text_variant "solid"
tmux set -g @themux_cpu_text_variant "naked"
src
printf "\ncpu_text_naked "
{ core cpu | grep -qF 'bg=default]#{E:@themux_cpu_text}'; } && printf "Y" || printf "n"
tmux set -gu @themux_module_text_variant
tmux set -gu @themux_cpu_text_variant

# A stateful module: session carries its prefix accent at draw time through
# @themux_<name>_active_when, so the active reference is always in the segment.
src
printf "\nsession_prefix "
core session | grep -c 'client_prefix' || true

# Leading position: right swaps the block order, so the left/right edge colours
# swap too (icon-then-text -> text-then-icon).
tmux set -g @themux_status_line_1 "host"
tmux set -g @themux_module_leading_position "left"
src
ll=$(tmux show -gqv @_tmx_module_host_lbg) lr=$(tmux show -gqv @_tmx_module_host_rbg)
tmux set -g @themux_module_leading_position "right"
src
rl=$(tmux show -gqv @_tmx_module_host_lbg) rr=$(tmux show -gqv @_tmx_module_host_rbg)
printf "\nposition_swaps_edges "
{ [ "$ll" = "$rr" ] && [ "$lr" = "$rl" ] && [ "$ll" != "$lr" ]; } && printf "Y" || printf "n"
