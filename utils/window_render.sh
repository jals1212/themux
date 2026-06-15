#!/usr/bin/env bash
# Assemble window-status-format and window-status-current-format from the per-side
# style vars computed in utils/window_block.conf.
#
# This replaces the in-config format assembly, whose tmux two-stage expansion was
# the debt: draw-time refs had to be written as "##{?##{E:...}}" (counting set-time
# vs draw-time "#" levels), and the inactive and current blocks duplicated the
# whole structure. In shell the two stages separate cleanly:
#   load-time -> resolved now via a single `tmux set -F` pass, captured as a string
#   draw-time -> emitted literally as #{...} (no ## doubling) for tmux to resolve
#                per window
# and inactive/current collapse to one function called twice. The produced option
# values are byte-identical to the previous assembly.

# Expand $1 through a single tmux format pass (the load-time stage).
expand() {
  tmux set -gF @_tmx_render_tmp "$1"
  tmux show -gv @_tmx_render_tmp
}

position=$(tmux show -gqv @themux_window_number_position)
# @_tmx_w_flags is shared by both sides and unset once the formats are built.
flags=$(expand "#{@_tmx_w_flags}")

# Render one window side's format. $1: var prefix (w|cw); $2: option infix
# (""|current_). The name container only appears when the side has text.
render_side() {
  local p="$1" o="$2"
  local number_style left mid number right has_text text_style

  number_style=$(expand "#{E:@_tmx_${p}_number_style}")
  left=$(expand "#{E:@themux_window_${o}left_border}")
  number=$(expand "#{@themux_window_${o}number}")
  right="#{E:@themux_window_${o}right_border}"
  # Parse-time flag from window_block.conf (see its note on #W timing).
  has_text=$(tmux show -gqv "@_tmx_${p}_has_text")
  text_style="#{E:@_tmx_${p}_text_style}"

  if [ "$position" = "left" ]; then
    # number block (with a right pad so the index stays centred whether or not a
    # name follows), then the name container — itself right-padded (on the text
    # bg) so the name block is symmetric — only when the window has text.
    printf '%s%s%s #{?#{E:@_tmx_%s_text},#{E:@_tmx_%s_namepart} ,}%s%s' \
      "$number_style" "$left" "$number" "$p" "$p" "$flags" "$right"
  elif [ "$has_text" = 1 ]; then
    # number on the right: name block first, number block after the separator.
    mid=$(expand "#{E:@themux_window_${o}middle_separator}")
    printf '%s%s%s#{E:@_tmx_%s_text}%s%s%s %s%s' \
      "$text_style" "$left" "$text_style" "$p" "$flags" "$mid" "$number_style" "$number" "$right"
  else
    # number on the right, but no text: just the number block.
    printf '%s%s%s%s%s' "$number_style" "$left" "$number" "$flags" "$right"
  fi
}

tmux set -g window-status-format "$(render_side w "")"
tmux set -g window-status-current-format "$(render_side cw current_)"

tmux set -gu @_tmx_render_tmp
tmux set -ug @_tmx_w_flags
tmux set -gu @_tmx_w_has_text
tmux set -gu @_tmx_cw_has_text
exit 0
