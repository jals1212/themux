#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# run-shell is synchronous, so status-format is built before we read it.
run_layout() { tmux run-shell "${script_dir}/../utils/layout.sh"; }

# One line: left modules (with a "|" divider), windows centred, right module.
tmux set -g @themux_status_line_1 "session|application / windows / host"
tmux set -g @themux_status_line_2 ""
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout

printf "\none_status "
tmux show -gv status
printf "one_zones "
tmux show -gv 'status-format[0]' | grep -oE '#\[nolist align=(left|centre|right)\]' | tr '\n' ' '
printf "\none_left_divider "
tmux show -gv 'status-format[0]' | grep -c '@themux_module_session}#{E:@_tmx_module_divider}#{E:@themux_module_application' || true
printf "one_windows_centre "
tmux show -gv 'status-format[0]' | grep -c 'list=on align=centre' || true
printf "one_right_module "
tmux show -gv 'status-format[0]' | grep -c 'nolist align=right]#{E:@themux_module_host}' || true

# Two lines: windows alone on the second row, right-aligned.
tmux set -g @themux_status_line_1 "session / / host"
tmux set -g @themux_status_line_2 " / / windows"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\ntwo_status "
tmux show -gv status
printf "two_line2_windows_right "
tmux show -gv 'status-format[1]' | grep -c 'list=on align=right' || true

# Back to a single row when the extra lines are blank.
tmux set -g @themux_status_line_2 ""
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nsingle_status "
tmux show -gv status

# "=" merges two modules into one capped group built from their bare cores — a
# flat (squared) seam, no divider between them even with a non-empty divider set.
tmux set -g @themux_status_line_1 "session=application"
tmux set -g @themux_module_shape "rounded"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nmerge_uses_core "
tmux show -gv 'status-format[0]' | grep -c '@_tmx_module_session_core' || true
printf "merge_no_divider "
tmux show -gv 'status-format[0]' | grep -c '@_tmx_module_divider' || true

# Lazy render: a module never referenced in any status line is not rendered.
printf "unused_not_rendered "
tmux show -gqv @themux_module_weather | grep -c . || true

# Per-seam connectors (rounded): ">" draws a right-cap seam (mprr), "<" a left-cap
# seam (mpll), "=" no seam glyph (flat). Outer caps are always the shape's caps.
# Counting inline glyphs over status-format[0] counts caps+seams only — module
# cores are references, so their glyphs are not inlined.
mpll=$(printf '\356\202\266')   # rounded left cap  (E0B6)
mprr=$(printf '\356\202\264')   # rounded right cap (E0B4)
# `|| true` so a zero count (grep exit 1) does not trip the harness ERR trap.
glyphs() { tmux show -gv 'status-format[0]' | { grep -o "$1" || true; } | wc -l | tr -d ' '; }
tmux set -g @themux_module_shape "rounded"

# ">" : head (mpll) + right-penetrate seam (mprr) + tail (mprr) = 1 mpll, 2 mprr
tmux set -g @themux_status_line_1 "session>host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\ngt_mpll "; glyphs "$mpll"
printf "gt_mprr "; glyphs "$mprr"

# "<" : head (mpll) + left-penetrate seam (mpll) + tail (mprr) = 2 mpll, 1 mprr
tmux set -g @themux_status_line_1 "session<host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nlt_mpll "; glyphs "$mpll"
printf "lt_mprr "; glyphs "$mprr"

# "=" : head (mpll) + flat seam (none) + tail (mprr) = 1 mpll, 1 mprr
tmux set -g @themux_status_line_1 "session=host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\neq_mpll "; glyphs "$mpll"
printf "eq_mprr "; glyphs "$mprr"

# A plain space breaks the group: each module is its own full pill (a reference),
# so no run core is emitted.
tmux set -g @themux_status_line_1 "session host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nspace_session_pill "
tmux show -gv 'status-format[0]' | grep -c 'E:@themux_module_session}' || true
printf "space_no_run_core "
tmux show -gv 'status-format[0]' | grep -c '@_tmx_module_session_core' || true

# Flush edges (nvim-style): the edge group's outer cap is dropped so its block
# fills to the terminal border. "left" drops the left zone's first head cap
# (one fewer mpll); "right" drops the right zone's last tail cap (one fewer mprr).
tmux set -g @themux_status_flush_edges "left"
tmux set -g @themux_status_line_1 "session>host"   # left zone
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nflush_left_mpll "; glyphs "$mpll"   # head dropped -> 0
printf "flush_left_mprr "; glyphs "$mprr"     # seam + tail kept -> 2

tmux set -g @themux_status_flush_edges "right"
tmux set -g @themux_status_line_1 " / session>host"   # right zone
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nflush_right_mpll "; glyphs "$mpll"   # head kept -> 1
printf "flush_right_mprr "; glyphs "$mprr"     # tail dropped -> 1

# "both" drops the left zone's first head cap AND the right zone's last tail cap
# in one config. For "session>host / / cpu<ram": off gives 3 mpll / 3 mprr; both
# drops the left head (mpll) and the right tail (mprr) -> 2 / 2.
tmux set -g @themux_status_flush_edges "both"
tmux set -g @themux_status_line_1 "session>host / / cpu<ram"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nflush_both_mpll "; glyphs "$mpll"   # 2 (left head dropped)
printf "flush_both_mprr "; glyphs "$mprr"     # 2 (right tail dropped)

# "off" (default) keeps both outer caps.
tmux set -g @themux_status_flush_edges "off"
tmux set -g @themux_status_line_1 "session>host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nflush_off_mpll "; glyphs "$mpll"     # 1
printf "flush_off_mprr "; glyphs "$mprr"       # 2

# Window ribbon flush: layout flags the window list (@_tmx_win_flush_left/right)
# only when "windows" is the first token of a flushing left zone or the last of a
# flushing right zone; window_render then drops that edge's ribbon cap.
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_seam "<>"
tmux set -g @themux_window_flush_edges "left"
tmux set -g @themux_status_line_1 "windows / / host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nwin_flush_left_edge "; tmux show -gqv @_tmx_win_flush_left    # 1

# "windows" not first -> not flagged (window flush only targets a leading windows).
tmux set -g @themux_status_line_1 "host windows / / "
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "win_flush_left_inner "; tmux show -gqv @_tmx_win_flush_left    # 0

# Right edge: "windows" as the last token of a flushing right zone.
tmux set -g @themux_window_flush_edges "right"
tmux set -g @themux_status_line_1 "host / / windows"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "win_flush_right_edge "; tmux show -gqv @_tmx_win_flush_right    # 1
