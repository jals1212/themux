<!-- markdownlint-disable -->
<h3 align="center">
 <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/logos/exports/1544x1544_circle.png" width="100" alt="Logo"/><br/>
 <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
 Catppuccin for <a href="https://github.com/tmux/tmux">Tmux</a>
 <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
</h3>

<p align="center">
    <a href="https://github.com/catppuccin/tmux/stargazers"><img src="https://img.shields.io/github/stars/catppuccin/tmux?colorA=363a4f&colorB=b7bdf8&style=for-the-badge"></a>
    <a href="https://github.com/catppuccin/tmux/issues"><img src="https://img.shields.io/github/issues/catppuccin/tmux?colorA=363a4f&colorB=f5a97f&style=for-the-badge"></a>
    <a href="https://github.com/catppuccin/tmux/contributors"><img src="https://img.shields.io/github/contributors/catppuccin/tmux?colorA=363a4f&colorB=a6da95&style=for-the-badge"></a>
</p>

<p align="center">
  <img src="./assets/preview.webp"/>
</p>
<!-- markdownlint-enable -->

## Themes

<details>
<summary>🌻 Latte</summary>

![Latte Flavor Preview](./assets/latte.webp)

</details>
<details>
<summary>🪴 Frappé</summary>

![Frappe Flavor Preview](./assets/frappe.webp)

</details>
<details>
<summary>🌺 Macchiato</summary>

![Macchiato Flavor Preview](./assets/macchiato.webp)

</details>
<details>
<summary>🌿 Mocha</summary>

![Mocha Flavor Preview](./assets/mocha.webp)

</details>

### Multi-theme selection (themux)

This fork is a multi-theme manager: besides the catppuccin flavors, other
themes can be selected with `@themux_theme`, which loads
`themes/<theme>_tmux.conf`:

```sh
# Kanagawa (wave, dragon or lotus)
set -g @themux_theme 'kanagawa_dragon'

# Catppuccin (latte, frappe, macchiato or mocha)
set -g @themux_theme 'catppuccin_frappe'
```

Available themes: `catppuccin_latte`, `catppuccin_frappe`,
`catppuccin_macchiato`, `catppuccin_mocha`, `kanagawa_wave`,
`kanagawa_dragon`, `kanagawa_lotus`.

### Style variants (themux)

Every item of the UI selects its style independently. `unstyled` makes
themux leave that item completely untouched, so you can build it by hand
with the `@thm_*` palette colors:

```sh
set -g @themux_status_variant  "rounded" # squared, rounded, slanted, flat, unstyled
set -g @themux_windows_variant "squared" # squared, rounded, slanted, flat, unstyled
set -g @themux_panes_variant   "squared" # squared, rounded, slanted, flat, unstyled
```

Window and pane variants live one file per look under `variants/windows/`
and `variants/panes/`, so adding a new look is dropping a file there.

### Composition (themux)

Each item of tmux is a component you compose declaratively. List the
component names and themux builds `status-left`/`status-right` for you — a
token `NAME` becomes the `@themux_status_NAME` segment. Separate modules with
a space; put a `|` between two of them to insert a divider:

```sh
set -g @themux_status_left_modules  "session|application|directory zoom"
set -g @themux_status_right_modules "gitmux|ram|date_time"
```

Leave them empty to compose `status-left`/`status-right` by hand instead.

### Flat style (themux)

By default status modules render as "pills" — icon and text blocks with
their own backgrounds — even when `@themux_status_background` is set to
`"none"` (that option only clears the bar itself). For a fully transparent
status line, this fork adds a flat variant: modules become colored text on
the default background, separated by a configurable divider.

```sh
# Before loading the plugin
set -g @themux_status_variant "flat"  # transparent modules
set -g @themux_windows_variant "flat" # flat window list to match
set -g @themux_status_background "none"

# Optional: tweak the default divider segment (its text includes padding)
set -g @themux_divider_text " │ "
set -g @themux_divider_color "#{@thm_overlay_0}"

# Optional: flat window list colors
set -g @themux_window_flat_text_color "#{@thm_rosewater}"  # inactive windows
set -g @themux_window_flat_last_color "#{@thm_peach}"      # last window
set -g @themux_window_flat_current_fg "#{@thm_bg}"         # current window
set -g @themux_window_flat_current_bg "#{@thm_peach}"
```

In flat mode each module's icon and text take the module color
(`@themux_<module>_color`), so all the existing modules and the
per-module options keep working — only the rendering changes. Modules draw
no dividers themselves; compose them explicitly with the divider segment:

```sh
set -g status-left ""
set -ga status-left "#{E:@themux_status_session}"
set -ga status-left "#{E:@themux_status_divider}"
set -ga status-left "#{E:@themux_status_application}"
```

