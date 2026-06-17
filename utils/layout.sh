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

# Emptying the divider ("") connects across "|" too: the divider token becomes
# transparent so modules on either side join the same run, mirroring how an
# empty window divider connects the window list.
mdiv=$(tmux show -gqv @themux_module_divider)

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

# Connect a run of adjacent modules ($@, $1 = zone alignment) powerline-style: a
# left cap, each module's bare core, a connector between neighbours, then a right
# cap. The flow follows the zone: left/centre runs taper left-to-right (the left
# module curves into the right); a right-aligned rounded run mirrors it so the
# seam bulges the other way (the right module curves into the left). Only the
# inner connector changes — the outer caps are a pill in either direction.
#
# A conditional module (@themux_<name>_when, e.g. gitmux/zoom) only joins while
# its condition holds, at ANY position: the head cap reflows to whichever module
# is first visible, the connector colour falls back to the previous visible
# module, and a run whose every module is hidden collapses to nothing (no stray
# cap left on the bar).
powerline_run() {
  local dir="$1"; shift
  local mirror=0
  [ "$mshape" = rounded ] && [ "$dir" = right ] && mirror=1

  local m cond lcol lbg rcol rbg core head conn seg
  local out2="" prc="" prb=""   # prev visible module's right colour / right bg
  local shown="0" shown_fixed=1 # shown: anything visible yet? (fixed while constant)
  for m in "$@"; do
    cond=$(tmux show -gqv "@themux_${m}_when")
    lcol=$(mod_field "$m" lcol); lbg=$(mod_field "$m" lbg)
    rcol=$(mod_field "$m" rcol); rbg=$(mod_field "$m" rbg)
    core=$(mod_core "$m")
    head="#[fg=${lcol},bg=default]${mpll}${core}"
    if [ "$mirror" = 1 ]; then
      conn="#[fg=${lcol},bg=${prb}]${mpll}${core}"
    else
      conn="#[fg=${prc},bg=${lbg}]${mprr}${core}"
    fi

    # Head cap for the first visible module, connector once something precedes
    # it. While "shown" is still constant the choice is static; once a
    # conditional makes it dynamic, both forms are stashed (they carry commas)
    # and the draw-time #{?} picks one.
    if [ "$shown_fixed" = 1 ]; then
      [ "$shown" = 0 ] && seg="$head" || seg="$conn"
    else
      tmux set -g "@_tmx_plh_${m}" "$head"
      tmux set -g "@_tmx_plc_${m}" "$conn"
      seg="#{?${shown},#{E:@_tmx_plc_${m}},#{E:@_tmx_plh_${m}}}"
    fi

    if [ -n "$cond" ]; then
      tmux set -g "@_tmx_pl_${m}" "$seg"
      out2+="#{?${cond},#{E:@_tmx_pl_${m}},}"
      prc="#{?${cond},${rcol},${prc}}"
      prb="#{?${cond},${rbg},${prb}}"
      if [ "$shown_fixed" = 1 ] && [ "$shown" = 1 ]; then
        :                               # an earlier module is always visible
      elif [ "$shown_fixed" = 1 ]; then
        shown="${cond}"; shown_fixed=0
      else
        shown="#{?${cond},1,${shown}}"
      fi
    else
      out2+="$seg"
      prc="$rcol"; prb="$rbg"; shown="1"; shown_fixed=1
    fi
  done

  # Right cap, only when the run has a visible module (a pill close either way).
  if [ "$shown_fixed" = 1 ]; then
    [ "$shown" = 1 ] && out2+="#[fg=${prc},bg=default]${mprr}"
  else
    tmux set -g "@_tmx_plt_${m}" "#[fg=${prc},bg=default]${mprr}"
    out2+="#{?${shown},#{E:@_tmx_plt_${m}},}"
  fi
  printf '%s' "$out2"
}

# Expand one zone ($1) into a format fragment, aligned per $2 (left|centre|right).
# Consecutive modules connect powerline-style (rounded/slanted); a squared shape
# keeps its own full pill. A non-empty '|' divider breaks the run and draws the
# divider; an empty divider connects through it (see mdiv above).
expand_zone() {
  local zone align out token run=()
  zone="${1//|/ divider }"
  align="$2"
  out=""
  flush() {
    case ${#run[@]} in
      0) ;;
      1) out+="$(full_pill "${run[0]}")" ;;
      *) out+="$(powerline_run "$align" "${run[@]}")" ;;
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
        # An empty divider connects through "|": stay in the run, emit nothing.
        if [ -n "$mdiv" ]; then
          flush
          out+="#{E:@_tmx_module_divider}"
        fi
        ;;
      *)
        # squared/unstyled has no connector glyph, so each module is its own
        # pill; rounded/slanted accumulate into a connected run (conditional
        # modules connect through draw-time gating inside powerline_run).
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
