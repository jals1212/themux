#!/usr/bin/env bash
# Build `status` and status-format[*] from @themux_status_line_1..5.
#
# Each line is split into zones by "/": none -> one left column, one ->
# left + right, two -> left / center / right. A zone is a module list (token
# NAMEs; "|" inserts the divider, a space leaves each item its own pill/list, and
# =/>/< merge adjacent modules or the special token "windows" into one strip.
# Rows render up to the last non-empty line, so a blank ("") line in between
# becomes an empty row (status off when every line is empty).

# A module marked @themux_<name>_expand=yes carries a tmux plugin's #{var} literals
# (#{cpu_percentage}, #{battery_percentage}, ...) that the plugin only resolves into
# status-left/right. @themux_<name>_plugin names the plugin's tmux file (under
# TMUX_PLUGIN_MANAGER_PATH); its do_interpolation rewrites those literals into the
# #(script) form, so the module works in ANY zone of the grammar — not just the bar
# edges. Every such plugin names the function `do_interpolation`, so they would
# clobber one another: source each ONCE and snapshot its function under a per-plugin
# name (the `declare -F` guard caches it). A missing plugin — or one without the
# function — snapshots to identity, leaving the literals untouched (no regression).
interp() { # $1 module, $2 string -> the string with the module's plugin literals resolved
  local p fn
  p=$(tmux show -gqv "@themux_${1}_plugin")
  [ -z "$p" ] && { printf '%s' "$2"; return; }
  fn="_di_${p//[^a-zA-Z0-9]/_}"
  # Snapshot the plugin's do_interpolation under a per-plugin name on first use (the
  # declare -F guard caches it within this shell). Inlined here — not split into a
  # helper — so the eval'd function lives in the same scope that then calls it.
  if ! declare -F "$fn" >/dev/null 2>&1; then
    unset -f do_interpolation 2>/dev/null || true
    # shellcheck disable=SC1090
    [ -r "${TMUX_PLUGIN_MANAGER_PATH}/${p}" ] && source "${TMUX_PLUGIN_MANAGER_PATH}/${p}" >/dev/null 2>&1
    if declare -F do_interpolation >/dev/null 2>&1; then
      eval "${fn}() $(declare -f do_interpolation | sed '1d')"
    else
      eval "${fn}() { printf '%s' \"\$1\"; }"
    fi
  fi
  "$fn" "$2"
}

windows_block=$(tmux show -gqv @_tmx_fmt_windows)

# Cap glyphs for the module shape. Empty only for unstyled; squared uses a full
# block cap, so `=` and edge flush still work for square-cornered modules.
mshape=$(tmux display -p "#{?#{@themux_module_shape},#{@themux_module_shape},#{@themux_all_shape}}")
case "$mshape" in
  rounded)   mpll=$(printf '\356\202\266'); mprr=$(printf '\356\202\264') ;;
  slanted)   mpll=$(printf '\356\202\272'); mprr=$(printf '\356\202\274') ;;
  powerline) mpll=$(printf '\356\202\262'); mprr=$(printf '\356\202\260') ;;
  unstyled)  mpll=""; mprr="" ;;
  *)         mpll=$(printf '\342\226\210'); mprr=$(printf '\342\226\210') ;; # squared/unknown
esac

# The divider "|" inserts between modules; emptying it ("") just drops the
# segment (modules stay separate pills — merging is done with =/>/< instead).
mdiv=$(tmux show -gqv @themux_module_divider)

# Edge flush (nvim-style) is part of the status-line grammar: a leading "=" on the
# left zone, or a trailing "=" on the right zone, drops that edge's outer cap so
# the block fills flat to the terminal border. It mirrors the "=" connector (a
# flat, capless seam) carried out to the bar's edge. One marker flushes whatever
# sits there — a module group OR the window list — and it is per line; the
# centre zone never touches an edge. Parsed in the per-line loop below.

# An _expand module (cpu/ram, battery, ...) carries its plugin's #{var} literals;
# interp (above) rewrites them to #(...) form via that plugin's do_interpolation.
# These helpers apply it for such modules and pass everything else through unchanged.
mod_field() { # $1 module, $2 edge option (lcol|rcol|lbg) -> a usable colour
  if [ "$(tmux show -gqv "@themux_${1}_expand")" = "yes" ]; then
    tmux set -gF @_tmx_layout_tmp "#{E:@_tmx_module_${1}_${2}}"
    interp "$1" "$(tmux show -gv @_tmx_layout_tmp)"
  else
    tmux show -gqv "@_tmx_module_${1}_${2}"
  fi
}
mod_core() { # $1 module -> its bare core (a ref normally; inlined for tmux-cpu)
  if [ "$(tmux show -gqv "@themux_${1}_expand")" = "yes" ]; then
    tmux set -gF @_tmx_layout_tmp "#{E:@_tmx_module_${1}_core}"
    interp "$1" "$(tmux show -gv @_tmx_layout_tmp)"
  else
    printf '%s' "#{E:@_tmx_module_${1}_core}"
  fi
}
full_pill() { # $1 module -> its own pill, caps included (inlined for tmux-cpu)
  if [ "$(tmux show -gqv "@themux_${1}_expand")" = "yes" ]; then
    tmux set -gF @_tmx_layout_tmp "#{E:@themux_module_${1}}"
    interp "$1" "$(tmux show -gv @_tmx_layout_tmp)"
  else
    printf '%s' "#{E:@themux_module_${1}}"
  fi
}

