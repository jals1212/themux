#!/usr/bin/env bash

# Set path of script
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Internal reset (synchronous, before the rebuild below) so a re-source always
# starts clean — switch theme/variant/style and just reload, no `kill-server`.
# Runs only when a previous themux load is detected (@thm_bg set). It clears
# what themux *derives* (palette, internals, the variant-set separators and the
# status/window/pane formats) but never the user's @themux_* config options, so
# your variants, module lists and overrides survive the reload.
if [ -n "$(tmux show -gqv @thm_bg)" ]; then
  tmux show -g | awk '$1 ~ /^@(thm_|_tmx_)/ { print $1 }' |
    while read -r o; do tmux set -gu "$o"; done
  for o in \
    @themux_pane_left_border @themux_pane_right_border \
    status status-format \
    window-status-format window-status-current-format window-status-style \
    window-status-current-style window-status-last-style window-status-separator \
    window-status-activity-style window-status-bell-style \
    mode-style message-style message-command-style clock-mode-colour \
    menu-selected-style popup-style popup-border-style \
    pane-border-style pane-active-border-style pane-border-format pane-border-status; do
    tmux set -gu "$o" 2>/dev/null
    tmux set -wgu "$o" 2>/dev/null
  done
fi

tmux source "${PLUGIN_DIR}/themux_options.conf"
tmux source "${PLUGIN_DIR}/themux.conf"
