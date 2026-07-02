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
configuration: `#{@thm_blue}` works in a status-line append, a custom module,
or anywhere a format string is accepted.

### Orthogonal props over endless options

The historical failure mode of a status-line plugin is an explosion of
inter-dependent options where specific combinations break. themux avoids that
not by removing configurability but by keeping the configurable surface
**orthogonal**: each UI item (status modules, the window list, panes) is a
*component* with a handful of independent props, drawn from one small, shared
vocabulary.

| Prop | Values | Meaning |
| --- | --- | --- |
| **shape** | `squared` / `rounded` / `slanted` / `powerline` | Block with square / round / slant / arrow (powerline chevron) caps. |
| | `unstyled` | themux leaves the item alone so you can build it by hand. |
| **leading** / **text** | `solid` / `soft` / `subtle` / `naked` | The icon-or-number block and the text block each pick a style: accent block / grey block / grey block with accent text / transparent. |
| **notch** | `off` / `>` / `<` / `auto` (`on` alias) | The leading↔text seam direction; `auto` resolves one per placement. |

The props are orthogonal: each item's `shape`, `leading`, `text` and `notch`
are chosen independently, and any combination is valid — a colored chip with a
transparent label, a rounded outline capsule, a plain grey pill. A common
renderer resolves the two block styles, so a new shape is a few cap glyphs, not
a flag that interacts with every other flag.

One prop bends this locality rule: `notch auto` is the only one whose resolved
value depends on where the item sits (its status-line zone, or a pane's
`leading_position`) rather than solely on the item's own options.

`unstyled` is the escape hatch: it makes the law of orthogonality hold even at
the edges. Anything themux's props do not cover, you build yourself with the
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
