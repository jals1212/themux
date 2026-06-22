## Using the theme's built-in status modules

To use the theme's built in status modules, set the `status-left` and
`status-right` tmux options _after_ the plugin has been loaded with `run`.

The tmux status line modules are set as variables and prefixed with `@themux_module_<module>`.

To use the `application` and `session` modules on the right and have nothing on
the left:

```sh
set -g status-right-length 100

set -g status-right "#{E:@themux_module_application}#{E:@themux_module_session}"
set -g status-left ""
```
Some notes about expanding options when setting the status line:
* Options are expanded as format strings by placing `E:` before the option name.
* When a module status string contains a reference to another variable, you have to add the `-F` flag that treats the value passed as a format string that is immediately expanded, that is use `set -gF` (see tmux [`set-option`](https://man.openbsd.org/OpenBSD-current/man1/tmux.1#set-option) man page).
* Example for such a case is the [battery](#battery-module) module below, where the status contains the format string `#{battery_percentage}` that needs to be further expanded.

## Customizing modules

Every module supports the following overrides:

### Override the specific module icon

```sh
set -g @themux_[module_name]_icon " <glyph> "
```

The icon value carries its **own** padding — the shipped icons are `" <glyph> "`
(a leading and a trailing space) for the default footprint. Tune those spaces per
icon to nudge a glyph: nerd-font glyphs sit off-centre in their cell by different
amounts, so no single rule places them all (e.g. `"<glyph> "` pulls it to the
left cap, `" <glyph>  "` gives it more room on the right). An override with no
leading space sits flush against the left cap.

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

Make sure you load themux prior to setting the status-left and/or
status-* options. This ensures the themux options (such as colors and
status modules) are defined so they can then be used.

After status-left and/or status-right have been set, make sure to run TPM to load
the modules. This runs any plugins that may replace text in the status line.

```bash
# load themux ...
run '~/.config/tmux/plugins/themux/themux.tmux' # or where this file is located on your machine

# ... and then set status-left & status-right ...
set -g status-left "#{E:@themux_module_session}"

set -g status-right "#{E:@themux_module_[module_name]}"
set -ag status-right "#{E:@themux_module_[module_name]}"
set -agF status-right "#{E:@themux_module_[module_name]}"

# ... and finally start TPM
set -g @plugin 'tmux-plugins/tpm'
run '~/.tmux/plugins/tpm/tpm'
```

## Battery module

**Requirements:** This module depends on [tmux-battery](https://github.com/tmux-plugins/tmux-battery/tree/master).

**Install:** The preferred way to install tmux-battery is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{E:@themux_module_battery}"

set -g @plugin 'tmux-plugins/tmux-battery'
run '~/.tmux/plugins/tpm/tpm'
```

## CPU module

**Requirements:** This module depends on [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu/tree/master).

**Install:** The preferred way to install tmux-cpu is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{E:@themux_module_cpu}"

set -g @plugin 'tmux-plugins/tmux-cpu'
run '~/.tmux/plugins/tpm/tpm'
```

## RAM module

**Requirements:** This module depends on [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu/tree/master).

**Install:** The preferred way to install tmux-cpu is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{E:@themux_module_ram}"

set -g @plugin 'tmux-plugins/tmux-cpu'
run '~/.tmux/plugins/tpm/tpm'
```

## Weather modules

### tmux-weather

**Requirements:** This module depends on [tmux-weather](https://github.com/xamut/tmux-weather).

**Install:** The preferred way to install tmux-weather is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{E:@themux_module_weather}"

set -g @plugin 'xamut/tmux-weather'
run '~/.tmux/plugins/tpm/tpm'
```

### tmux-clima

**Requirements:** This module depends on [tmux-clima](https://github.com/vascomfnunes/tmux-clima).

**Install:** The preferred way to install tmux-clima is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{E:@themux_module_clima}"

set -g @plugin 'vascomfnunes/tmux-clima'
run '~/.tmux/plugins/tpm/tpm'
```

## Load module

**Configure:**

```sh
run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{E:@themux_module_load}"
```

## Gitmux module

**Requirements:** This module depends on [gitmux](https://github.com/arl/gitmux).

**Install:** To install gitmux, follow the instructions in the [gitmux documentation](https://github.com/arl/gitmux/blob/main/README.md#installing).

**Configure:**

Add the gitmux module to the status modules list.

```sh
run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{@themux_module_gitmux}"
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
run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{E:@themux_module_pomodoro_plus}"

set -g @plugin 'olimorris/tmux-pomodoro-plus'
run '~/.tmux/plugins/tpm/tpm'
```

## Kube module

**Requirements:** This module depends on [tmux-kubectx](https://github.com/tony-sol/tmux-kubectx).

**Install:** The preferred way to install tmux-kubectx is using [TPM](https://github.com/tmux-plugins/tpm).

**Configure:**

```sh
set -g @themux_kube_context_color "#{@thm_red}"
set -g @themux_kube_namespace_color "#{@thm_sky}"

run ~/.config/tmux/plugins/themux/themux.tmux

set -agF status-right "#{E:@themux_module_kube}"

set -g @plugin 'tony-sol/tmux-kubectx'
run '~/.tmux/plugins/tpm/tpm'
```
