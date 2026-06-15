## Design Philosophy

themux is a multi-theme, themeable UI layer for the tmux status line. It began
as a fork of [catppuccin/tmux] and keeps that project's core idea — a palette
exposed as plain tmux options — but deliberately takes a different stance on
configurability. Where the upstream doc below argued for *fewer* options,
themux argues for a *small set of orthogonal* ones you compose yourself.

[catppuccin/tmux]: https://github.com/catppuccin/tmux

### A palette first

A theme is, first and foremost, a palette. Every theme under `themes/` defines
the same `@thm_*` colors, and everything else is expressed in terms of them. A
theme switch is just a different palette; pick one with `@themux_theme`.

Because the palette is plain tmux options, it composes with any other tmux
configuration: `#{@thm_blue}` works in your own `status-left`, a custom module,
or anywhere a format string is accepted.

### Orthogonal variants over endless options

The historical failure mode of a status-line plugin is an explosion of
inter-dependent options where specific combinations break. themux avoids that
not by removing configurability but by keeping the configurable surface
**orthogonal**: each UI item (status modules, the window list, panes) is named
by one *variant* string — `"<shape> [fill] [notch]"` — whose tokens are drawn
from the same small, shared vocabulary.

| Axis | Tokens | Meaning |
| --- | --- | --- |
| **shape** | `squared` / `rounded` / `slanted` | Solid block with full / rounded / slanted caps. |
| | `unstyled` | themux leaves the item alone so you can build it by hand. |
| **fill** | `icon` / `fill` / `none` | The icon only / the whole badge / nothing takes the accent. |
| | `naked` | Transparent text on the bar; only the active window/pane is a block. |
| **notch** | `notch` | The icon↔text seam inherits the shape's cap. |

The axes are orthogonal: `@themux_module_variant`, `@themux_window_variant` and
`@themux_pane_variant` are chosen independently, and within each the shape, fill
and notch combine freely — any combination is valid. New shapes are added by
dropping a file under `variants/`, not by adding a flag that interacts with
every other flag.

`unstyled` is the escape hatch: it makes the law of orthogonality hold even at
the edges. Anything themux's variants do not cover, you build yourself with the
exposed palette, and themux stays out of the way.

### Build for composition

tmux is a text-based program and its options are a universal interface. themux
leans into that: each UI item is a component, and you compose the bar yourself
from a declarative per-line layout (`@themux_status_line_1..5`, each a
`left / centre / right` of module tokens or the `windows` list) — there are no
opaque presets hiding the knobs. Modules, dividers and the palette are all just
strings you can read, pipe and recombine.
An internal reset (in `themux.tmux`) makes re-sourcing idempotent, so iterating on a
config never requires killing the server.