win_field() { # $1 edge option (lcol|rcol|lbg|rbg) -> a usable window-list colour
  tmux show -gqv "@_tmx_windows_${1}"
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
# Items connect only through explicit tokens in the layout string: = (flat
# merge, squared seam), > (left penetrates right) and < (right penetrates left)
# join adjacent modules and/or the window list into one strip; a plain space
# leaves each item its own full pill/list; "|" separates and draws the divider.
# unstyled has no caps, so connectors are inert there — every module is its own
# pill.
#
# Tokens are first collected into items (G=group, D=divider, W=windows) so the
# first/last *group* is known: that is the one whose outer cap flushes to the
# terminal edge when $3 asks for it; a leading/trailing divider or window list
# owns the edge instead, so no module flushes there.
expand_zone() {
  local zone align edge token pending i out fl fr fg lg last can_join grp_in
  local left_join right_join next cur_lcol cur_lbg prev_rcol prev_rbg seam idx
  local local_vis next_vis drop_right keep_right
  local -a it_type it_mods it_conns it_in grp_mods grp_conns
  align="$2"; edge="$3"
  pending="" can_join=0 grp_in=""

  push_group() {
    [ ${#grp_mods[@]} -eq 0 ] && return
    it_type+=("G"); it_mods+=("${grp_mods[*]}"); it_conns+=("${grp_conns[*]}"); it_in+=("$grp_in")
    grp_mods=(); grp_conns=(); grp_in=""; can_join=1
  }
  item_lcol() { local -a mm; read -ra mm <<<"${it_mods[$1]}"; case "${it_type[$1]}" in G) mod_field "${mm[0]}" lcol ;; W) win_field lcol ;; esac; }
  item_lbg() { local -a mm; read -ra mm <<<"${it_mods[$1]}"; case "${it_type[$1]}" in G) mod_field "${mm[0]}" lbg ;; W) win_field lbg ;; esac; }
  item_rcol() { local -a mm; read -ra mm <<<"${it_mods[$1]}"; case "${it_type[$1]}" in G) idx=$(( ${#mm[@]} - 1 )); mod_field "${mm[$idx]}" rcol ;; W) win_field rcol ;; esac; }
  item_rbg() { local -a mm; read -ra mm <<<"${it_mods[$1]}"; case "${it_type[$1]}" in G) idx=$(( ${#mm[@]} - 1 )); mod_field "${mm[$idx]}" rbg ;; W) win_field rbg ;; esac; }
  item_seam() { # $1 connector, $2 prev rcol, $3 prev rbg, $4 current lcol, $5 current lbg
    case "$1" in
      lt) printf '#[fg=%s,bg=%s]%s' "$4" "$3" "$mpll" ;; # < penetrate left
      eq) printf '' ;;                                      # = flat squared seam
      *)  printf '#[fg=%s,bg=%s]%s' "$2" "$5" "$mprr" ;; # > penetrate right
    esac
  }
  item_visible() { # $1 item index -> 1 or a tmux condition for conditional groups
    local -a mm
    local m cond vis=""
    case "${it_type[$1]}" in
      W) printf '1' ;;
      G)
        read -ra mm <<<"${it_mods[$1]}"
        for m in "${mm[@]}"; do
          cond=$(tmux show -gqv "@themux_${m}_when")
          [ -z "$cond" ] && { printf '1'; return; }
          if [ -z "$vis" ]; then vis="$cond"; else vis="#{||:${vis},${cond}}"; fi
        done
        printf '%s' "${vis:-1}"
        ;;
      *) printf '1' ;;
    esac
  }
  render_item() { # $1 item index, $2 flush-left, $3 flush-right
    local idx="$1" fl2="$2" fr2="$3" wedge2 wfmt2
    local -a mm2
    case "${it_type[idx]}" in
      W)
        case "$fl2:$fr2" in
          1:1) wedge2=both ;;
          1:0) wedge2=left ;;
          0:1) wedge2=right ;;
          *)   wedge2=none ;;
        esac
        wfmt2="${windows_block//%ALIGN%/$align}"
        printf '%s' "${wfmt2//%WEDGE%/$wedge2}"
        ;;
      D) [ -n "$mdiv" ] && printf '%s' "#{E:@_tmx_module_divider}" ;;
      G)
        read -ra mm2 <<<"${it_mods[idx]}"
        if [ ${#mm2[@]} -eq 1 ] && [ "$fl2" = 0 ] && [ "$fr2" = 0 ]; then
          full_pill "${mm2[0]}"
        else
          powerline_run "${it_mods[idx]}" "${it_conns[idx]}" "$fl2" "$fr2"
        fi
        ;;
    esac
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
      windows)
        push_group
        it_type+=("W"); it_mods+=(""); it_conns+=(""); it_in+=("$pending")
        pending=""; can_join=1
        ;;
      __div__)
        push_group
        it_type+=("D"); it_mods+=(""); it_conns+=(""); it_in+=("")
        pending=""; can_join=0
        ;;
      __gt__|__lt__|__eq__)
        # Joins the next item to the open group/list; nothing on its left = no-op.
        { [ ${#grp_mods[@]} -ge 1 ] || [ "$can_join" = 1 ]; } && pending="${token//_/}"
        ;;
      *)
        # unstyled has no caps, so connectors are inert: each module is its
        # own one-module group. Otherwise a pending connector extends the
        # open group; a plain space starts a fresh one (its "head").
        if [ -z "$mpll" ]; then
          push_group; it_type+=("G"); it_mods+=("$token"); it_conns+=("head"); it_in+=(""); pending=""; can_join=1
        elif [ -n "$pending" ]; then
          if [ ${#grp_mods[@]} -ge 1 ]; then
            grp_mods+=("$token"); grp_conns+=("$pending")
          else
            grp_mods+=("$token"); grp_conns+=("head"); grp_in="$pending"
          fi
          pending=""; can_join=1
        else
          push_group; grp_mods+=("$token"); grp_conns+=("head"); grp_in=""; can_join=1
        fi
        ;;
    esac
  done
  push_group

  # Flushable groups are the literal first/last item, and only if a group.
  fg=-1; lg=-1; last=$(( ${#it_type[@]} - 1 ))
  [ "$last" -ge 0 ] && [ "${it_type[0]}" = G ] && fg=0
  [ "$last" -ge 0 ] && [ "${it_type[last]}" = G ] && lg=$last

  out=""; prev_rcol=""; prev_rbg=""
  for i in "${!it_type[@]}"; do
    local_vis=$(item_visible "$i")
    next_vis="1"
    left_join=0; right_join=0
    [ -n "${it_in[i]}" ] && left_join=1
    next=$((i + 1))
    if [ "$next" -le "$last" ] && [ -n "${it_in[next]}" ]; then
      right_join=1
      next_vis=$(item_visible "$next")
    fi

    if [ "$left_join" = 1 ]; then
      cur_lcol=$(item_lcol "$i"); cur_lbg=$(item_lbg "$i")
      seam=$(item_seam "${it_in[i]}" "$prev_rcol" "$prev_rbg" "$cur_lcol" "$cur_lbg")
      if [ "$local_vis" = 1 ]; then
        out+="$seam"
      else
        tmux set -g "@_tmx_item_seam_${i}" "$seam"
        out+="#{?${local_vis},#{E:@_tmx_item_seam_${i}},}"
      fi
    fi

    fl=0; fr=0
    [ "${it_type[i]}" = G ] && [ -n "$mpll" ] && [ "$edge" = left ]  && [ "$i" = "$fg" ] && fl=1
    [ "${it_type[i]}" = G ] && [ -n "$mpll" ] && [ "$edge" = right ] && [ "$i" = "$lg" ] && fr=1
    [ "${it_type[i]}" = W ] && [ "$edge" = left ]  && [ "$i" = 0 ]       && fl=1
    [ "${it_type[i]}" = W ] && [ "$edge" = right ] && [ "$i" = "$last" ] && fr=1
    [ "$left_join" = 1 ] && fl=1
    [ "$right_join" = 1 ] && fr=1

    if [ "$right_join" = 1 ] && [ "$next_vis" != 1 ]; then
      drop_right=$(render_item "$i" "$fl" 1)
      keep_right=$(render_item "$i" "$fl" 0)
      tmux set -g "@_tmx_item_drop_${i}" "$drop_right"
      tmux set -g "@_tmx_item_keep_${i}" "$keep_right"
      out+="#{?${next_vis},#{E:@_tmx_item_drop_${i}},#{E:@_tmx_item_keep_${i}}}"
    else
      out+="$(render_item "$i" "$fl" "$fr")"
    fi

    case "${it_type[i]}" in
      G|W) prev_rcol=$(item_rcol "$i"); prev_rbg=$(item_rbg "$i") ;;
      *) prev_rcol=""; prev_rbg="" ;;
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

  # Edge flush marker: a leading "=" on the left zone flushes the left border, a
  # trailing "=" on the right zone the right border. Strip it before the zone is
  # parsed (an inline "=" between two adjacent items stays a flat-merge connector). A
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

  # One "=" flushes whatever sits at that edge. expand_zone applies that edge
  # locally: a module group drops its outer cap; a "windows" token selects the
  # matching per-occurrence window-list variant (%WEDGE%). A prepend/append
  # cancels the flush on its edge because the item no longer touches the border.
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

tmux set -gu @_tmx_layout_tmp
# `status` takes off / on (1 row) / 2..5; a literal "1" is rejected.
case "$last" in
  0) tmux set -g status off ;;
  1) tmux set -g status on ;;
  *) tmux set -g status "$last" ;;
esac
exit 0
