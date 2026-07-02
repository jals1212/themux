#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# Directional + zone-aware auto notch (@themux_*_notch: off | > | < | auto | on
# alias). Conventions mirror tests/module_variant.sh and tests/windows_line.sh:
# pre-layout assertions read the raw or expanded module core (core/core_e, the
# #{E:} idiom); zone-resolution assertions run utils/layout.sh and grep the RAW
# status-format[N] text, since an auto-resolved seam is spliced in literally
# there (a full module pill stays a hidden #{E:@themux_module_<name>} reference
# otherwise, so its own outer caps never leak into that raw text). `|| true`
# guards every possibly-zero-match grep — the harness ERR-trap kills the tmux
# server on a bare non-match.
core() { tmux show -gqv "@_tmx_module_$1_core"; }
core_e() { tmux display -p "#{E:@_tmx_module_$1_core}"; }
run_layout() { tmux run-shell "${script_dir}/../utils/layout.sh"; }
src() {
  tmux source "${script_dir}/../themux_options.conf"
  tmux source "${script_dir}/../themux.conf"
}
count() { # $1 haystack, $2 needle -> occurrence count (0-match safe)
  printf '%s' "$1" | { grep -o "$2" || true; } | wc -l | tr -d ' '
}

mpll=$(printf '\356\202\266')  # rounded LEFT cap  (E0B6) — the lt seam glyph
mprr=$(printf '\356\202\264')  # rounded RIGHT cap (E0B4) — the gt seam glyph
block=$(printf '\342\226\210') # squared block (U+2588) — both directions there

# 1-2. Explicit ">"/"<" are NOT zone-dependent: they bake directly at module_
# render.sh time, so layout's per-zone splice never runs (its raw seam_gt/
# seam_lt fetch comes back empty — the micro-opt skips the #{s///} wrap
# entirely). Placing the module in the OPPOSITE zone from its natural auto
# resolution and confirming the explicit direction still wins is the point.
# A rounded module's outer caps always draw one mpll + one mprr regardless of
# notch, so the seam's own contribution is counted (2 = outer + seam, not
# just present).
tmux set -g @themux_module_shape "rounded"
tmux set -g @themux_status_line_1 " / / host"
tmux set -g @themux_host_notch ">"
src
run_layout
resolved=$(tmux display -p "#{E:@themux_module_host}")
printf "\nexplicit_gt_right_zone_extra_mprr "
{ [ "$(count "$resolved" "$mprr")" -eq 2 ]; } && printf "Y" || printf "n"
printf "\nexplicit_gt_right_zone_no_extra_mpll "
{ [ "$(count "$resolved" "$mpll")" -eq 1 ]; } && printf "Y" || printf "n"

tmux set -g @themux_status_line_1 "host / / "
tmux set -g @themux_host_notch "<"
src
run_layout
resolved=$(tmux display -p "#{E:@themux_module_host}")
printf "\nexplicit_lt_left_zone_extra_mpll "
{ [ "$(count "$resolved" "$mpll")" -eq 2 ]; } && printf "Y" || printf "n"
printf "\nexplicit_lt_left_zone_no_extra_mprr "
{ [ "$(count "$resolved" "$mprr")" -eq 1 ]; } && printf "Y" || printf "n"
tmux set -gu @themux_host_notch

# 3-5. auto: left zone -> gt, right zone -> lt, centre zone -> off (falls back
# to the module middle separator, default empty AND a custom value). A single
# module alone in its zone renders through the full_pill fast path (a hidden
# @themux_module_<name> reference), so the raw status-format text is clean:
# only a spliced seam's own bytes are ever inlined there.
tmux set -g @themux_all_notch "auto"
tmux set -g @themux_status_line_1 "host / / "
src
run_layout
printf "\nauto_left_zone_gt "
{ tmux show -gv 'status-format[0]' | grep -qF "$mprr"; } && printf "Y" || printf "n"

tmux set -g @themux_status_line_1 " / / host"
src
run_layout
printf "\nauto_right_zone_lt "
{ tmux show -gv 'status-format[0]' | grep -qF "$mpll"; } && printf "Y" || printf "n"