Different dividers can coexist: create extra named divider segments from
the template (after loading the plugin), each with its own text and color:

```sh
%hidden DIVIDER_NAME="dot"
set -g @themux_dot_text "·"
source -F "~/.config/tmux/plugins/themux/utils/divider.conf"

set -ga status-right "#{E:@themux_status_dot}"
```

This fork also adds a `zoom` status module
(`#{E:@themux_status_zoom}`) that renders only while the active pane
is zoomed, in both pill and flat styles.

### Multi-line status (themux)

Give the window list its own status line (aligned by `status-justify`),
leaving the other line to `status-left`/`status-right`:

```sh
set -g @themux_windows_line "stacked"    # inline (default), stacked, spaced
set -g @themux_windows_position "bottom" # top, bottom
```

- `inline` keeps the stock single line (windows between left and right).
- `stacked` puts the window list on its own line.
- `spaced` does the same with a blank line between them.
- `@themux_windows_position` chooses which line the window list takes.

### Reset pattern (themux)

Source `themux_reset.conf` at the top of your theme config, before setting
any `@themux_*` option. On a running server it wipes all themux-derived
state (palette, options, built segments, status/window formats), so
re-sourcing your config switches theme or style cleanly — no
`tmux kill-server` needed. On fresh servers it is a no-op.

```sh
source ~/.config/tmux/plugins/themux/themux_reset.conf
set -g @themux_theme 'kanagawa_dragon'
# ... options ...
run ~/.config/tmux/plugins/themux/themux.tmux
```


## Installation

