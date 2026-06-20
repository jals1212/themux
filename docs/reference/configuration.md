## Configuration Reference

<img src="../../assets/structure.svg" style="background: #eff1f5" />

Every option is a tmux user option (`@themux_*`). Set them **before the plugin
loads** unless noted. Colors accept a hex code (`#ff0000`) or a palette token
(`#{@thm_<name>}`, e.g. `#{@thm_mauve}`). themux re-derives its state on every
load, so changing an option and reloading is enough — no `kill-server`.

The three UI items — **status modules**, **windows**, **panes** — are each a
*component* styled through a few independent props: a **shape**, an
**indicator** style, a **text** style, and a **notch** flag.

---

### Theme

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_theme` | `catppuccin_mocha` | Palette: `catppuccin_{latte,frappe,macchiato,mocha}`, `kanagawa_{wave,dragon,lotus}`, or `kanso_{zen,ink,mist,pearl}`. Loads `themes/<theme>.palette` (or a legacy `_tmux.conf`), which exposes the `@thm_*` colors. |

### Component props — per item

Each item is styled by independent props, so any combination is valid: the
shape draws the border/caps, the indicator (icon/number) and text blocks each
pick a style on their own, and notch shapes the seam between them.

```sh
set -g @themux_module_shape     "rounded"
set -g @themux_module_indicator "solid"
set -g @themux_module_text      "naked"  # colored icon chip, transparent label
set -g @themux_module_notch     "off"
```

| Prop | Values | Default |
| --- | --- | --- |
| `@themux_<item>_shape` | `squared` · `rounded` · `slanted` · `powerline` · `unstyled` | `squared` |
| `@themux_<item>_indicator` | `solid` · `soft` · `subtle` · `naked` | `solid` |
| `@themux_<item>_text` † | `solid` · `soft` · `subtle` · `naked` | `soft` |
| `@themux_<item>_notch` | `on` · `off` | `off` |
| `@themux_<item>_indicator_position` | `left` · `right` | `left` |
| `@themux_<item>_indicator_highlight` | `off` · `bg` · `fg` · `both` | `both` |
| `@themux_<item>_text_highlight` | `off` · `bg` · `fg` · `both` | `both` |

`<item>` is `module`, `window`, or `pane`. † The text-block **style** prop is
`@themux_<item>_text` for all three; on windows the name *content* lives in
`@themux_window_name` / `@themux_window_current_name`.

These per-item props default from a shared `@themux_all_<prop>`: set
`@themux_all_shape "rounded"` to shape every item at once; a per-item value
(e.g. `@themux_window_shape`) overrides it for that item. Precedence: per-item >
`@themux_all_*` > built-in. Cascadable props: `shape`, `indicator`, `text`,
`notch`, `indicator_position`, `indicator_highlight`, `text_highlight`.

`*_indicator_highlight` / `*_text_highlight` choose which channels take the
item's *highlight* color — for windows/panes that is the active item, for
modules the alert state (cpu/ram threshold, session prefix).

**shape** — `squared` / `rounded` / `slanted` / `powerline` are blocks with
square / round / slant / arrow (`  `, the classic powerline/lualine chevron)
caps; `unstyled` makes themux leave the item alone so you build it by hand with
the `@thm_*` palette.

**indicator / text** — the icon-or-number block and the text block each take a
style:

| Style | Background | Text |
| --- | --- | --- |
| `solid` | accent | crust — a solid colored block |
| `soft` | surface (grey) | normal |
| `subtle` | surface (grey) | accent |
| `naked` | transparent | accent — no block |

A `naked` block keeps the shape's caps as an outline, so a `rounded` indicator +
`naked` text reads as a capsule. Pair naked styles with
`@themux_status_background "none"` for a fully bare bar.

**notch** — `on` makes the indicator↔text seam inherit the shape's cap (the
indicator color tapering into the text background) instead of a flat boundary;
it collapses to nothing when the two blocks share a background.

For windows and panes, each part has a base and a highlight (active) color, and
`@themux_<item>_<part>_highlight` (`off`\|`bg`\|`fg`\|`both`) picks which channels
switch on the active item (windows → `@themux_window_indicator_color` /
`@themux_window_indicator_highlight_color`, panes → `@themux_pane_indicator_color`
/ `@themux_pane_indicator_highlight_color`, and the matching `_text_` pair).

> **Migration** from the old `@themux_<item>_variant` / `_fill` options (both
> removed): map the old fill to the new pair — `icon` → indicator `solid` + text
> `soft`, `fill` → both `solid`, `none` → both `soft`, `naked` → both `naked`.

### Status line background

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_status_background` | `default` | `default` (theme color), `none` (transparent), or any hex / `#{@thm_*}`. |
| `@themux_module_flush_edges` | `off` | `off` · `left` · `right` · `both` — flush the edge **module group** (drop its outer cap so the block fills to the terminal border). Capped shapes only. |
| `@themux_window_flush_edges` | `off` | `off` · `left` · `right` · `both` — same, for the edge **window ribbon** (independent of the module flush). Needs a connected ribbon (`@themux_window_seam` ≠ `\|`). |

---

### Status layout

The bar is built from up to five rows. Each is `"<left> / <center> / <right>"`;
a zone is a module list (token `NAME` → the `@themux_module_NAME` segment) or the
special token `windows`. Blank zones render nothing; the number of non-empty rows
sets how many status lines show.

The character between two modules sets how they join:

| Connector | Result |
| --- | --- |
| space | separate pills, each with its own caps |
| `=` | one merged pill, flat (squared) seam |
| `>` | merged, seam points right (left module into right) |
| `<` | merged, seam points left (right module into left) |
| `\|` | separate pills + the modules divider |