tmux set -g @themux_status_line_1 " / host / "
src
run_layout
printf "\nauto_centre_zone_no_gt "
{ tmux show -gv 'status-format[0]' | grep -qF "$mprr"; } && printf "n" || printf "Y"
printf "\nauto_centre_zone_no_lt "
{ tmux show -gv 'status-format[0]' | grep -qF "$mpll"; } && printf "n" || printf "Y"
# FIX 2 regression: the marker IS baked into the core in auto mode regardless of
# the centre replacement text, and the default middle separator is itself empty
# — splicing must be decided by marker PRESENCE (mod_has_marker), not by
# whether the replacement text is empty, or the marker leaks into the rendered
# line. For host (a plain ref module), that splice is tmux's own draw-time
# #{s/<mark>//:...}, so the RAW stored status-format[0] legitimately still
# carries the marker byte as the substitution's pattern argument — that is the
# mechanism working as designed, not a leak. What must never happen is the
# marker surviving into the EXPANDED (drawn) text, so these two check
# #{E:status-format[0]} instead of the raw option.
printf "\nauto_centre_zone_default_empty_midsep_no_raw_marker "
{ tmux display -p "#{E:status-format[0]}" | grep -qF "$(printf '\036')"; } && printf "n" || printf "Y"

tmux set -g @themux_module_middle_separator "MIDSEP"
src
run_layout
printf "\nauto_centre_zone_uses_custom_midsep "
{ tmux show -gv 'status-format[0]' | grep -qF "MIDSEP"; } && printf "Y" || printf "n"
printf "\nauto_centre_zone_custom_midsep_no_raw_marker "
{ tmux display -p "#{E:status-format[0]}" | grep -qF "$(printf '\036')"; } && printf "n" || printf "Y"
tmux set -gu @themux_module_middle_separator

# 6. "on" is a plain alias of "auto": same three zone outcomes.
tmux set -g @themux_all_notch "on"
tmux set -g @themux_status_line_1 "host / / "
src
run_layout
printf "\non_alias_left_zone_gt "
{ tmux show -gv 'status-format[0]' | grep -qF "$mprr"; } && printf "Y" || printf "n"

tmux set -g @themux_status_line_1 " / / host"
src
run_layout
printf "\non_alias_right_zone_lt "
{ tmux show -gv 'status-format[0]' | grep -qF "$mpll"; } && printf "Y" || printf "n"

tmux set -g @themux_status_line_1 " / host / "
src
run_layout
printf "\non_alias_centre_zone_off "
{ tmux show -gv 'status-format[0]' | grep -qF "$mprr"; } && printf "n" || printf "Y"

# 7. Cascade override: @themux_all_notch auto + @themux_cpu_notch "<" fixes cpu
# to lt regardless of zone (checked pre-layout, like the explicit tests above —
# cpu is an _expand module, so mod_core/full_pill inline its whole core rather
# than referencing it, but the same "explicit ignores zone" rule still governs
# what module_render.sh baked). Its sibling (host, plain, same zone) still
# resolves through the zone (left -> gt). core_e reads the BARE core (no outer
# caps at all, unlike tests 1-2's full pill), so a plain presence check is
# clean here — nothing else in it can produce a false mpll/mprr match.
tmux set -g @themux_status_line_1 "cpu host"
tmux set -g @themux_all_notch "auto"
tmux set -g @themux_cpu_notch "<"
src
run_layout
cpu_core=$(core_e cpu)
printf "\ncascade_override_cpu_fixed_lt "
{ printf '%s' "$cpu_core" | grep -qF "$mpll"; } && printf "Y" || printf "n"
printf "\ncascade_override_cpu_no_gt_seam "
{ printf '%s' "$cpu_core" | grep -qF "$mprr"; } && printf "n" || printf "Y"
printf "\ncascade_override_sibling_zone_resolved_gt "
{ tmux show -gv 'status-format[0]' | grep -qF "$mprr"; } && printf "Y" || printf "n"
tmux set -gu @themux_cpu_notch

# 8. Multi-placement: the SAME module referenced in both the left and right
# zone of one row resolves independently per occurrence — one snippet gets gt,
# the other lt, in the same status-format[0] string.
tmux set -g @themux_status_line_1 "host / / host"
src
run_layout
fmt0=$(tmux show -gv 'status-format[0]')
printf "\nmulti_placement_one_gt "
{ [ "$(count "$fmt0" "$mprr")" -eq 1 ]; } && printf "Y" || printf "n"
printf "\nmulti_placement_one_lt "
{ [ "$(count "$fmt0" "$mpll")" -eq 1 ]; } && printf "Y" || printf "n"

