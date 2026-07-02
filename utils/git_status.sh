#!/usr/bin/env bash

# Minimal git status text for the git module: "<branch> <clean>" on a clean
# work tree, "<branch> <dirty> <n>C <n>M <n>S <n>D <n>?" on a dirty one (zero
# groups are omitted). Plain text only — no #[...] codes — so the renderer
# styles the block like any other module and every prop keeps working.
#
# Usage: git_status.sh <path> [<clean-symbol>] [<dirty-symbol>]
#        git_status.sh --dirty <path>
#
# --dirty backs @themux_git_active_when: it prints 1 when the work tree has
# any change — tracked or untracked — and 0 otherwise (tmux's #{?...} reads
# the string "0" as false). It runs the same porcelain (no -uno) as the text
# mode, so the accent and the text never disagree. Outside a repo the text
# mode prints nothing; both modes always exit 0.

set -u

if [ "${1-}" = "--dirty" ]; then
  changes=$(git -C "${2:-.}" --no-optional-locks status --porcelain 2>/dev/null | head -1)
  if [ -n "$changes" ]; then printf '1'; else printf '0'; fi
  exit 0
fi

path=${1:-.}
clean_sym=${2:-✓}
dirty_sym=${3:-!}

# Branch name, or a short SHA when HEAD is detached; bail quietly outside a repo.
branch=$(git -C "$path" symbolic-ref --short -q HEAD 2>/dev/null) ||
  branch=$(git -C "$path" rev-parse --short HEAD 2>/dev/null) || exit 0

status=$(git -C "$path" --no-optional-locks status --porcelain -b 2>/dev/null) || exit 0

# One porcelain pass, counted by the two-character XY code. An unmerged pair
# (UU, AU, UA, DU, UD, DD, AA) is checked first and counted into its own
# conflicts group so it never leaks into staged/modified/deleted. Otherwise X
# (index) feeds the staged group, Y (work tree) the modified/deleted groups,
# "??" the untracked group. A file can appear in two groups (e.g. staged with
# unstaged edits).
dirty=0 conflicts=0 staged=0 modified=0 deleted=0 untracked=0
while IFS= read -r line; do
  case $line in
  '' | '##'*) continue ;;
  '??'*)
    untracked=$((untracked + 1))
    dirty=1
    continue
    ;;
  esac
  dirty=1
  x=${line:0:1} y=${line:1:1}
  case $x$y in
  UU | AU | UA | DU | UD | DD | AA)
    conflicts=$((conflicts + 1))
    continue
    ;;
  esac
  case $x in [MTADRC]) staged=$((staged + 1)) ;; esac
  case $y in
  M | T) modified=$((modified + 1)) ;;
  D) deleted=$((deleted + 1)) ;;
  esac
done <<<"$status"

if [ "$dirty" -eq 0 ]; then
  printf '%s %s' "$branch" "$clean_sym"
  exit 0
fi

out="$branch $dirty_sym"
[ "$conflicts" -gt 0 ] && out="$out ${conflicts}C"
[ "$modified" -gt 0 ] && out="$out ${modified}M"
[ "$staged" -gt 0 ] && out="$out ${staged}S"
[ "$deleted" -gt 0 ] && out="$out ${deleted}D"
[ "$untracked" -gt 0 ] && out="$out ${untracked}?"
printf '%s' "$out"
