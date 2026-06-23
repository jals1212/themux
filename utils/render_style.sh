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

# Parse a @themux_*_padding value into a badge's three pads "<L> <S> <T>" (cells):
#   L = pad on BOTH sides of the leading (icon/number) block — keeps it centred.
#   S = separator between the leading block and the text.
#   T = trailing pad after the text (the right-cap room).
# Grammar (cell numbers, no named tokens):
#   ""    -> 1 1 1   (the default)
#   "N"   -> N N N   (one number sets all three)
#   "A B" -> A 1 B   (two are the extremes; the centre keeps the default)
#   "L S T" -> taken as-is
# The icon glyph's own per-glyph compensation lives in @themux_<name>_icon and is
# independent of this.
pad_parse() { # $1 raw value -> "L S T"
  local -a f; read -ra f <<<"$1"
  case "${#f[@]}" in
    0) printf '1 1 1' ;;
    1) printf '%s %s %s' "${f[0]}" "${f[0]}" "${f[0]}" ;;
    2) printf '%s 1 %s' "${f[0]}" "${f[1]}" ;;
    *) printf '%s %s %s' "${f[0]}" "${f[1]}" "${f[2]}" ;;
  esac
}

# Emit N space cells (a non-numeric or empty N -> nothing).
spaces() { local n="$1"; [[ "$n" =~ ^[0-9]+$ ]] || n=0; printf "%${n}s" ''; }