`=`/`>`/`<` build one capped **group** (a space or `|` breaks it) and need a
capped shape — `rounded`, `slanted` or `powerline`. With `squared`/`unstyled`
they collapse to a plain space.

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_status_line_1` | `" / windows / "` | First row. |
| `@themux_status_line_2` … `_5` | `""` | Extra rows (blank = unused). |
| `@themux_status_line_<N>_prepend` / `_append` | _(unset)_ | Arbitrary content (text, emoji, `#{...}`, `#[styles]`) pinned to row N's far left / far right — e.g. padding. A prepend cancels that row's left `*_flush_edges`; an append cancels the right. |

```sh
set -g @themux_status_line_1 "session>application / windows / gitmux<cpu<ram"
set -g @themux_status_line_2 " / windows / "   # windows on their own row
```

### Dividers

The divider between **status modules** and the one between **windows** are
independent.

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_module_divider` | `" "` | Text the `|` inserts between modules (includes its own padding). |
| `@themux_module_divider_color` | `#{@thm_overlay_0}` | Its color. |
| `@themux_window_seam` | `\|` | How windows meet (symbols, like the module connectors): `\|` separate pills · `<>` raised ribbon · `>` / `<` directional ribbon · `=` flat ribbon. Any but `\|` connects the list (capped shape + left numbers). |
| `@themux_window_divider` | `" "` | Separator between windows, used in the `\|` (separate) case. |
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
| `@themux_window_name` | `" #W"` | Inactive window name content (any tmux format). |
| `@themux_window_number` | `#I` | Inactive window index. |
| `@themux_window_current_name` | `" #W"` | Active window name content. |
| `@themux_window_current_number` | `#I` | Active window index. |
| `@themux_window_indicator_color` | `#{@thm_overlay_2}` | Base (inactive) number accent. |
| `@themux_window_indicator_highlight_color` | `#{@thm_mauve}` | Active number accent. |
| `@themux_window_text_color` | `#{@thm_overlay_2}` | Base (inactive) name accent. |
| `@themux_window_text_highlight_color` | `#{@thm_mauve}` | Active name accent. |
| `@themux_window_background_color` | `#{@thm_surface_0}` | Shared neutral fill for `soft`/`subtle` blocks. |
| `@themux_window_indicator_highlight` | `both` | `off` \| `bg` \| `fg` \| `both` — which channels of the number block switch to the active color. |
| `@themux_window_text_highlight` | `both` | `off` \| `bg` \| `fg` \| `both` — same, for the name block. |
| `@themux_window_indicator_position` | `left` | `left` \| `right` — number before or after the name. |

#### Window name visibility

| Option | Default | Values |
| --- | --- | --- |
| `@themux_window_name_mode` | `always` | `always` \| `never` \| `manual` |

- `always` — the name is always shown.
- `never` — only the number block (the name container is dropped).
- `manual` — the name shows only on windows you renamed by hand (tmux's
  `automatic-rename` is `off`); auto-named windows show just the number.

Setting `@themux_window_name ""` / `@themux_window_current_name ""` also drops
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

#### Window colors

The window caps follow the shape (`@themux_window_shape`); they are drawn from
the block colors, so there are no separate cap-glyph options. Each part has its
own accent with a base and a highlight (active) colour: the number block uses
`@themux_window_indicator_color` / `@themux_window_indicator_highlight_color`,
the name block `@themux_window_text_color` / `@themux_window_text_highlight_color`.
`soft`/`subtle` blocks fill from the shared `@themux_window_background_color`
instead of the accent. `@themux_window_indicator_highlight` and
`@themux_window_text_highlight` (`off` \| `bg` \| `fg` \| `both`) pick which
channels actually switch to the active color. This mirrors panes exactly.

---

### Panes (border label)

| Option | Default | Effect |
| --- | --- | --- |
| `@themux_pane_status` | `off` | `off` \| `top` \| `bottom` — shows a styled label on each pane border. |
| `@themux_pane_indicator_color` | `#{@thm_overlay_0}` | Inactive pane number/accent color. |
| `@themux_pane_indicator_highlight_color` | `#{@thm_green}` | Active pane number/accent color. |
| `@themux_pane_text_color` | `#{@thm_overlay_0}` | Inactive pane label accent. |
| `@themux_pane_text_highlight_color` | `#{@thm_green}` | Active pane label accent. |
| `@themux_pane_indicator_highlight` | `both` | `off` \| `bg` \| `fg` \| `both` — which channels of the number block switch on the active pane. |
| `@themux_pane_text_highlight` | `both` | `off` \| `bg` \| `fg` \| `both` — same, for the label block. |
| `@themux_pane_background_color` | `#{@thm_surface_0}` | Pane label neutral background. |
| `@themux_pane_default_text` | `#{b:pane_current_path}` | Label text (any tmux format). |
| `@themux_pane_indicator_position` | `left` | `left` \| `right`. |
| `@themux_pane_border_style` | `fg=#{@thm_overlay_0}` | Inactive pane border style. |
| `@themux_pane_active_border_style` | lavender (mauve when synced) | Active pane border style. |

---

### Status modules

Each module defines three options (and is referenced as `@themux_module_<name>`
in a layout zone). Built-in modules: `session`, `application`, `directory`,
`host`, `user`, `date_time`, `time`, `cpu`, `ram`, `load`, `uptime`, `gitmux`, `kube`,
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
server `themux.tmux` clears the palette, internals, the derived caps and the
status/window/pane formats *before* rebuilding — but never your `@themux_*`
config. So switching theme or style is just a config reload.
