#!/usr/bin/env bash
# Build `status` and status-format[*] from @themux_status_line_1..5.
#
# Each line is split into zones by "/": none -> one left column, one ->
# left + right, two -> left / center / right. A zone is a module list (token
# NAMEs; "|" inserts the divider, a space leaves each module its own pill, and
# =/>/< merge modules into one capped group) or the special token "windows".
# Rows render up to the last non-empty line, so a blank ("") line in between
# becomes an empty row (status off when every line is empty).

# tmux-cpu only interpolates its literals (#{ram_percentage}, ...) into
# status-left/right, so surface them into their #(script) form here — that lets
# cpu/ram sit in any zone of any line, not just the left/right edges.
cpu_tmux="${TMUX_PLUGIN_MANAGER_PATH}/tmux-cpu/cpu.tmux"
# shellcheck disable=SC1090
[ -r "$cpu_tmux" ] && source "$cpu_tmux" >/dev/null 2>&1
type do_interpolation >/dev/null 2>&1 || do_interpolation() { printf '%s' "$1"; }

windows_block=$(tmux show -gqv @_tmx_fmt_windows)

# Powerline cap glyphs for the module shape. Empty for squared/unstyled (no caps,
# so the =/>/< connectors are inert and every module stays its own full pill).
mshape=$(tmux display -p "#{?#{@themux_module_shape},#{@themux_module_shape},#{@themux_all_shape}}")
case "$mshape" in
  rounded)   mpll=$(printf '\356\202\266'); mprr=$(printf '\356\202\264') ;;
  slanted)   mpll=$(printf '\356\202\272'); mprr=$(printf '\356\202\274') ;;
  powerline) mpll=$(printf '\356\202\262'); mprr=$(printf '\356\202\260') ;;
  *)         mpll=""; mprr="" ;;
esac

# The divider "|" inserts between modules; emptying it ("") just drops the
# segment (modules stay separate pills — merging is done with =/>/< instead).
mdiv=$(tmux show -gqv @themux_module_divider)

# Edge flush (nvim-style) is part of the status-line grammar: a leading "=" on the
# left zone, or a trailing "=" on the right zone, drops that edge's outer cap so
# the block fills flat to the terminal border. It mirrors the "=" connector (a
# flat, capless seam) carried out to the bar's edge. One marker flushes whatever
# sits there — a module group OR the window ribbon — and it is per line; the
# centre zone never touches an edge. Parsed in the per-line loop below.

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

# Connect a GROUP of modules (joined in the layout string by =, > or <) into one
# powerline strip: a left cap, each module's bare core, a per-seam connector, a
# right cap. $1 is the space-joined module list, $2 the parallel connector list
# (one token per module; the first is "head"). Each seam follows the right
# module's incoming connector: > = the left module's colour penetrates right
# (mprr glyph); < = this module penetrates left (mpll glyph); = = flat, the bare
# cores abut as a squared seam (no glyph). The outer caps are always the shape's
# caps, regardless of the inner seams; $3/$4 (0/1) flush the left/right outer cap
# — dropping it so the edge block fills to the terminal border (nvim-style).
#
# A conditional module (@themux_<name>_when, e.g. gitmux/zoom) only joins while
# its condition holds, at ANY position: the head cap reflows to whichever module
# is first visible, the connector colour falls back to the previous visible
# module, and a group whose every module is hidden collapses to nothing (no stray
# cap left on the bar).
powerline_run() {
  local -a mods conns
  read -ra mods <<<"$1"
  read -ra conns <<<"$2"
  local fl="${3:-0}" fr="${4:-0}"   # flush the left/right outer cap to the edge

  local i m c cond lcol lbg rcol rbg core head conn seg
  local out2="" prc="" prb=""   # prev visible module's right colour / right bg
  local shown="0" shown_fixed=1 # shown: anything visible yet? (fixed while constant)
  for i in "${!mods[@]}"; do
    m="${mods[i]}"; c="${conns[i]}"
    cond=$(tmux show -gqv "@themux_${m}_when")
    lcol=$(mod_field "$m" lcol); lbg=$(mod_field "$m" lbg)
    rcol=$(mod_field "$m" rcol); rbg=$(mod_field "$m" rbg)
    core=$(mod_core "$m")
    # flush_left drops the opening cap so the first block fills the terminal edge.
    if [ "$fl" = 1 ]; then head="${core}"; else head="#[fg=${lcol},bg=default]${mpll}${core}"; fi
    # The seam glyph follows this module's incoming connector token.
    case "$c" in
      lt) conn="#[fg=${lcol},bg=${prb}]${mpll}${core}" ;; # < penetrate left
      eq) conn="${core}" ;;                               # = flat squared seam
      *)  conn="#[fg=${prc},bg=${lbg}]${mprr}${core}" ;;  # > penetrate right
    esac

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

  # Right cap, only when the group has a visible module (a pill close either way).
  # flush_right drops it so the last block fills the terminal edge instead.
  if [ "$fr" != 1 ]; then
    if [ "$shown_fixed" = 1 ]; then
      [ "$shown" = 1 ] && out2+="#[fg=${prc},bg=default]${mprr}"
    else
      tmux set -g "@_tmx_plt_${m}" "#[fg=${prc},bg=default]${mprr}"
      out2+="#{?${shown},#{E:@_tmx_plt_${m}},}"
    fi
  fi
  printf '%s' "$out2"
}