In order to have the icons displayed correctly please use/update your favorite
[nerd font](https://www.nerdfonts.com/font-downloads).
If you do not have a patched font installed, you can override or remove any
icon. Check the [documentation](./docs/reference/configuration.md) on the
options available.

### Manual (Recommended)

This method is recommended as TPM has some issues with name conflicts.

<!-- x-release-please-start-version -->

1. Clone this repository to your desired location (e.g.
   `~/.config/tmux/plugins/catppuccin`).

   ```bash
   mkdir -p ~/.config/tmux/plugins/catppuccin
   git clone -b v2.3.0 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
   ```

1. Add the following line to your `tmux.conf` file:
   `run ~/.config/tmux/plugins/catppuccin/tmux/themux.tmux`.
1. Reload Tmux by either restarting or reloading with `tmux source ~/.tmux.conf`.
<!-- x-release-please-end -->

Check out what to do next in the "[Getting Started Guide](./docs/tutorials/01-getting-started.md)".

### TPM

<!-- x-release-please-start-version -->

1.  Install [TPM](https://github.com/tmux-plugins/tpm)
1.  Add the Catppuccin plugin:

    ```bash
    set -g @plugin 'catppuccin/tmux#v2.3.0' # See https://github.com/catppuccin/tmux/tags for additional tags
    # ...alongside
    set -g @plugin 'tmux-plugins/tpm'
    ```

1.  (Optional) Set your preferred theme, it defaults to `catppuccin_mocha`:

    ```bash
    set -g @themux_theme 'catppuccin_mocha'
    ```

    <!-- x-release-please-end -->

> [!IMPORTANT]
> You may have to run `~/.config/tmux/plugins/tpm/bin/clean_plugins`
> if upgrading from an earlier version
> (especially from `v0.3.0`).

### For TMUX versions prior to 3.2

This plugin uses features that were only introduced into tmux in version 3.2.
If you are using a version earlier than this, you can still have lovely
catppuccin colors, the installation method just looks a little different.

```sh
# In your ~/.tmux.conf

# Add the colors from the pallete. Check the themes/ directory for all options.

# Some basic mocha colors.
set -g @ctp_bg "#24273a"
set -g @ctp_surface_1 "#494d64"
set -g @ctp_fg "#cad3f5"
set -g @ctp_mauve "#c6a0f6"
set -g @ctp_crust "#181926"

# status line
set -gF status-style "bg=#{@ctp_bg},fg=#{@ctp_fg}"

# windows
set -gF window-status-format "#[bg=#{@ctp_surface_1},fg=#{@ctp_fg}] ##I ##T "
set -gF window-status-current-format "#[bg=#{@ctp_mauve},fg=#{@ctp_crust}] ##I ##T "
```

### For TMUX versions prior to 3.6

This plugin can be used in conjunction with the support for tmux to
automatically report dark or light themes using hooks. You can leverage these
hooks in your tmux configuration file like so:

```conf
set-hook -g client-dark-theme {
  source ~/code/github.com/catppuccin/tmux/themux_reset.conf
  set -g @themux_theme "catppuccin_frappe"
  run ~/code/github.com/catppuccin/tmux/themux.tmux
}
set-hook -g client-light-theme {
  source ~/code/github.com/catppuccin/tmux/themux_reset.conf
  set -g @themux_theme "catppuccin_latte"
  run ~/code/github.com/catppuccin/tmux/themux.tmux
}
```

The above is only possible with versions of tmux 3.6+. To replicate this
functionality with versions prior to 3.6, you can will need to set variables and
run the `cappuccin.tmux` file and trigger it yourself. If you'd like some
inspiration for how to do this, read through [the Bash code found in this Nix
function here][reload-example] which reloads Catppuccin on-demand without
relying on tmux hooks.

[reload-example]: https://git.sr.ht/~rogeruiz/.files.nix/tree/1dedf4da47f995ec41e07d37b65008ad0f464717/item/module/tools/terminal/tmux/catppuccin/bin/default.nix "An example from a catppuccin/tmux maintainer on how to manually reload the Catppuccin configuration on macOS."

> [!IMPORTANT]
> As mentioned in the comments in the `conf` snippet above, you may find that
> you'll need to add to the list of `@themux_*` variables. Test your
> configuration by switching themes and noting what of the Tmux session isn't
> getting reset to an expected color.

### Upgrading from v0.3

Breaking changes have been introduced since 0.3, to understand how to migrate
your configuration, see pinned issue [#487](https://github.com/catppuccin/tmux/issues/487).

## Recommended Default Configuration

This configuration shows some customisation options, that can be further
extended as desired.
This is what is used for the previews above.

![Example configuration](./assets/mocha.webp)

```bash
# ~/.tmux.conf

# Options to make tmux more pleasant
set -g mouse on
set -g default-terminal "tmux-256color"

# Configure the catppuccin plugin
set -g @themux_theme "catppuccin_mocha"
set -g @themux_windows_variant "rounded"

# Load catppuccin
run ~/.config/tmux/plugins/catppuccin/tmux/themux.tmux
# For TPM, instead use `run ~/.tmux/plugins/tmux/themux.tmux`

# Make the status line pretty and add some modules
set -g status-right-length 100
set -g status-left-length 100
set -g status-left ""
set -g status-right "#{E:@themux_status_application}"
set -agF status-right "#{E:@themux_status_cpu}"
set -agF status-right "#{E:@themux_status_ram}"
set -ag status-right "#{E:@themux_status_session}"
set -ag status-right "#{E:@themux_status_uptime}"
set -agF status-right "#{E:@themux_status_battery}"

run ~/.config/tmux/plugins/tmux-plugins/tmux-cpu/cpu.tmux
run ~/.config/tmux/plugins/tmux-plugins/tmux-battery/battery.tmux
# Or, if using TPM, just run TPM
```

## Documentation

### Guides

- [Getting Started](./docs/tutorials/01-getting-started.md)
- [Custom Status Line Segments](./docs/tutorials/02-custom-status.md)
- [Troubleshooting](./docs/guides/troubleshooting.md)

### Reference

- [Status Line](./docs/reference/status-line.md)
- [Configuration Options Reference](./docs/reference/configuration.md)
- [Tmux Configuration Showcase](https://github.com/catppuccin/tmux/discussions/317)

## 💝 Credits

themux is a multi-theme fork of [catppuccin/tmux] — the module system,
status-line architecture, and the catppuccin palettes are their work
(MIT, Copyright © Catppuccin Org).

The flat style is inspired by [@89iuv]'s configuration shared in the
catppuccin/tmux [configuration showcase][89iuv-config].

[catppuccin/tmux]: https://github.com/catppuccin/tmux
[@89iuv]: https://github.com/89iuv
[89iuv-config]: https://github.com/catppuccin/tmux/discussions/317#discussioncomment-11064512

Thanks to the original catppuccin/tmux contributors:

- [Pocco81](https://github.com/Pocco81)
- [vinnyA3](https://github.com/vinnyA3)
- [rogeruiz](https://github.com/rogeruiz)
- [kales](https://github.com/kjnsn)

&nbsp;

<!-- markdownlint-disable -->
<p align="center">
<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/footers/gray0_ctp_on_line.svg?sanitize=true" /></p>
<p align="center">Copyright &copy; 2021-present <a href="https://github.com/catppuccin" target="_blank">Catppuccin Org</a>
<p align="center"><a href="https://github.com/catppuccin/catppuccin/blob/main/LICENSE"><img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logoColor=d9e0ee&colorA=363a4f&colorB=b7bdf8"/></a></p>
<!-- markdownlint-enable -->
