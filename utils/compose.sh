#!/usr/bin/env bash
# Expand a themux module list into a status option.
#
# Usage: compose.sh <status-left|status-right> "<space-separated module list>"
#
# Each token NAME becomes the segment #{E:@themux_status_NAME}, resolved at
# draw time. Modules that set @themux_NAME_expand "yes" are expanded inline at
# compose time instead (with -F), so plugin literals like #{ram_percentage}
# are surfaced into the option value.

option="$1"
list="$2"

tmux set -g "$option" ""
for m in $list; do
  if [ "$(tmux show -gqv "@themux_${m}_expand")" = "yes" ]; then
    tmux set -agF "$option" "#{E:@themux_status_${m}}"
  else
    tmux set -ag "$option" "#{E:@themux_status_${m}}"
  fi
done

# tmux-cpu interpolates its #{*_percentage} literals into status-left/right at
# parse time, before this deferred compose runs — so re-apply it to the freshly
# composed option. No-op when tmux-cpu is absent or no literal remains.
cpu_tmux="${TMUX_PLUGIN_MANAGER_PATH}/tmux-cpu/cpu.tmux"
[ -x "$cpu_tmux" ] && "$cpu_tmux" >/dev/null 2>&1
exit 0