# Expand one zone ($1) into a format fragment, aligned per $2 (left|centre|right),
# with $3 = which side touches the terminal and should flush (left|right|none).
# Modules connect only through explicit tokens in the layout string: = (flat
# merge, squared seam), > (left penetrates right) and < (right penetrates left)
# join modules into one capped group; a plain space leaves each module its own
# full pill; "|" separates and draws the divider. squared/unstyled has no caps,
# so the connectors are inert there — every module is its own pill.
#
# Tokens are first collected into items (G=group, D=divider, W=windows) so the
# first/last *group* is known: that is the one whose outer cap flushes to the
# terminal edge when $3 asks for it (capped shapes only; a leading/trailing
# divider or window list owns the edge instead, so no module flushes there).
expand_zone() {
  local zone align edge token pending i out fl fr fg lg last
  local -a it_type it_mods it_conns grp_mods grp_conns m
  align="$2"; edge="$3"
  pending=""
  push_group() {
    [ ${#grp_mods[@]} -eq 0 ] && return
    it_type+=("G"); it_mods+=("${grp_mods[*]}"); it_conns+=("${grp_conns[*]}")
    grp_mods=(); grp_conns=()
  }
  # Make the connectors standalone tokens so a plain space (a group break) is
  # told apart from an explicit join. Module names never contain these glyphs.
  zone="$1"
  zone="${zone//|/ __div__ }"
  zone="${zone//>/ __gt__ }"
  zone="${zone//</ __lt__ }"
  zone="${zone//=/ __eq__ }"
  for token in $zone; do
    case "$token" in
      windows) push_group; it_type+=("W"); it_mods+=(""); it_conns+=(""); pending="" ;;
      __div__) push_group; it_type+=("D"); it_mods+=(""); it_conns+=(""); pending="" ;;
      __gt__|__lt__|__eq__)
        # Joins the next module to the open group; nothing on its left = no-op.
        [ ${#grp_mods[@]} -ge 1 ] && pending="${token//_/}"
        ;;
      *)
        # squared/unstyled has no caps, so connectors are inert: each module is
        # its own one-module group. Otherwise a pending connector extends the
        # open group; a plain space starts a fresh one (its "head").
        if [ -z "$mpll" ]; then
          push_group; it_type+=("G"); it_mods+=("$token"); it_conns+=("head"); pending=""
        elif [ -n "$pending" ]; then
          grp_mods+=("$token"); grp_conns+=("$pending"); pending=""
        else
          push_group; grp_mods+=("$token"); grp_conns+=("head")
        fi
        ;;
    esac
  done
  push_group

  # Flushable groups are the literal first/last item, and only if a group.
  fg=-1; lg=-1; last=$(( ${#it_type[@]} - 1 ))
  [ "$last" -ge 0 ] && [ "${it_type[0]}" = G ] && fg=0
  [ "$last" -ge 0 ] && [ "${it_type[last]}" = G ] && lg=$last

  out=""
  for i in "${!it_type[@]}"; do
    case "${it_type[i]}" in
      W) out+="${windows_block//%ALIGN%/$align}" ;;
      D) [ -n "$mdiv" ] && out+="#{E:@_tmx_module_divider}" ;;
      G)
        fl=0; fr=0
        [ -n "$mpll" ] && [ "$edge" = left ]  && [ "$i" = "$fg" ] && fl=1
        [ -n "$mpll" ] && [ "$edge" = right ] && [ "$i" = "$lg" ] && fr=1
        read -ra m <<<"${it_mods[i]}"
        if [ ${#m[@]} -eq 1 ] && [ "$fl" = 0 ] && [ "$fr" = 0 ]; then
          out+="$(full_pill "${m[0]}")"
        else
          out+="$(powerline_run "${it_mods[i]}" "${it_conns[i]}" "$fl" "$fr")"
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

# Window-list edge flush: 1 when the "windows" token is the first item of a
# flushing left zone or the last of a flushing right zone (any row). Read by
# window_render.sh to drop the ribbon's opening/closing cap at that edge.
win_fl=0; win_fr=0
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

  # Edge flush marker: a leading "=" on the left zone flushes the left border, a
  # trailing "=" on the right zone the right border. Strip it before the zone is
  # parsed (an inline "=" between two modules stays a flat-merge connector). A
  # single-zone row has no right border, so only the left marker applies there.
  l_flush=0; r_flush=0
  lz="${left#"${left%%[![:space:]]*}"}"     # left zone, leading whitespace trimmed
  [ "${lz:0:1}" = "=" ] && { l_flush=1; left="${lz:1}"; }
  rz="${right%"${right##*[![:space:]]}"}"   # right zone, trailing whitespace trimmed
  [ -n "$rz" ] && [ "${rz: -1}" = "=" ] && { r_flush=1; right="${rz%=}"; }

  # Per-line prepend/append: arbitrary content (text, emoji, #{...}, #[styles])
  # pinned to the very left/right of the row. A prepend pushes the left edge off
  # the terminal border, so it cancels this line's left flush; an append cancels
  # the right flush.
  prepend=$(tmux show -gqv "@themux_status_line_${i}_prepend")
  append=$(tmux show -gqv "@themux_status_line_${i}_append")

  # One "=" flushes whatever sits at that edge: a leading/trailing "windows" token
  # flags the ribbon (@_tmx_win_flush_left/right, read by window_render.sh to drop
  # its opening/closing cap); a module group drops its outer cap via the edge arg
  # to expand_zone below. A prepend/append cancels the flush on its edge (the
  # block is no longer against the terminal border).
  read -r _lfirst _ <<<"$left"
  _rlast=""; for _t in $right; do _rlast="$_t"; done
  [ "$l_flush" = 1 ] && [ "$_lfirst" = windows ] && [ -z "$prepend" ] && win_fl=1
  [ "$r_flush" = 1 ] && [ "$_rlast" = windows ]  && [ -z "$append" ]  && win_fr=1

  # "nolist" leaves the window-list region the "windows" token turns on, so a
  # zone after it still pins to its own edge (otherwise the right zone stays
  # glued to the window list instead of the right edge).
  l_edge=none; [ "$l_flush" = 1 ] && [ -z "$prepend" ] && l_edge=left
  r_edge=none; [ "$r_flush" = 1 ] && [ -z "$append" ] && r_edge=right
  fmt="#[nolist align=left]${prepend}$(expand_zone "$left" left "$l_edge")"
  fmt+="#[nolist align=centre]$(expand_zone "$center" centre none)"
  fmt+="#[nolist align=right]$(expand_zone "$right" right "$r_edge")${append}"

  tmux set -g "status-format[$((i - 1))]" "$fmt"
done

tmux set -g @_tmx_win_flush_left "$win_fl"
tmux set -g @_tmx_win_flush_right "$win_fr"

tmux set -gu @_tmx_layout_tmp
# `status` takes off / on (1 row) / 2..5; a literal "1" is rejected.
case "$last" in
  0) tmux set -g status off ;;
  1) tmux set -g status on ;;
  *) tmux set -g status "$last" ;;
esac
exit 0
