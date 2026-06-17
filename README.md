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
`themes/<theme>.palette` (a plain `name hex` palette — a legacy
`themes/<theme>_tmux.conf` with `set -ogq @thm_*` still works for custom themes):

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

Every item of the UI — status modules, the window list, panes — is a
*component* with independent props, so any combination is valid:

```sh
set -g @themux_module_shape     "rounded"
set -g @themux_module_indicator "solid"  # the icon/number block
set -g @themux_module_text      "naked"  # the text block (windows: _name)
set -g @themux_module_notch     "off"
```

- **shape** — `squared`, `rounded`, `slanted` (blocks with square / round /
  slant caps) or `unstyled` to leave the item untouched and build it by hand
  with the `@thm_*` palette.
- **indicator / text** — the icon-or-number block and the text block each take a
  style: `solid` (accent block), `soft` (grey block), `subtle` (grey block,
  accent text) or `naked` (transparent, accent text — pair with
  `@themux_status_background "none"`). A naked block keeps the shape's caps as an
  outline, so `rounded` indicator + `naked` text reads as a capsule.
- **notch** — `on` makes the indicator↔text seam inherit the shape's cap instead
  of a flat edge.

On windows the text-block prop is `@themux_window_name` (the window name content
already owns `@themux_window_text`). Replaces the old
`@themux_<item>_variant` / `_fill` options.

### Composition (themux)

The status line is built from up to five rows (`@themux_status_line_1` … `_5`).
Each row is split into zones by `/` — none gives one left column, one gives
**left + right**, two gives left / center / right. A zone is a list of component
names (a token `NAME` becomes the `@themux_module_NAME` segment) or the special
token `windows` (the window list). Separate modules with a space; put a `|`
between two of them to insert the modules divider:

```sh
set -g @themux_status_line_1 "session|application|directory / windows / gitmux|ram|date_time"
```

Rows render up to the last non-empty line, so a blank (`""`) line in between
becomes an empty row — handy for spacing. The window list aligns to its zone:

```sh
set -g @themux_status_line_1 "session / gitmux date_time"   # left + right
set -g @themux_status_line_2 ""                             # blank row
set -g @themux_status_line_3 "windows"                      # windows, own row
```

The divider between status modules and the divider between windows are
configured independently:

```sh
set -g @themux_module_divider " | "            # what "|" inserts
set -g @themux_module_divider_color "#{@thm_overlay_0}"
set -g @themux_window_divider " "                     # window-status-separator
set -g @themux_window_divider_color "#{@thm_overlay_0}"
```

Emptying a divider connects the items into a continuous powerline ribbon:
modules joined with `|` (or listed adjacent) merge into one run, and the window
list becomes a single ribbon with the active window raised over its neighbours.

> [!NOTE]
> The connected window ribbon (rounded/slanted shapes) colours each seam from
> its neighbour and caps the first window using the window index, both of which
> assume **contiguous** window indices. Pair it with:
>
> ```sh
> set -g renumber-windows on
> ```
>
> so killing a middle window never leaves a gap. Without it, the seam and left
> cap next to a gap render incorrectly until you renumber.

### Pane status (themux)

Off by default. `@themux_pane_status` is the master switch for the styled label
on each pane border — set it to `top` or `bottom` to enable (the variant only
picks the shape, never turns it on). With `off`, themux leaves pane borders at
tmux's defaults.

```sh
set -g @themux_pane_status "top"                                  # off | top | bottom
set -g @themux_pane_indicator_highlight_color "#{@thm_green}"     # active number accent
set -g @themux_pane_text_highlight_color "#{@thm_green}"          # active label accent
set -g @themux_pane_indicator_highlight "both"                    # off | bg | fg | both
set -g @themux_pane_default_text "#{b:pane_current_path}"         # label text
set -g @themux_pane_indicator_position "left"                     # left | right
```

### Window names (themux)

`@themux_window_text_mode` controls when a window shows its name:

```sh
set -g @themux_window_text_mode "always"  # always | never | manual
```

- `always` — the name is always shown.
- `never` — only the number block.
- `manual` — the name shows only on windows you renamed by hand (tmux's
  `automatic-rename` off); auto-named windows show just the number.

### Naked style (themux)

By default status modules render as "pills" — icon and text blocks with their
own backgrounds — even when `@themux_status_background` is `"none"` (that option
only clears the bar itself). For a fully transparent status line, set the
`naked` style: blocks become colored text on the default background.

```sh
# Before loading the plugin
set -g @themux_module_indicator "naked"
set -g @themux_module_text      "naked"  # transparent modules
set -g @themux_window_indicator "naked"
set -g @themux_window_name      "naked"  # naked window list to match
set -g @themux_status_background "none"
```

`naked` is per part, so it pairs with any shape and with the other styles: a
`rounded` shape keeps the bare bar but outlines each item with the rounded caps,
and a `solid` indicator + `naked` text gives a colored chip with a transparent
label. Each module's icon and text take the module color
(`@themux_<module>_color`), so all the existing modules and per-module options
keep working — only the rendering changes.

Extra named dividers can be created from the template (after loading the
plugin) and then dropped into a zone as a token:

```sh
%hidden DIVIDER_NAME="dot"
set -g @themux_dot_text "·"
source -F "~/.config/tmux/plugins/themux/utils/divider.conf"

set -g @themux_status_line_1 "session dot application / windows / date_time"
```

This fork also adds a `zoom` status module
(`#{E:@themux_module_zoom}`) that renders only while the active pane
is zoomed, in both pill and naked styles.

### Clean reloads (themux)

themux resets its own derived state automatically when it loads: on a running
server `themux.tmux` clears the palette, internals, the variant-set separators
and the status/window/pane formats *before* rebuilding — but never your
`@themux_*` config. So switching theme, variant or style is just a config
reload; no `tmux kill-server`, no reset file to source.

```sh
set -g @themux_theme 'kanagawa_dragon'
# ... options ...
run ~/.config/tmux/plugins/themux/themux.tmux  # resets + rebuilds
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
  set -g @themux_theme "catppuccin_frappe"
  run ~/code/github.com/catppuccin/tmux/themux.tmux
}
set-hook -g client-light-theme {
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
set -g @themux_window_shape "rounded"

# Load catppuccin
run ~/.config/tmux/plugins/catppuccin/tmux/themux.tmux
# For TPM, instead use `run ~/.tmux/plugins/tmux/themux.tmux`

# Make the status line pretty and add some modules
set -g status-right-length 100
set -g status-left-length 100
set -g status-left ""
set -g status-right "#{E:@themux_module_application}"
set -agF status-right "#{E:@themux_module_cpu}"
set -agF status-right "#{E:@themux_module_ram}"
set -ag status-right "#{E:@themux_module_session}"
set -ag status-right "#{E:@themux_module_uptime}"
set -agF status-right "#{E:@themux_module_battery}"

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

The naked style is inspired by [@89iuv]'s configuration shared in the
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
