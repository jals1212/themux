#!/usr/bin/env bash
# themux clean reload — bound to @themux_reload_key by themux.tmux.
#
# themux keeps your @themux_* options across reloads by design, so an option you
# remove from (or change in) your config would otherwise linger. This unsets every
# @themux_* option first, so anything not re-applied falls back to the themux
# default, then re-sources your config (which re-sets what it declares and reloads
# themux; themux.tmux then re-derives @thm_*/@_tmx_* and the formats).
#
# The unset MUST happen here, before the re-source: themux loads at the end of your
# config, so by the time it runs your options are already set and it cannot tell a
# stale option from a current one — only the reload trigger can clear first.

# Bulk unset in ONE tmux process: pipe a `set -gu <opt>` line per option into
# source-file (~10 ms). One fork per option (xargs) is ~2 s for ~130 options.
tmux show -g | grep -oE '^@themux_[A-Za-z0-9_]+' | sed 's/^/set -gu /' | tmux source-file /dev/stdin

# Re-source your config: the last file tmux auto-loaded (#{config_files}, tmux ≥ 3.3)
# is your main config, mirroring a normal `source-file` reload. Skip if unresolved.
cfg=$(tmux display-message -p '#{config_files}' | tr ',' '\n' | tail -n1)
[ -n "$cfg" ] && [ -f "$cfg" ] && tmux source-file "$cfg"

tmux display-message "themux: clean reload"