# 9. Panes: no bar zone, so auto follows leading_position instead (left -> gt,
# right -> lt). Also regression-tests the newly added position=right seam path
# (there was none before this feature).
tmux set -g @themux_pane_shape "rounded"
tmux set -g @themux_pane_leading_variant "solid"
tmux set -g @themux_pane_text_variant "soft"
tmux set -g @themux_pane_notch "auto"
tmux set -g @themux_pane_status "top"
tmux set -g @themux_pane_leading_position "left"
src
printf "\npane_auto_left_position_gt "
{ tmux show -gv pane-border-format | grep -qF "$mprr"; } && printf "Y" || printf "n"
tmux set -g @themux_pane_leading_position "right"
src
printf "\npane_auto_right_position_lt "
{ tmux show -gv pane-border-format | grep -qF "$mpll"; } && printf "Y" || printf "n"
tmux set -gu @themux_pane_leading_position
tmux set -gu @themux_pane_notch
tmux set -gu @themux_pane_leading_variant
tmux set -gu @themux_pane_text_variant
tmux set -gu @themux_pane_status

# 10. Windows: layout sets the hidden @_tmx_window_notch_dir global per
# occurrence (left -> gt, right -> lt, centre -> off); window-status-format
# carries the draw-time #{?#{==:...}} dispatch that reads it (ONE shared tmux
# option, unlike a module's per-occurrence splice).
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_notch "auto"
tmux set -g @themux_status_line_1 "windows"
src
run_layout
printf "\nwindow_dispatch_present "
{ tmux show -gv window-status-format | grep -qF '@_tmx_window_notch_dir'; } && printf "Y" || printf "n"
printf "\nwindow_notch_dir_left_zone "
tmux show -gqv @_tmx_window_notch_dir

tmux set -g @themux_status_line_1 " / / windows"
src
run_layout
printf "window_notch_dir_right_zone "
tmux show -gqv @_tmx_window_notch_dir

tmux set -g @themux_status_line_1 " / windows / "
src
run_layout
printf "window_notch_dir_centre_zone "
tmux show -gqv @_tmx_window_notch_dir
tmux set -gu @themux_window_notch
tmux set -gu @themux_window_shape

# 11. An invalid value degrades to off, same convention as state_target.
tmux set -g @themux_status_line_1 "host"
tmux set -g @themux_module_shape "rounded"
tmux set -g @themux_host_notch "off"
src
off_core=$(core_e host)
tmux set -g @themux_host_notch "nonsense"
src
invalid_core=$(core_e host)
printf "\ninvalid_notch_falls_back_to_off "
{ [ "$off_core" = "$invalid_core" ]; } && printf "Y" || printf "n"

# 12. Squared shape: gt and lt draw the SAME glyph (U+2588, direction-agnostic)
# but with swapped colours. Squared's outer caps ALSO draw a block glyph (unlike
# windows/panes, a module's cap() only skips squared on a naked/default bg), so
# presence alone proves nothing — compare against the off baseline (one more
# block = the seam), and that the two directions add the identical glyph COUNT
# while their full cores still differ (the colours).
tmux set -g @themux_module_shape "squared"
tmux set -g @themux_host_notch "off"
src
squared_off=$(core_e host)
tmux set -g @themux_host_notch ">"
src
squared_gt=$(core_e host)
tmux set -g @themux_host_notch "<"
src
squared_lt=$(core_e host)
printf "\nsquared_gt_adds_block "
{ [ "$(count "$squared_gt" "$block")" -gt "$(count "$squared_off" "$block")" ]; } && printf "Y" || printf "n"
printf "\nsquared_lt_adds_block "
{ [ "$(count "$squared_lt" "$block")" -gt "$(count "$squared_off" "$block")" ]; } && printf "Y" || printf "n"
printf "\nsquared_gt_lt_same_glyph_count "
{ [ "$(count "$squared_gt" "$block")" -eq "$(count "$squared_lt" "$block")" ]; } && printf "Y" || printf "n"
printf "\nsquared_gt_lt_different_colours "
{ [ "$squared_gt" != "$squared_lt" ]; } && printf "Y" || printf "n"
tmux set -gu @themux_host_notch
tmux set -g @themux_module_shape "rounded"

