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
# fabricated conflicted index.
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

# Conflicts: fabricated deterministically via index stages, not a real merge
# — a real `git merge` needs a committer identity and depends on the git
# version's merge/diff machinery, so it is version- and environment-sensitive
# (observed on CI: no git identity configured makes an un-`-c`'d merge abort
# before it ever runs, silently swallowed by `|| true`, leaving a clean repo).
# The index-stage combination is what git itself uses to derive the XY code:
# stage 1 (base) + 2 (ours) + 3 (theirs) = UU; 2 + 3 with no 1 = AA; 1 alone
# (no 2, no 3) = DD. Each fabrication is verified against a fresh
# `git status --porcelain` right away — a stanza that fails to register turns
# into an immediate, clearly labelled failure instead of a silently wrong
# count later.
require_conflict() { # $1 expected "XY path" line, $2 porcelain status text
  grep -qF "$1" <<<"$2" && return 0
  printf 'FIXTURE ERROR: expected "%s" in git status --porcelain, got:\n%s\n' \
    "$1" "$2" >&2
  exit 1
}

git -C "$conflict_repo" init -q -b main
printf 'shared base\n' >"$conflict_repo/shared.txt"
printf 'victim\n' >"$conflict_repo/victim.txt"
git -C "$conflict_repo" add shared.txt victim.txt
git -C "$conflict_repo" -c user.name=themux -c user.email=themux@test -c commit.gpgsign=false commit -q -m base
shared_base=$(git -C "$conflict_repo" rev-parse HEAD:shared.txt)
victim_base=$(git -C "$conflict_repo" rev-parse HEAD:victim.txt)
shared_ours=$(printf 'shared ours\n' | git -C "$conflict_repo" hash-object -w --stdin)
shared_theirs=$(printf 'shared theirs\n' | git -C "$conflict_repo" hash-object -w --stdin)
added_ours=$(printf 'added ours\n' | git -C "$conflict_repo" hash-object -w --stdin)
added_theirs=$(printf 'added theirs\n' | git -C "$conflict_repo" hash-object -w --stdin)

# UU: drop the plain (stage 0) entry, then fabricate all three stages.
git -C "$conflict_repo" rm -q --cached shared.txt
{
  printf '100644 %s 1\tshared.txt\n' "$shared_base"
  printf '100644 %s 2\tshared.txt\n' "$shared_ours"
  printf '100644 %s 3\tshared.txt\n' "$shared_theirs"
} | git -C "$conflict_repo" update-index --index-info
printf 'shared ours\n' >"$conflict_repo/shared.txt"

status=$(git -C "$conflict_repo" --no-optional-locks status --porcelain)
require_conflict 'UU shared.txt' "$status"
printf '\nscript_conflict [%s]' "$("$git_status" "$conflict_repo")"

# AA: added.txt gets stage 2 + 3 only (no stage 1 — no common ancestor).
{
  printf '100644 %s 2\tadded.txt\n' "$added_ours"
  printf '100644 %s 3\tadded.txt\n' "$added_theirs"
} | git -C "$conflict_repo" update-index --index-info
printf 'added theirs\n' >"$conflict_repo/added.txt"

# DD: victim.txt drops the stage 0 entry and keeps only stage 1 (both sides
# deleted it, so no worktree file either).
git -C "$conflict_repo" rm -q --cached victim.txt
rm -f "$conflict_repo/victim.txt"
printf '100644 %s 1\tvictim.txt\n' "$victim_base" | git -C "$conflict_repo" update-index --index-info

status=$(git -C "$conflict_repo" --no-optional-locks status --porcelain)
require_conflict 'AA added.txt' "$status"
require_conflict 'DD victim.txt' "$status"
require_conflict 'UU shared.txt' "$status"
printf '\nscript_conflict_extended [%s]\n' "$("$git_status" "$conflict_repo")"
