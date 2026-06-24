#!/usr/bin/env bash
# Regenerate every themux documentation image: theme/flavor strips, window-shape
# strips, named preset "looks", the component-anatomy strip and the preview hero.
#
# Each shot is a real themux render via VHS on an isolated tmux socket, cropped to
# the status bar. Requires: vhs, tmux, cwebp, ffmpeg, and the "IosevkaTerm Nerd
# Font" (the render font — pick any Nerd Font by editing FONT below).
#
# Usage: assets/generate.sh   (run from anywhere; writes into this repo's assets/)
set -euo pipefail

THEMUX="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$THEMUX/assets"
WORK="$(mktemp -d)"
SOCK="themuxgen"
FONT="IosevkaTerm Nerd Font"
trap 'tmux -L "$SOCK" kill-server 2>/dev/null || true; rm -rf "$WORK"' EXIT
cd "$WORK"

# render <name> <launch-command>  -> $ASSETS/<name>.webp (1800x58 status-bar strip)
render() {
  local name="$1" launch="$2"
  cat > "$WORK/$name.tape" <<EOF
Output "_throwaway.gif"
Require tmux
Set Shell "bash"
Set FontSize 28
Set FontFamily "$FONT"
Set Width 1800
Set Height 240
Set Padding 0
Hide
Type "export TMUX_PLUGIN_MANAGER_PATH=\$HOME/.config/tmux/plugins/" Enter
Type "clear" Enter
Type '$launch' Enter
Sleep 3s
Show
Sleep 1s
Screenshot "${name}_full.png"
Sleep 500ms
EOF
  tmux -L "$SOCK" kill-server 2>/dev/null || true
  vhs "$WORK/$name.tape" >/dev/null 2>&1
  tmux -L "$SOCK" kill-server 2>/dev/null || true
  cwebp -quiet -crop 0 182 1800 58 "$WORK/${name}_full.png" -o "$ASSETS/${name}.webp"
  echo "  -> assets/${name}.webp"
}

# one window named zsh / three windows editor·server·logs (logs active),
# automatic-rename off so window names stay deterministic
launch1() { echo "tmux -L $SOCK -f $1 new-session -d -s themux -n zsh && tmux -L $SOCK set-option -g automatic-rename off && tmux -L $SOCK attach -t themux"; }
launch3() { echo "tmux -L $SOCK -f $1 new-session -d -s themux -n editor && tmux -L $SOCK neww -t themux -n server && tmux -L $SOCK neww -t themux -n logs && tmux -L $SOCK set-option -g automatic-rename off && tmux -L $SOCK select-window -t themux:2 && tmux -L $SOCK attach -t themux"; }

conf() { printf '%s\n' "$@" "run \"$THEMUX/themux.tmux\"" > "$WORK/$CONF.conf"; }

echo "themes (one strip per flavor):"
for t in catppuccin_latte catppuccin_frappe catppuccin_macchiato catppuccin_mocha \
         kanagawa_wave kanagawa_dragon kanagawa_lotus \
         kanso_zen kanso_ink kanso_mist kanso_pearl; do
  CONF="$t"; conf \
    "set -g @themux_theme '$t'" \
    'set -g @themux_all_shape "rounded"' \
    'set -g @themux_window_name_mode "always"' \
    'set -g @themux_status_line_1 "windows / application cpu ram session uptime"'
  render "$t" "$(launch1 "$WORK/$t.conf")"
done

echo "window shapes (modules adopt the shape via @themux_all_shape):"
for s in squared rounded slanted powerline; do
  CONF="shape-$s"; conf \
    "set -g @themux_theme 'catppuccin_mocha'" \
    "set -g @themux_all_shape \"$s\"" \
    'set -g @themux_window_name_mode "always"' \
    'set -g @themux_status_line_1 "windows / application cpu ram"'
  render "shape-$s" "$(launch3 "$WORK/shape-$s.conf")"
done

echo "preset looks:"
CONF="look-catppuccin-classic"; conf \
  "set -g @themux_theme 'catppuccin_mocha'" \
  'set -g @themux_all_shape "rounded"' \
  'set -g @themux_module_leading_variant "solid"' \
  'set -g @themux_window_name_mode "always"' \
  'set -g @themux_status_line_1 "windows / application cpu ram session uptime"'
render "look-catppuccin-classic" "$(launch3 "$WORK/look-catppuccin-classic.conf")"

CONF="look-nvim"; conf \
  "set -g @themux_theme 'kanagawa_wave'" \
  'set -g @themux_all_shape "powerline"' \
  'set -g @themux_window_name_mode "always"' \
  'set -g @themux_status_line_1 "=session>application / windows / cpu<ram="'
render "look-nvim" "$(launch3 "$WORK/look-nvim.conf")"

CONF="look-minimal"; conf \
  "set -g @themux_theme 'catppuccin_mocha'" \
  'set -g @themux_all_shape "rounded"' \
  'set -g @themux_module_leading_variant "naked"' \
  'set -g @themux_module_text_variant "naked"' \
  'set -g @themux_window_leading_variant "naked"' \
  'set -g @themux_window_text_variant "naked"' \
  'set -g @themux_status_background "none"' \
  'set -g @themux_window_name_mode "always"' \
  'set -g @themux_status_line_1 "windows / application cpu ram session"'
render "look-minimal" "$(launch3 "$WORK/look-minimal.conf")"

CONF="look-slanted"; conf \
  "set -g @themux_theme 'kanso_zen'" \
  'set -g @themux_all_shape "slanted"' \
  'set -g @themux_window_name_mode "always"' \
  'set -g @themux_status_line_1 "windows / cpu ram date_time"'
render "look-slanted" "$(launch3 "$WORK/look-slanted.conf")"

echo "component anatomy (solid leading vs subtle text, notch on):"
CONF="structure-anatomy"; conf \
  "set -g @themux_theme 'catppuccin_mocha'" \
  'set -g @themux_all_shape "rounded"' \
  'set -g @themux_session_leading_variant "solid"' \
  'set -g @themux_session_text_variant "subtle"' \
  'set -g @themux_all_notch "on"' \
  'set -g @themux_window_name_mode "always"' \
  'set -g @themux_status_line_1 "session windows"'
render "structure-anatomy" "$(launch1 "$WORK/structure-anatomy.conf")"

echo "custom append demo (flamingo memory pill, macOS memory_pressure):"
# NOTE: -g (not -gF) so #{@thm_flamingo} resolves at draw time, after the palette exists
CONF="ram-example"; conf \
  "set -g @themux_theme 'catppuccin_mocha'" \
  'set -g @themux_all_shape "rounded"' \
  'set -g @themux_window_name_mode "always"' \
  'set -g @themux_status_line_1 "windows"' \
  'set -g status-interval 2' \
  "set -g @themux_status_line_1_append \"#[bg=#{@thm_flamingo},fg=#{@thm_crust}] 󱀙 #(memory_pressure | awk '/percentage/{print \$5}') \""
render "ram-example" "$(launch1 "$WORK/ram-example.conf")"

echo "preview hero (vstack of the four catppuccin strips):"
ffmpeg -y -loglevel error \
  -i "$ASSETS/catppuccin_latte.webp"     -i "$ASSETS/catppuccin_frappe.webp" \
  -i "$ASSETS/catppuccin_macchiato.webp" -i "$ASSETS/catppuccin_mocha.webp" \
  -filter_complex "[0][1][2][3]vstack=inputs=4" "$WORK/preview.png"
cwebp -quiet "$WORK/preview.png" -o "$ASSETS/preview.webp"
echo "  -> assets/preview.webp"

echo "done."
