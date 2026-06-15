## Configuration Reference

<img src="../../assets/structure.svg" style="background: #eff1f5" />

Every option is a tmux user option (`@themux_*`). Set them **before the plugin
loads** unless noted. Colors accept a hex code (`#ff0000`) or a palette token
(`#{@thm_<name>}`, e.g. `#{@thm_mauve}`). themux re-derives its state on every
load, so changing an option and reloading is enough — no `kill-server`.

The three UI items — **status modules**, **windows**, **panes** — share one
*variant grammar*: a space-separated `"<shape> [fill] [notch]"` string.

---

### Theme

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_theme` | `catppuccin_mocha` | Palette: `catppuccin_{latte,frappe,macchiato,mocha}` or `kanagawa_{wave,dragon,lotus}`. Loads `themes/<theme>_tmux.conf`, which exposes the `@thm_*` colors. |

### Variant grammar — per item

Each item picks its look independently through one option whose value is up to
three tokens, in any order: a **shape**, a **fill**, and the **notch** flag.

```sh
set -g @themux_module_variant "rounded"             # shape only
set -g @themux_window_variant "slanted fill"        # shape + fill
set -g @themux_pane_variant   "rounded naked notch" # shape + fill + notch
```

| Option | Default |
| --- | --- |
| `@themux_module_variant` | `rounded` |
| `@themux_window_variant` | `squared` |
| `@themux_pane_variant` | `squared` |

**shape** — the block and its caps. Default `squared`.

| Token | Effect |
| --- | --- |
| `squared` / `rounded` / `slanted` | Solid block with square / round / slant caps. |
| `unstyled` | themux leaves the item untouched so you can style it by hand. |

**fill** — how much of the badge takes the accent color. Default `icon`.

| Token | Effect | Items |
| --- | --- | --- |
| `icon` | Only the icon/number block is colored; the rest stays neutral. | all |
| `fill` | The whole badge is one solid accent block. | all |
| `none` | Fully neutral, no accent. | modules, panes |
| `naked` | Transparent: accent *text* on the bare bar, and only the **active** window/pane is a solid block with the shape's caps. Pair with `@themux_status_background "none"`. | all |

**notch** — present or absent. With it the icon↔text seam (number↔name for
windows) inherits the shape's cap glyph instead of meeting on a flat boundary.

For windows/panes, only the **active** item keeps the bright accent; inactive
ones dim (windows → `@themux_window_number_color`, panes → `overlay_0`).

> The old `@themux_<item>_fill` options are gone — fill is now a token in the
> variant string (e.g. `@themux_window_fill "all"` becomes
> `@themux_window_variant "<shape> fill"`).

### Status line background

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_status_background` | `default` | `default` (theme color), `none` (transparent), or any hex / `#{@thm_*}`. |

---

### Status layout

The bar is built from up to five rows. Each is `"<left> / <center> / <right>"`;
a zone is a module list (token `NAME` → the `@themux_module_NAME` segment, `|`
inserts a divider, space = adjacent) or the special token `windows`. Blank zones
render nothing; the number of non-empty rows sets how many status lines show.

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_status_line_1` | `" / windows / "` | First row. |
| `@themux_status_line_2` … `_5` | `""` | Extra rows (blank = unused). |

```sh
set -g @themux_status_line_1 "session|application|directory / windows / gitmux|ram|date_time"
set -g @themux_status_line_2 " / windows / "   # windows on their own row
```

### Dividers

The divider between **status modules** and the one between **windows** are
independent.

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_module_divider` | `" │ "` | Text the `|` inserts between modules (includes its own padding). |
| `@themux_module_divider_color` | `#{@thm_overlay_0}` | Its color. |
| `@themux_window_divider` | `" "` | `window-status-separator` between windows. |
| `@themux_window_divider_color` | `#{@thm_overlay_0}` | Its color. |

Extra named dividers can be created from `utils/divider.conf` and used as a
token in a zone:

```sh
%hidden DIVIDER_NAME="dot"
set -g @themux_dot_text "·"
source -F "~/.config/tmux/plugins/themux/utils/divider.conf"
set -g @themux_status_line_1 "session dot application / windows / date_time"
```

---

### Windows — content & colors

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_window_text` | `" #W"` | Inactive window name (any tmux format). |
| `@themux_window_number` | `#I` | Inactive window index. |
| `@themux_window_current_text` | `" #W"` | Active window name. |
| `@themux_window_current_number` | `#I` | Active window index. |
| `@themux_window_number_color` | `#{@thm_overlay_2}` | Inactive number/accent color. |
| `@themux_window_text_color` | `#{@thm_surface_0}` | Inactive name-block background. |
| `@themux_window_current_number_color` | `#{@thm_mauve}` | Active number/accent color. |
| `@themux_window_current_text_color` | `#{@thm_surface_1}` | Active name-block background. |
| `@themux_window_number_position` | `left` | `left` \| `right` — number before or after the name. |

