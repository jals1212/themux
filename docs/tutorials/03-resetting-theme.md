# Switching theme or style at runtime

themux resets its own derived state automatically every time it loads, so to
change the theme, a variant, or any styling option you just update the option
and reload your config — no `tmux kill-server`, no reset option to set.

```sh
# In your tmux.conf (or wherever you load themux), change the value...
set -g @themux_theme "catppuccin_latte"
# ...then reload (e.g. prefix + r, or `tmux source-file ~/.tmux.conf`).
```

## How it works

When `themux.tmux` runs, it first clears what themux *derives* — the palette
(`@thm_*`), internal state (`@_tmx_*`), the variant-set separators/borders and
the status/window/pane formats — and then rebuilds everything from your current
options. It never clears your `@themux_*` configuration, so your variants,
module lists and overrides survive the reload. The reset is skipped on a fresh
server, where there is nothing to clear yet.

This means any option can be changed and reapplied with a plain reload:

```sh
set -g @themux_status_variant "flat"
set -g @themux_windows_variant "rounded"
# reload
```

## Light/dark switching with hooks

On tmux 3.6+ you can drive it from the dark/light theme hooks:

```conf
set-hook -g client-dark-theme {
  set -g @themux_theme "catppuccin_mocha"
  run ~/.config/tmux/plugins/themux/themux.tmux
}
set-hook -g client-light-theme {
  set -g @themux_theme "catppuccin_latte"
  run ~/.config/tmux/plugins/themux/themux.tmux
}
```
