#!/usr/bin/env bash

# Set path of script
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Internal reset (synchronous, before the rebuild below) so a re-source always
# starts clean — switch theme/variant/style and just reload, no `kill-server`.
# Runs only when a previous themux load is detected (@thm_bg set). It clears
# what themux *derives* (palette, internals, the variant-set separators and the
# status/window/pane formats) but never the user's @themux_* config options, so
# your variants, module lists and overrides survive the reload.
#
# Every unset is chained into ONE tmux command so the teardown is a single
# client round-trip (one redraw) instead of dozens — far less reload flicker.
# A sequence keeps running past a failing command, so the -gu/-wgu shotgun
# (each option lives in only one scope) is safe.
if [ -n "$(tmux show -gqv @thm_bg)" ]; then
  reset_args=()
  add() { [ ${#reset_args[@]} -eq 0 ] || reset_args+=(';'); reset_args+=("$@"); }
  while read -r o; do add set -gu "$o"; done \
    < <(tmux show -g | awk '$1 ~ /^@(thm_|_tmx_)/ { print $1 }')
  for o in \
    status status-format \
    window-status-format window-status-current-format window-status-style \
    window-status-current-style window-status-last-style window-status-separator \
    window-status-activity-style window-status-bell-style \
    mode-style message-style message-command-style clock-mode-colour \
    menu-selected-style popup-style popup-border-style \
    pane-border-style pane-active-border-style pane-border-format pane-border-status; do
    add set -gu "$o"; add set -wgu "$o"
  done
  [ ${#reset_args[@]} -gt 0 ] && tmux "${reset_args[@]}" 2>/dev/null
fi

tmux source "${PLUGIN_DIR}/themux_options.conf"
tmux source "${PLUGIN_DIR}/themux.conf"
