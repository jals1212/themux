## Design Philosophy

themux is a multi-theme, themeable UI layer for the tmux status line. It began
as a fork of [catppuccin/tmux] and keeps that project's core idea — a palette
exposed as plain tmux options — but deliberately takes a different stance on
configurability. Where the upstream doc below argued for *fewer* options,
themux argues for a *small set of orthogonal* ones plus curated presets.

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
**orthogonal**: each UI item (status modules, the window list, panes) selects a
*variant* from the same small, shared vocabulary.

| Variant    | Meaning                                                       |
| ---------- | ------------------------------------------------------------ |
| `squared`  | Solid block with full-block edges.                           |
| `rounded`  | Solid block with rounded caps.                               |
| `slanted`  | Solid block with slanted caps.                               |
| `flat`     | Transparent text on the bar; no block background.            |
| `unstyled` | themux leaves the item alone so you can build it by hand.    |

The variants are orthogonal: `@themux_status_variant`, `@themux_windows_variant`
and `@themux_panes_variant` are chosen independently, and any combination is
valid. New looks are added by dropping a file under `variants/`, not by adding
a flag that interacts with every other flag.

`unstyled` is the escape hatch: it makes the law of orthogonality hold even at
the edges. Anything themux's variants do not cover, you build yourself with the
exposed palette, and themux stays out of the way.

### Presets are defaults, not features

A preset is a named bundle of the options above — a curated starting point, not
a new mechanism. `@themux_preset` selects a `presets/<name>.conf` that sets
variant choices and a status-line composition using the same options a user
would. Presets are applied with non-destructive defaults, so any option you set
yourself still wins. This keeps the "smart defaults" benefit (a good look from
one line) without hiding the knobs underneath.

### Build for composition

tmux is a text-based program and its options are a universal interface. themux
leans into that: modules, separators and the palette are all just strings you
can read, pipe and recombine. Reset (`themux_reset.conf`) makes re-sourcing
idempotent, so iterating on a config never requires killing the server.
