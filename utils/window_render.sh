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
fill=$(tmux show -gqv @_tmx_window_fill)
notch=$(tmux show -gqv @_tmx_window_notch)
shape=$(tmux show -gqv @_tmx_window_shape)
# The notch seam glyph mirrors the shape's right cap (octal UTF-8 so it does not
# depend on printf's \u support): slanted  E0BC, rounded  E0B4, squared █ block.
seam_glyph=""
[ "$notch" = yes ] && case "$shape" in
  slanted) seam_glyph=$(printf '\356\202\274') ;;
  rounded) seam_glyph=$(printf '\356\202\264') ;;
  squared) seam_glyph=$(printf '\342\226\210') ;;
esac

# @_tmx_w_flags is shared by both sides and unset once the formats are built.
flags=$(expand "#{@_tmx_w_flags}")

# Render one window side's format. $1: var prefix (w|cw); $2: option infix
# (""|current_). The name container only appears when the side has text.
render_side() {
  local p="$1" o="$2"
  local number_style left mid number right text text_style
  number=$(expand "#{@themux_window_${o}number}")

  if [ "$fill" = naked ] && [ "$p" = w ]; then
    # naked inactive: accent text on the transparent bar, no caps or block.
    printf '#[fg=%s,bg=default] %s#{E:@_tmx_w_text}%s ' \
      "$(expand "#{E:@themux_window_number_color}")" "$number" "$flags"
    return
  fi

  number_style=$(expand "#{E:@_tmx_${p}_number_style}")
  left=$(expand "#{E:@themux_window_${o}left_border}")
  right="#{E:@themux_window_${o}right_border}"
  # Text is configured when its raw template is non-empty (never -> ""). Read the
  # raw value so a bare #W is NOT expanded here: at config-parse #W resolves empty,
  # which used to drop the name in number-on-the-right position.
  text=$(tmux show -gqv "@_tmx_${p}_text")
  text_style="#{E:@_tmx_${p}_text_style}"

  # The name container. With notch the icon<->name seam takes the shape's cap
  # (the number colour tapering into the name bg) instead of the plain separator.
  local namepart="#{E:@_tmx_${p}_namepart}"
  [ -n "$seam_glyph" ] && namepart="#[fg=$(expand "#{E:@themux_window_${o}number_color}"),bg=#{E:@_tmx_${p}t_bg}]${seam_glyph}#{E:@_tmx_${p}_text_style}#{E:@_tmx_${p}_text}"

  if [ "$position" = "left" ]; then
    # number block (with a right pad so the index stays centred whether or not a
    # name follows), then the name container — itself right-padded (on the text
    # bg) so the name block is symmetric — only when the window has text.
    printf '%s%s%s #{?#{E:@_tmx_%s_text},%s ,}%s%s' \
      "$number_style" "$left" "$number" "$p" "$namepart" "$flags" "$right"
  elif [ -n "$text" ]; then
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
exit 0
