#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# shellcheck disable=SC1091
source "${script_dir}/helpers.sh"

# A module renders only when referenced in a status line (lazy render).
tmux set -g @themux_status_line_1 "git"
tmux source "${script_dir}/../themux_options.conf"
tmux source "${script_dir}/../themux.conf"

# Wiring: the when gate, the dirty escalation and the accent options all point
# at the expected internal probes and palette roles.
print_option @themux_git_when
print_option @themux_git_active_when
print_option @themux_git_active_color
print_option @themux_git_color

# The internal probes and the script invocation. grep -o keeps the output
# deterministic (the baked script path is absolute) and `|| true` guards the
# harness ERR-trap, which kills the tmux server on a bare zero-match grep.
printf '\nin_repo_probe '
tmux show -gqv @_tmx_git_in_repo | { grep -oF 'rev-parse --is-inside-work-tree' || true; }
printf 'dirty_probe '
tmux show -gqv @_tmx_git_dirty | { grep -oF '#(#{E:@_tmx_git_script} --dirty' || true; }
printf 'text_invocation '
tmux show -gqv @themux_git_text | { grep -oF '#(#{E:@_tmx_git_script}' || true; }
printf 'script_path '
tmux show -gqv @_tmx_git_script | { grep -oF 'utils/git_status.sh' || true; }

# The baked core routes the active state through the dirty probe (an expanded
# draw would need a live repo path, so assert on the raw core).
printf 'core_active_switch '
tmux show -gqv @_tmx_module_git_core | { grep -oF '#{?#{E:@_tmx_git_dirty},' || true; } | sort -u

# gitmux keeps its stock colours but sits on the theme's darkest step.
print_option @themux_gitmux_text_bg

# The script itself, against a throwaway repo: clean, staged, modified plus
# untracked, the --dirty probe backing active_when, symbol overrides, and a
# plain directory outside any repo.
git_status="${script_dir}/../utils/git_status.sh"
repo=$(mktemp -d)
git -C "$repo" init -q -b main
git -C "$repo" -c user.name=themux -c user.email=themux@test -c commit.gpgsign=false commit -q --allow-empty -m init

printf '\nscript_clean [%s]' "$("$git_status" "$repo")"
printf '\nscript_probe_clean [%s]' "$("$git_status" --dirty "$repo")"

echo staged >"$repo/staged_file"
git -C "$repo" add staged_file
printf '\nscript_staged [%s]' "$("$git_status" "$repo")"

git -C "$repo" -c user.name=themux -c user.email=themux@test -c commit.gpgsign=false commit -q -m add
echo change >>"$repo/staged_file"
echo untracked >"$repo/untracked_file"
printf '\nscript_modified_untracked [%s]' "$("$git_status" "$repo")"
printf '\nscript_probe_dirty [%s]' "$("$git_status" --dirty "$repo")"
printf '\nscript_symbols [%s]' "$("$git_status" "$repo" OK WARN)"

outside=$(mktemp -d)
printf '\nscript_outside_repo [%s]\n' "$("$git_status" "$outside")"
rm -rf "$repo" "$outside"
