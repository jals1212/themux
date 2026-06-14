#!/usr/bin/env bash
# Build `status` and status-format[*] from @themux_status_line_1..5.
#
# Each line is split into zones by "/": none -> one left column, one ->
# left + right, two -> left / center / right. A zone is a module list (token
# NAMEs, "|" inserts the divider, space = adjacent) or the special token
# "windows". Rows render up to the last non-empty line, so a blank ("") line in
# between becomes an empty row (status off when every line is empty).

# tmux-cpu only interpolates its literals (#{ram_percentage}, ...) into
# status-left/right, so surface them into their #(script) form here — that lets
# cpu/ram sit in any zone of any line, not just the left/right edges.
cpu_tmux="${TMUX_PLUGIN_MANAGER_PATH}/tmux-cpu/cpu.tmux"
# shellcheck disable=SC1090
[ -r "$cpu_tmux" ] && source "$cpu_tmux" >/dev/null 2>&1
type do_interpolation >/dev/null 2>&1 || do_interpolation() { printf '%s' "$1"; }

windows_block=$(tmux show -gqv @_tmx_fmt_windows)

# Expand one zone ($1) into a format fragment, aligned per $2 (left|centre|right).
expand_zone() {
  local zone align out token seg
  zone="${1//|/ divider }"
  align="$2"
  out=""
  for token in $zone; do
    case "$token" in
      windows)
        out+="${windows_block//%ALIGN%/$align}"
        ;;
      divider)
        out+="#{E:@_tmx_module_divider}"
        ;;
      *)
        if [ "$(tmux show -gqv "@themux_${token}_expand")" = "yes" ]; then
          tmux set -gF @_tmx_layout_tmp "#{E:@themux_module_${token}}"
          seg=$(tmux show -gv @_tmx_layout_tmp)
          out+="$(do_interpolation "$seg")"
        else
          out+="#{E:@themux_module_${token}}"
        fi
        ;;
    esac
  done
  printf '%s' "$out"
}

# Last line that has any content; rows 1..last render (blank ones included).
last=0
for i in 1 2 3 4 5; do
  [ -n "$(tmux show -gqv "@themux_status_line_${i}")" ] && last=$i
done

for i in 1 2 3 4 5; do
  [ "$i" -gt "$last" ] && break
  line=$(tmux show -gqv "@themux_status_line_${i}")

  # Count "/" to pick the zones: 0 -> left only, 1 -> left + right, 2+ -> three.
  nslash=0 rest="$line"
  while [ "$rest" != "${rest#*/}" ]; do
    rest="${rest#*/}"
    nslash=$((nslash + 1))
  done
  case "$nslash" in
    0) left="$line" center="" right="" ;;
    1) left="${line%%/*}" right="${line#*/}" center="" ;;
    *) IFS='/' read -r left center right <<<"$line" ;;
  esac

  # "nolist" leaves the window-list region the "windows" token turns on, so a
  # zone after it still pins to its own edge (otherwise the right zone stays
  # glued to the window list instead of the right edge).
  fmt="#[nolist align=left]$(expand_zone "$left" left)"
  fmt+="#[nolist align=centre]$(expand_zone "$center" centre)"
  fmt+="#[nolist align=right]$(expand_zone "$right" right)"

  tmux set -g "status-format[$((i - 1))]" "$fmt"
done

tmux set -gu @_tmx_layout_tmp
# `status` takes off / on (1 row) / 2..5; a literal "1" is rejected.
case "$last" in
  0) tmux set -g status off ;;
  1) tmux set -g status on ;;
  *) tmux set -g status "$last" ;;
esac
exit 0
