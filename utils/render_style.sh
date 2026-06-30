#!/usr/bin/env bash
# Shared style resolver for the variant grammar (v3). Each styleable sub-part of
# an item — the leading (icon/number) and the text — picks a named style; this
# maps that name plus the item's colour roles to a (background, foreground) pair.
# One source of truth, sourced by utils/window_render.sh and utils/pane_render.sh.
#
#   solid  -> accent bg,      crust fg   (a solid colour block)
#   soft   -> surface bg,     normal fg  (a neutral grey block, plain text)
#   subtle -> surface bg,     accent fg  (a neutral block, coloured text)
#   naked  -> transparent bg, accent fg  (no block, coloured text on the bar)
#
# Usage: resolve_style <style> <accent> <surface> <crust> <fg>
#        then read the two globals it sets: RS_BG and RS_FG.
# Globals (not a subshell) so a draw-time #{?...} accent — which carries commas —
# survives intact instead of being word-split.
# shellcheck disable=SC2034  # RS_BG/RS_FG are read by the sourcing render scripts
resolve_style() {
  case "$1" in
    solid)  RS_BG="$2"; RS_FG="$4" ;;
    subtle) RS_BG="$3"; RS_FG="$2" ;;
    naked)  RS_BG="default"; RS_FG="$2" ;;
    *)      RS_BG="$3"; RS_FG="$5" ;; # soft (the default)
  esac
}

# Resolve a shared prop with the item cascade: @themux_<item>_<prop> if set, else
# the shared @themux_all_<prop>. One round-trip (display -p evaluates the #{?}).
#   Usage: shape=$(themux_prop window shape)
themux_prop() { # $1 item, $2 prop
  # Empty-check (not truthy) so a literal "0" value (valid for padding) is honoured.
  tmux display -p "#{?#{==:#{@themux_$1_$2},},#{@themux_all_$2},#{@themux_$1_$2}}"
}

# Parse a @themux_*_padding value into four side pads
# "<leading-left> [leading-right]|<text-left> [text-right]" (cells).
#
# This is intentionally breaking: padding has one grammar only. The "|" marks
# the leading<->text seam, so each side can be spaced independently. A single
# value on either side expands to both sides there: "1 | 1" -> "1 1|1 1".
# Invalid or omitted cells fall back to 0 via spaces(), not to legacy defaults.
pad_side_parse() { # $1 side value -> "left right"
  local -a f
  read -ra f <<<"$1"
  case "${#f[@]}" in
    0) printf '0 0' ;;
    1) printf '%s %s' "${f[0]}" "${f[0]}" ;;
    *) printf '%s %s' "${f[0]}" "${f[1]}" ;;
  esac
}

pad_parse() { # $1 raw value -> "leading_left leading_right text_left text_right"
  local left right
  case "$1" in
    *'|'*) ;;
    *) printf '0 0 0 0'; return ;;
  esac
  left="${1%%|*}"
  right="${1#*|}"
  printf '%s %s' "$(pad_side_parse "$left")" "$(pad_side_parse "$right")"
}

# Emit N space cells (a non-numeric or empty N -> nothing).
spaces() { local n="$1"; [[ "$n" =~ ^[0-9]+$ ]] || n=0; printf "%${n}s" ''; }
