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

# Powerline cap glyphs for the module shape. Empty for squared/unstyled, where
# modules abut as their own full pills; rounded/slanted connect adjacent modules.
mshape=$(tmux show -gqv @themux_module_shape)
case "$mshape" in
  rounded) mpll=$(printf '\356\202\266'); mprr=$(printf '\356\202\264') ;;
  slanted) mpll=$(printf '\356\202\272'); mprr=$(printf '\356\202\274') ;;
  *)       mpll=""; mprr="" ;;
esac

# tmux-cpu modules (cpu/ram) carry #{cpu_*}/#{ram_*} literals that only resolve
# in status-left/right, so do_interpolation rewrites them to #(...) form. These
# helpers apply it for those modules and pass everything else through unchanged.
mod_field() { # $1 module, $2 edge option (lcol|rcol|lbg) -> a usable colour
  if [ "$(tmux show -gqv "@themux_${1}_expand")" = "yes" ]; then
    tmux set -gF @_tmx_layout_tmp "#{E:@_tmx_module_${1}_${2}}"
    do_interpolation "$(tmux show -gv @_tmx_layout_tmp)"
  else
    tmux show -gqv "@_tmx_module_${1}_${2}"
  fi
}
mod_core() { # $1 module -> its bare core (a ref normally; inlined for tmux-cpu)
  if [ "$(tmux show -gqv "@themux_${1}_expand")" = "yes" ]; then
    tmux set -gF @_tmx_layout_tmp "#{E:@_tmx_module_${1}_core}"
    do_interpolation "$(tmux show -gv @_tmx_layout_tmp)"
  else
    printf '%s' "#{E:@_tmx_module_${1}_core}"
  fi
}
full_pill() { # $1 module -> its own pill, caps included (inlined for tmux-cpu)
  if [ "$(tmux show -gqv "@themux_${1}_expand")" = "yes" ]; then
    tmux set -gF @_tmx_layout_tmp "#{E:@themux_module_${1}}"
    do_interpolation "$(tmux show -gv @_tmx_layout_tmp)"
  else
    printf '%s' "#{E:@themux_module_${1}}"
  fi
}

# Connect a run of adjacent modules ($@) powerline-style: a left cap, each
# module's bare core, a connector between neighbours (the left module's right
# colour tapering into the right module's left background), then a right cap.
powerline_run() {
  local m out2="" first=1 prev_rcol=""
  for m in "$@"; do
    if [ "$first" = 1 ]; then
      out2+="#[fg=$(mod_field "$m" lcol),bg=default]${mpll}"
      first=0
    else
      out2+="#[fg=${prev_rcol},bg=$(mod_field "$m" lbg)]${mprr}"
    fi
    out2+="$(mod_core "$m")"
    prev_rcol=$(mod_field "$m" rcol)
  done
  out2+="#[fg=${prev_rcol},bg=default]${mprr}"
  printf '%s' "$out2"
}

# Expand one zone ($1) into a format fragment, aligned per $2 (left|centre|right).
# Consecutive modules connect powerline-style (rounded/slanted); a lone module
# ('|' divider) or a squared shape keeps its own full pill.
expand_zone() {
  local zone align out token run=()
  zone="${1//|/ divider }"
  align="$2"
  out=""
  flush() {
    case ${#run[@]} in
      0) ;;
      1) out+="$(full_pill "${run[0]}")" ;;
      *) out+="$(powerline_run "${run[@]}")" ;;
    esac
    run=()
  }
  for token in $zone; do
    case "$token" in
      windows)
        flush
        out+="${windows_block//%ALIGN%/$align}"
        ;;
      divider)
        flush
        out+="#{E:@_tmx_module_divider}"
        ;;
      *)
        # squared/unstyled has no connector glyph, so each module is its own
        # pill; rounded/slanted accumulate into a connected run.
        if [ -z "$mpll" ]; then
          flush
          out+="$(full_pill "$token")"
        else
          run+=("$token")
        fi
        ;;
    esac
  done
  flush
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