# 13. Active-state seam: session carries active_when (client_prefix), so its
# resting/active leading colours differ and module_render.sh's chan() wraps the
# leading block's bg in a draw-time #{?client_prefix,...} conditional. That
# block bg feeds directly into the seam colour formula, so the conditional ends
# up nested inside the seam's own #[fg=...] attribute — which utils/layout.sh
# then splices whole into status-format via #{s/<marker>/<seam>/:...}. This is
# the mechanism's main risk (the plan's own test 13): confirms tmux resolves
# the nested #{?} correctly instead of mangling it.
tmux set -g @themux_status_line_1 "session"
tmux set -g @themux_session_notch "auto"
src
run_layout
printf "\nactive_seam_nested_conditional_survives "
{ tmux show -gv 'status-format[0]' | grep -qF 'client_prefix'; } && printf "Y" || printf "n"
printf "\nactive_seam_has_gt_glyph "
{ tmux show -gv 'status-format[0]' | grep -qF "$mprr"; } && printf "Y" || printf "n"
tmux set -gu @themux_session_notch

# 14. FIX 1 regression (the user-confirmed dark notch triangle): cpu is an
# _expand module whose accent is a LIVE #{l:#{cpu_bg_color}} plugin literal.
# mod_core's _expand branch must run the seam through the SAME #{E:} expansion
# the core itself gets, BEFORE interp — same pipeline the icon backgrounds
# already ride. A dead (unpeeled) seam stays literally double-wrapped
# `#{l:#{cpu_bg_color}...}` in the baked status-format text (an invalid fg ->
# the dark glyph); once expanded exactly once it reads as a bare
# `#{cpu_bg_color}` literal (interp is a no-op here — no tmux-cpu plugin in the
# test harness — so it is not rewritten further, but the peel already
# happened, which is what mattered). Also re-checks FIX 2 across every
# status-format row, not just the centre case above.
tmux set -g @themux_status_line_1 "cpu / / "
tmux set -g @themux_all_notch "auto"
tmux set -g @themux_module_shape "rounded"
src
run_layout
fmt0=$(tmux show -gv 'status-format[0]')
printf "\ncpu_seam_not_double_wrapped "
{ printf '%s' "$fmt0" | grep -qF '#{l:#{cpu'; } && printf "n" || printf "Y"
printf "\ncpu_seam_live_colour_present "
{ printf '%s' "$fmt0" | grep -qF 'cpu_bg_color'; } && printf "Y" || printf "n"
# Unlike the centre-zone/ref-module check above, an _expand module's splice
# happens entirely at bash-string level (mod_core's _expand branch), before the
# result is ever stored — so the RAW status-format text is the right thing to
# check here; there is no draw-time #{s///} pattern argument to account for.
printf "\nno_raw_marker_in_any_status_format_row "
leak=0
for row_i in 0 1 2 3 4; do
  row=$(tmux show -gqv "status-format[$row_i]" 2>/dev/null) || true
  { printf '%s' "$row" | grep -qF "$(printf '\036')"; } && leak=1
done
{ [ "$leak" -eq 0 ]; } && printf "Y" || printf "n"
tmux set -gu @themux_all_notch

# 15. FIX 3 regression: window leading_position=right + notch auto. Before the
# fix the seam was emitted unconditionally right after the name block, so a
# window whose name resolves empty at draw time left a floating taper with
# nothing to taper into. The fix wraps the name content AND the seam inside the
# SAME #{?${text},…,} name-visibility conditional the position=left path
# already used. The exact adjacency "#{?#{E:@_tmx_w_text},#[fg=" only exists
# once the style/name content sits inside that conditional (old position=right
# code had no such wrapper at all), and the notch dispatch
# (@_tmx_window_notch_dir) must appear textually after that opening, inside the
# same conditional's branch.
tmux set -g @themux_status_line_1 "windows"
tmux set -g @themux_window_shape "rounded"
tmux set -g @themux_window_leading_position "right"
tmux set -g @themux_window_notch "auto"
src
run_layout
wfmt=$(tmux show -gv window-status-format)
printf "\nwindow_right_seam_inside_text_conditional "
{ printf '%s' "$wfmt" | grep -qF '#{?#{E:@_tmx_w_text},#[fg='; } && printf "Y" || printf "n"
printf "\nwindow_right_notch_dispatch_present "
{ printf '%s' "$wfmt" | grep -qF '@_tmx_window_notch_dir'; } && printf "Y" || printf "n"
printf "\nwindow_right_notch_dispatch_after_conditional_open "
before=${wfmt%%@_tmx_window_notch_dir*}
{ printf '%s' "$before" | grep -qF '#{?#{E:@_tmx_w_text},#[fg='; } && printf "Y" || printf "n"
tmux set -gu @themux_window_leading_position
tmux set -gu @themux_window_notch
tmux set -gu @themux_window_shape
