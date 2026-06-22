# Switching theme or style at runtime

themux resets its own derived state automatically every time it loads, so to
change the theme or any styling option you just update the option
and reload your config — no `tmux kill-server` needed.

```sh
# In your tmux.conf (or wherever you load themux), change the value...
set -g @themux_theme "catppuccin_latte"
# ...then reload (e.g. prefix + r, or `tmux source-file ~/.tmux.conf`).
```

## How it works

When `themux.tmux` runs, it first clears what themux *derives* — the palette
(`@thm_*`), internal state (`@_tmx_*`), the derived separators/borders and
the status/window/pane formats — and then rebuilds everything from your current
options. It never clears your `@themux_*` configuration, so your styles,
module lists and overrides survive the reload. The reset is skipped on a fresh
server, where there is nothing to clear yet.

So *changing* an option and reloading just works:

```sh
set -g @themux_module_text_variant "naked"
set -g @themux_window_shape "rounded"
# reload
```

## Resetting to defaults (clean reload)

The flip side of options surviving: *removing* one from your config does **not**
revert it — tmux keeps the last value until it is unset, so a plain reload leaves
the old setting in place. To make a reload start from defaults, set
`@themux_reload_key`. themux binds that key to a clean reload that unsets every
`@themux_*` first, then re-sources your whole config — so anything you removed
falls back to its default (and the rest of your `tmux.conf` reloads too):

```conf
set -g @themux_reload_key "r"   # prefix + r now does a clean reload
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
