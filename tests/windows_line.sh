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

# Squared also has caps (█), so "=" must still use the connected core path and
# edge flush must drop the outer square cap. This is not visually decorative: it
# is how a squared block reaches the terminal edge without an extra border cell.
block=$(printf '\342\226\210')
tmux set -g @themux_module_shape "squared"
tmux set -g @themux_status_line_1 "session=host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nsq_eq_uses_core "
tmux show -gv 'status-format[0]' | grep -c '@_tmx_module_session_core' || true
printf "sq_eq_blocks "; glyphs "$block"       # head + tail -> 2

tmux set -g @themux_status_line_1 "=session=host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nsq_flush_left_blocks "; glyphs "$block" # head dropped -> tail only

tmux set -g @themux_module_shape "rounded"

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

# Edge flush (nvim-style) is part of the line grammar: a leading "=" on the left
# zone drops that group's head cap (one fewer mpll); a trailing "=" on the right
# zone drops its tail cap (one fewer mprr). The edge block then fills flat to the
# terminal border.
tmux set -g @themux_status_line_1 "=session>host"   # left zone, leading "="
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nflush_left_mpll "; glyphs "$mpll"   # head dropped -> 0
printf "flush_left_mprr "; glyphs "$mprr"     # seam + tail kept -> 2

tmux set -g @themux_status_line_1 " / session>host="   # right zone, trailing "="
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nflush_right_mpll "; glyphs "$mpll"   # head kept -> 1
printf "flush_right_mprr "; glyphs "$mprr"     # tail dropped -> 1

# "=" at both ends drops the left zone's head cap AND the right zone's tail cap.
# For "=session>host / / cpu<ram=": off gives 3 mpll / 3 mprr; the markers drop
# the left head (mpll) and the right tail (mprr) -> 2 / 2.
tmux set -g @themux_status_line_1 "=session>host / / cpu<ram="
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nflush_both_mpll "; glyphs "$mpll"   # 2 (left head dropped)
printf "flush_both_mprr "; glyphs "$mprr"     # 2 (right tail dropped)

# No markers (default): both outer caps kept.
tmux set -g @themux_status_line_1 "session>host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nflush_off_mpll "; glyphs "$mpll"     # 1
printf "flush_off_mprr "; glyphs "$mprr"       # 2

# Window-list flush: the same "=" selects a per-occurrence window format when a
# "windows" token sits at that edge; no global flush flag should leak to another
# row/position.
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_seam "<>"
tmux set -g @themux_status_line_1 "=windows / / host"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nwin_flush_left_edge "; tmux show -gv 'status-format[0]' | grep -c '@_tmx_wfmt_left' || true

# "windows" not first -> no window edge variant; the leading module group owns
# the flush instead.
tmux set -g @themux_status_line_1 "=host windows / / "
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "win_flush_left_inner "; tmux show -gv 'status-format[0]' | grep -c '@_tmx_wfmt_none' || true

# Right edge: "windows" as the last token of a "="-flushed right zone.
tmux set -g @themux_status_line_1 "host / / windows="
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "win_flush_right_edge "; tmux show -gv 'status-format[0]' | grep -c '@_tmx_wfmt_right' || true

# Per-line prepend/append: a prepend cancels that row's left "=" flush, an append
# the right "=" flush (the edge block is no longer against the border), so both
# the head and tail caps return.
tmux set -gu @themux_window_shape
tmux set -gu @themux_window_seam
tmux set -g @themux_module_shape "rounded"
tmux set -g @themux_status_line_1_prepend "PRE "
tmux set -g @themux_status_line_1_append " END"
tmux set -g @themux_status_line_1 "=session>host / / cpu<ram="
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"
run_layout
printf "\nprepend_pinned "; tmux show -gv 'status-format[0]' | grep -c 'align=left\]PRE ' || true
printf "append_pinned "; tmux show -gv 'status-format[0]' | grep -c ' END' || true
printf "prepend_cancels_left_flush_mpll "; glyphs "$mpll"   # left head back -> 3
printf "append_cancels_right_flush_mprr "; glyphs "$mprr"   # right tail back -> 3
