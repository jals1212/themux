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
# harness ERR-trap, which kills the tmux server on a bare zero-match grep. The
# path is quoted ("#{E:...}") so an install path containing spaces still works.
printf '\nin_repo_probe '
tmux show -gqv @_tmx_git_in_repo | { grep -oF 'rev-parse --is-inside-work-tree' || true; }
printf 'dirty_probe '
tmux show -gqv @_tmx_git_dirty | { grep -oF '#("#{E:@_tmx_git_script}" --dirty' || true; }
printf 'text_invocation '
tmux show -gqv @themux_git_text | { grep -oF '#("#{E:@_tmx_git_script}"' || true; }
printf 'script_path '
tmux show -gqv @_tmx_git_script | { grep -oF 'utils/git_status.sh' || true; }

# The baked core routes the active state through the dirty probe (an expanded
# draw would need a live repo path, so assert on the raw core).
printf 'core_active_switch '
tmux show -gqv @_tmx_module_git_core | { grep -oF '#{?#{E:@_tmx_git_dirty},' || true; } | sort -u

# gitmux keeps its stock colours but sits on the theme's darkest step.
print_option @themux_gitmux_text_bg

# The script itself, against a throwaway repo: clean, staged, modified plus
# untracked, the --dirty probe backing active_when, symbol overrides, an
# untracked-only work tree, a plain directory outside any repo, and a
# conflicted merge.
git_status="${script_dir}/../utils/git_status.sh"
repo=$(mktemp -d)
outside=$(mktemp -d)
conflict_repo=$(mktemp -d)
trap 'rm -rf "$repo" "$outside" "$conflict_repo"' EXIT

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

# Untracked-only: --dirty must agree with the text ("1"), matching the same
# porcelain semantics the text mode uses instead of the old "text says dirty,
# colour says clean" split.
git -C "$repo" -c user.name=themux -c user.email=themux@test -c commit.gpgsign=false commit -q -am settle
printf '\nscript_untracked_only [%s]' "$("$git_status" "$repo")"
printf '\nscript_probe_untracked_only [%s]' "$("$git_status" --dirty "$repo")"

printf '\nscript_outside_repo [%s]' "$("$git_status" "$outside")"

# Conflicts: a real UU from two branches editing the same line plus a failed
# merge, asserted on its own first. Then an add/add and a fabricated
# delete/delete (git plumbing — an ordinary merge almost never surfaces a
# genuine DD pair) are layered onto the same unresolved merge, asserting
# neither leaks into the staged/deleted groups.
git -C "$conflict_repo" init -q -b main
echo "base line" >"$conflict_repo/shared.txt"
echo "victim" >"$conflict_repo/victim.txt"
git -C "$conflict_repo" add shared.txt victim.txt
git -C "$conflict_repo" -c user.name=themux -c user.email=themux@test -c commit.gpgsign=false commit -q -m base
victim_blob=$(git -C "$conflict_repo" rev-parse HEAD:victim.txt)

git -C "$conflict_repo" checkout -q -b feature
echo "feature line" >"$conflict_repo/shared.txt"
git -C "$conflict_repo" -c user.name=themux -c user.email=themux@test -c commit.gpgsign=false commit -q -am feature

git -C "$conflict_repo" checkout -q main
echo "main line" >"$conflict_repo/shared.txt"
git -C "$conflict_repo" -c user.name=themux -c user.email=themux@test -c commit.gpgsign=false commit -q -am mainedit

git -C "$conflict_repo" merge feature --no-edit -q >/dev/null 2>&1 || true
printf '\nscript_conflict [%s]' "$("$git_status" "$conflict_repo")"

blob_one=$(printf 'one\n' | git -C "$conflict_repo" hash-object -w --stdin)
blob_two=$(printf 'two\n' | git -C "$conflict_repo" hash-object -w --stdin)
{
  printf '100644 %s 2\tadded.txt\n' "$blob_one"
  printf '100644 %s 3\tadded.txt\n' "$blob_two"
} | git -C "$conflict_repo" update-index --index-info
printf 'two\n' >"$conflict_repo/added.txt"

git -C "$conflict_repo" rm -q --cached victim.txt
rm -f "$conflict_repo/victim.txt"
printf '100644 %s 1\tvictim.txt\n' "$victim_blob" | git -C "$conflict_repo" update-index --index-info

printf '\nscript_conflict_extended [%s]\n' "$("$git_status" "$conflict_repo")"
