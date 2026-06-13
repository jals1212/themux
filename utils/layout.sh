#!/usr/bin/env bash
# Build `status` and status-format[*] from @themux_status_line_1..5.
#
# Each line is "<left> / <center> / <right>". A zone is a module list (token
# NAMEs, "|" inserts the modules divider, space = adjacent) or the special
# token "windows" (the window list). Blank zones render nothing; the number of
# non-empty lines sets how many status rows are shown (status off when none).

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
        out+="#{E:@_tmx_status_divider}"
        ;;
      *)
        if [ "$(tmux show -gqv "@themux_${token}_expand")" = "yes" ]; then
          tmux set -gF @_tmx_layout_tmp "#{E:@themux_status_${token}}"
          seg=$(tmux show -gv @_tmx_layout_tmp)
          out+="$(do_interpolation "$seg")"
        else
          out+="#{E:@themux_status_${token}}"
        fi
        ;;
    esac
  done
  printf '%s' "$out"
}

n=0
for i in 1 2 3 4 5; do
  line=$(tmux show -gqv "@themux_status_line_${i}")
  case "$line" in
    *[![:space:]]*) ;; # has a non-space character: render it
    *) continue ;;     # blank line: skip
  esac

  IFS='/' read -r left center right <<<"$line"
  fmt="#[align=left]$(expand_zone "$left" left)"
  fmt+="#[align=centre]$(expand_zone "$center" centre)"
  fmt+="#[align=right]$(expand_zone "$right" right)"

  tmux set -g "status-format[${n}]" "$fmt"
  n=$((n + 1))
done

tmux set -gu @_tmx_layout_tmp
# `status` takes off / on (1 row) / 2..5; a literal "1" is rejected. A lower
# row count just hides the higher status-format[i], which the next run rewrites.
case "$n" in
  0) tmux set -g status off ;;
  1) tmux set -g status on ;;
  *) tmux set -g status "$n" ;;
esac
exit 0
