## Configuration Reference

<img src="../../assets/structure.svg" style="background: #eff1f5" />

This is a diagram of how the theme is split between its components.

### Top Level Options

| Option               | Effect                                                                         |
| -------------------- | ------------------------------------------------------------------------------ |
| `@themux_theme` | Selects the theme: `catppuccin_{latte,frappe,macchiato,mocha}` or `kanagawa_{wave,dragon,lotus}`. |

### Status Line

| Option                        | Effect                                        |
| ----------------------------- | --------------------------------------------- |
| @themux_status_background | Sets the background color of the status line. |

- `default` will use the color from the selected theme
- `none` will make the status bar transparent
- use hex color codes for other colors or a theme color (`#{@thm_<color>}`)

### Window

The plugin comes with three window styles built in, these can be customized by
setting the `@themux_windows_variant` option. The default is `squared`.

| Option    | Effect                                                                   | Preview                                                |
| --------- | ------------------------------------------------------------------------ | ------------------------------------------------------ |
| `basic`   | Simple styling with blocks.                                              | ![window basic](../../assets/window-basic.webp)           |
| `rounded` | Each window is separated with rounded separators.                        | ![window rounded style](../../assets/window-rounded.webp) |
| `slanted` | Each window is separated with slanted separators.                        | ![window slanted style](../../assets/window-slanted.webp) |
| `custom`  | Custom separators are used. This is required to override the separators! |                                                        |
| `none`    | Styling of the window status is completely disabled.                     | ![window no styling](../../assets/window-none.webp)       |

If you want to change the active color to something else (the default is mauve),
use the following. For example to use lavender:

```bash
set -g @themux_window_current_number_color "#{@thm_lavender}"
```

<details>

<summary>Customising the separators</summary>

Add the following,
setting whatever values you'd like for the separators:

```bash
set -g @themux_windows_variant "custom"
set -g @themux_window_left_separator ""
set -g @themux_window_middle_separator ""
set -g @themux_window_right_separator ""
```

</details>

### Menu

**Set the menu selected style:**

```sh
# Use a value compatible with the standard tmux `menu-selected-style`
set -g @themux_menu_selected_style "fg=#{@thm_surface_0},bg=#{@thm_yellow}"
```

### All options and their defaults

```bash
# Menu styling options
set -g @themux_menu_selected_style "fg=#{@thm_fg},bold,bg=#{@thm_overlay_0}"

# Pane styling options
set -g @themux_pane_status_enabled "no" # set to "yes" to enable
set -g @themux_pane_border_status "off" # set to "yes" to enable
set -g @themux_pane_border_style "fg=#{@thm_overlay_0}"
set -g @themux_pane_active_border_style "##{?pane_in_mode,fg=#{@thm_lavender},##{?pane_synchronized,fg=#{@thm_mauve},fg=#{@thm_lavender}}}"
set -g @themux_pane_left_separator "█"
set -g @themux_pane_middle_separator "█"
set -g @themux_pane_right_separator "█"
set -g @themux_pane_color "#{@thm_green}"
set -g @themux_pane_background_color "#{@thm_surface_0}"
set -g @themux_pane_default_text "##{b:pane_current_path}"
set -g @themux_pane_default_fill "number"
set -g @themux_pane_number_position "left" # right, left

set -g @themux_windows_variant "squared" # squared, rounded, slanted, flat, unstyled
set -g @themux_window_text_color "#{@thm_surface_0}"
set -g @themux_window_number_color "#{@thm_overlay_2}"
set -g @themux_window_text " #T"
set -g @themux_window_number "#I"
set -g @themux_window_current_text_color "#{@thm_surface_1}"
set -g @themux_window_current_number_color "#{@thm_mauve}"
set -g @themux_window_current_text " #T"
set -g @themux_window_current_number "#I"
set -g @themux_window_number_position "left"
set -g @themux_window_flags "none" # none, icon, or text
set -g @themux_window_flags_icon_last " 󰖰" # -
set -g @themux_window_flags_icon_current " 󰖯" # *
set -g @themux_window_flags_icon_zoom " 󰁌" # Z
set -g @themux_window_flags_icon_mark " 󰃀" # M
set -g @themux_window_flags_icon_silent " 󰂛" # ~
set -g @themux_window_flags_icon_activity " 󱅫" # #
set -g @themux_window_flags_icon_bell " 󰂞" # !
# Matches icon order when using `#F` (`#!~[*-]MZ`)
set -g @themux_window_flags_icon_format "##{?window_activity_flag,#{E:@themux_window_flags_icon_activity},}##{?window_bell_flag,#{E:@themux_window_flags_icon_bell},}##{?window_silence_flag,#{E:@themux_window_flags_icon_silent},}##{?window_active,#{E:@themux_window_flags_icon_current},}##{?window_last_flag,#{E:@themux_window_flags_icon_last},}##{?window_marked_flag,#{E:@themux_window_flags_icon_mark},}##{?window_zoomed_flag,#{E:@themux_window_flags_icon_zoom},} "

# Status line options
set -g @themux_status_left_separator ""
set -g @themux_status_middle_separator ""
set -g @themux_status_right_separator "█"
set -g @themux_status_connect_separator "yes" # yes, no
set -g @themux_status_fill "icon"
set -g @themux_status_module_bg_color "#{@thm_surface_0}"
```