#### Window name visibility

| Option | Default | Values |
| --- | --- | --- |
| `@themux_window_text_mode` | `always` | `always` \| `never` \| `manual` |

- `always` — the name is always shown.
- `never` — only the number block (the name container is dropped).
- `manual` — the name shows only on windows you renamed by hand (tmux's
  `automatic-rename` is `off`); auto-named windows show just the number.

Setting `@themux_window_text ""` / `@themux_window_current_text ""` also drops
the container — handy for, e.g., number-only inactive windows with a named
active window.

#### Window flags

| Option | Default | Values |
| --- | --- | --- |
| `@themux_window_flags` | `none` | `none` \| `icon` \| `text` |

`icon` uses the nerd-font icons below; `text` uses tmux's `#F`.

| Option | Flag |
| --- | --- |
| `@themux_window_flags_icon_current` | active (`*`) |
| `@themux_window_flags_icon_last` | last (`-`) |
| `@themux_window_flags_icon_zoom` | zoomed (`Z`) |
| `@themux_window_flags_icon_mark` | marked (`M`) |
| `@themux_window_flags_icon_silent` | silence (`~`) |
| `@themux_window_flags_icon_activity` | activity (`#`) |
| `@themux_window_flags_icon_bell` | bell (`!`) |
| `@themux_window_flags_icon_format` | order/format of the icons above |

#### Window caps (block variants)

Override to keep a base variant but change the cap glyphs. Active windows reuse
the inactive caps unless their `_current_` form is set.

| Option | Effect |
| --- | --- |
| `@themux_window_left_border` / `_middle_separator` / `_right_border` | Inactive left cap / inner separator / right cap. |
| `@themux_window_current_left_border` / `_current_middle_separator` / `_current_right_border` | Active versions. |

#### Naked windows

The `naked` fill reuses the same `@themux_window_(current_)number_color` as the
block fills — no separate options.

---

### Panes (border label)

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_pane_status` | `off` | `off` \| `top` \| `bottom` — shows a styled label on each pane border. |
| `@themux_pane_color` | `#{@thm_green}` | Active pane accent (inactive dim to `overlay_0`). |
| `@themux_pane_background_color` | `#{@thm_surface_0}` | Pane label neutral background. |
| `@themux_pane_default_text` | `#{b:pane_current_path}` | Label text (any tmux format). |
| `@themux_pane_number_position` | `left` | `left` \| `right`. |
| `@themux_pane_border_style` | `fg=#{@thm_overlay_0}` | Inactive pane border style. |
| `@themux_pane_active_border_style` | lavender (mauve when synced) | Active pane border style. |
| `@themux_pane_left_border` / `_middle_separator` / `_right_border` | per variant | Cap glyphs (override like the window caps). |

---

### Status modules

Each module defines three options (and is referenced as `@themux_module_<name>`
in a layout zone). Built-in modules: `session`, `application`, `directory`,
`host`, `user`, `date_time`, `cpu`, `ram`, `load`, `uptime`, `gitmux`, `kube`,
`battery`, `weather`, `clima`, `pomodoro_plus`, `zoom`.

| Option | Effect |
| --- | --- |
| `@themux_<name>_icon` | The module's icon. |
| `@themux_<name>_color` | The module's accent color. |
| `@themux_<name>_text` | The module's text (any tmux format). |

Per-module overrides (advanced): `@themux_<name>_icon_fg` / `_icon_bg` /
`_text_fg` / `_text_bg` force a segment's colors (used by the `cpu`/`ram`
threshold modules, which also read tmux-cpu's `@cpu_*` / `@ram_*` colors).

Shared status options:

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_module_middle_separator` | `""` | Gap between a module's icon and text. |
| `@themux_module_connect_separator` | `no` | `yes` \| `no` — whether adjacent pills connect. |

### Menu & popups

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_menu_selected_style` | `fg=#{@thm_fg},bold,bg=#{@thm_overlay_0}` | Selected menu entry style (tmux ≥ 3.4). |

---

### Clean reloads

themux resets its own derived state automatically when it loads: on a running
server `themux.tmux` clears the palette, internals, the variant-set caps and the
status/window/pane formats *before* rebuilding — but never your `@themux_*`
config. So switching theme, variant or style is just a config reload.
