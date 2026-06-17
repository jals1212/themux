#!/usr/bin/env bash
# Load the @thm_* palette for the selected @themux_theme.
#
# Built-in themes are data files (themes/<name>.palette: "name hex" per line,
# "#"/blank lines ignored) applied in a single chained `tmux set` — one source
# of truth for how a palette is set, and one round-trip. Falls back to sourcing
# a legacy themes/<name>_tmux.conf, so custom themes in the old `set -ogq @thm_*`
# format keep working.

dir=$(dirname "$0")
theme=$(tmux show -gqv @themux_theme)
palette="$dir/../themes/${theme}.palette"

if [ -f "$palette" ]; then
  args=()
  while read -r name hex _; do
    case "$name" in '' | \#*) continue ;; esac
    [ ${#args[@]} -eq 0 ] || args+=(';')
    args+=(set -ogq "@thm_${name}" "$hex")
  done <"$palette"
  [ ${#args[@]} -gt 0 ] && tmux "${args[@]}"
else
  tmux source -F "$dir/../themes/${theme}_tmux.conf"
fi
