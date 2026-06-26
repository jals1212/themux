## Using the theme's built-in status modules

themux composes the whole status line from the row grammar in
`@themux_status_line_1` … `_5` — it owns tmux's `status-format`, so `status-left`
and `status-right` are not used. A module is simply its **name** as a token in a
row; list the names you want and themux renders the pills.

To put the `application` and `session` modules on the right with the window list on
the left:

```sh
set -g @themux_status_line_1 "windows / application session"
```

`/` splits a row into zones (`<left> / windows / <right>`); within a zone a space
leaves each module its own pill, `|` adds a divider, and `=` `>` `<` merge modules
into one capped group. Set `@themux_status_line_*` **before** `run`-ing themux. See
the [Configuration reference](./configuration.md) and the README for the full
status-line grammar.

A module that pulls live data from a tmux plugin (cpu, ram, …) needs that plugin
installed; the per-module sections below note which. With TPM that is automatic —
themux finds the plugin through `TMUX_PLUGIN_MANAGER_PATH`.

## Customizing modules

Every module supports the following overrides:

### Override the specific module icon

```sh
set -g @themux_[module_name]_icon "<glyph> "
```

The icon value carries the glyph plus its own per-glyph nudge — the shipped icons
are `"<glyph> "`. Nerd-font glyphs sit off-centre in their cell by different
amounts, so tune the spaces per icon to compensate (e.g. `"<glyph> "` keeps it
flush-left, `" <glyph>"` nudges it right). The badge's overall tightness is a
separate, cascading prop — see `@themux_<item>_padding` in the
[Configuration reference](./configuration.md).

### Override the specific module color

```sh
set -g @themux_[module_name]_color "color"
```

### Override the specific module text

```sh
set -g @themux_[module_name]_text "text"
```

### Override the specific module's background color

```sh
set -g @themux_module_[module_name]_bg_color "#{@thm_surface_0}"
```

### Removing a specific module option

```sh
set -g @themux_[module_name]_[option] ""
```

This is for the situation where you want to remove the icon from a module.
For example:

```sh
set -g @themux_date_time_icon ""
```

### Notes for TPM users

Set your `@themux_status_line_*` rows (and any other `@themux_*` options) **before**
TPM runs — TPM loads themux, which reads them when it builds the status line. A
module that depends on a tmux plugin only needs that plugin listed: TPM exports
`TMUX_PLUGIN_MANAGER_PATH`, so themux can find it and resolve the module's live data.

```bash
set -g @themux_theme "catppuccin_mocha"
set -g @themux_status_line_1 "windows / application cpu session"

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-cpu'   # needed by the cpu module
set -g @plugin 'jals1212/themux'

run '~/.config/tmux/plugins/tpm/tpm'
```

## Battery module

**Requirements:** This module depends on [tmux-battery](https://github.com/tmux-plugins/tmux-battery/tree/master).

**Install:** The preferred way to install tmux-battery is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
set -g @themux_status_line_1 "windows / battery"

set -g @plugin 'tmux-plugins/tmux-battery'
run '~/.config/tmux/plugins/tpm/tpm'
```

## CPU module

**Requirements:** This module depends on [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu/tree/master).

**Install:** The preferred way to install tmux-cpu is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
set -g @themux_status_line_1 "windows / cpu"

set -g @plugin 'tmux-plugins/tmux-cpu'
run '~/.config/tmux/plugins/tpm/tpm'
```

**Level colours:** cpu and ram escalate through three colours as the value climbs
— `low` (default green), `medium` (yellow), `high` (red). Recolour a single level
with `@themux_<name>_{low,medium,high}_color`, taking a palette token or a literal
hex. Each defaults to its slot and still tracks a theme switch.

```sh
set -g @themux_cpu_high_color "#{@thm_peach}"  # cpu, high level → palette slot
set -g @themux_ram_low_color  "#5e857a"         # ram, low level  → literal hex
```

## RAM module

**Requirements:** This module depends on [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu/tree/master).

**Install:** The preferred way to install tmux-cpu is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
set -g @themux_status_line_1 "windows / ram"

set -g @plugin 'tmux-plugins/tmux-cpu'
run '~/.config/tmux/plugins/tpm/tpm'
```

Per-level colours work the same as the [CPU module](#cpu-module) — override with
`@themux_ram_{low,medium,high}_color`.

## Weather modules

### tmux-weather

**Requirements:** This module depends on [tmux-weather](https://github.com/xamut/tmux-weather).

**Install:** The preferred way to install tmux-weather is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
set -g @themux_status_line_1 "windows / weather"

set -g @plugin 'xamut/tmux-weather'
run '~/.config/tmux/plugins/tpm/tpm'
```

### tmux-clima

**Requirements:** This module depends on [tmux-clima](https://github.com/vascomfnunes/tmux-clima).

**Install:** The preferred way to install tmux-clima is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
set -g @themux_status_line_1 "windows / clima"

set -g @plugin 'vascomfnunes/tmux-clima'
run '~/.config/tmux/plugins/tpm/tpm'
```

## Load module

**Configure:**

```sh
set -g @themux_status_line_1 "windows / load"
```

## Gitmux module

**Requirements:** This module depends on [gitmux](https://github.com/arl/gitmux).

**Install:** To install gitmux, follow the instructions in the [gitmux documentation](https://github.com/arl/gitmux/blob/main/README.md#installing).

**Configure:**

Add the gitmux module to the status modules list.

```sh
set -g @themux_status_line_1 "windows / gitmux"
```

Follow the instructions in the [gitmux documentation](https://github.com/arl/gitmux/blob/main/README.md#customizing)
to create a gitmux config file. The gitmux plugin expects a file to be present
at `~/.gitmux.conf`.

Add the following to your `~/.gitmux.conf` so that it uses the theme's colors:

```yaml
tmux:
  styles:
    clear: "#[fg=#{@thm_fg}]"
    state: "#[fg=#{@thm_red},bold]"
    branch: "#[fg=#{@thm_fg},bold]"
    remote: "#[fg=#{@thm_teal}]"
    divergence: "#[fg=#{@thm_fg}]"
    staged: "#[fg=#{@thm_green},bold]"
    conflict: "#[fg=#{@thm_red},bold]"
    modified: "#[fg=#{@thm_yellow},bold]"
    untracked: "#[fg=#{@thm_mauve},bold]"
    stashed: "#[fg=#{@thm_blue},bold]"
    clean: "#[fg=#{@thm_rosewater},bold]"
    insertions: "#[fg=#{@thm_green}]"
    deletions: "#[fg=#{@thm_red}]"
```

## Pomodoro module

**Requirements:**: This module depends on [tmux-pomodoro-plus](https://github.com/olimorris/tmux-pomodoro-plus/tree/main).

**Install:**: The preferred way to install tmux-pomodoro-plus is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
set -g @themux_status_line_1 "windows / pomodoro_plus"

set -g @plugin 'olimorris/tmux-pomodoro-plus'
run '~/.config/tmux/plugins/tpm/tpm'
```

## Kube module

**Requirements:** This module depends on [tmux-kubectx](https://github.com/tony-sol/tmux-kubectx).

**Install:** The preferred way to install tmux-kubectx is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
set -g @themux_kube_context_color "#{@thm_red}"
set -g @themux_kube_namespace_color "#{@thm_sky}"

set -g @themux_status_line_1 "windows / kube"

set -g @plugin 'tony-sol/tmux-kubectx'
run '~/.config/tmux/plugins/tpm/tpm'
```
