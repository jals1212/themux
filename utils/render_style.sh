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

# Normalize a raw @themux_*_notch value to its direction: gt (>, the left block's
# colour penetrates right), lt (<, the right block penetrates left), auto (zone-
# aware — on is its alias) or off (default; unknown values degrade here, same
# convention as state_target). Single home for the on->auto alias, used by all
# three renderers (module_render.sh, window_render.sh, pane_render.sh).
themux_notch_mode() { # $1 raw -> gt | lt | auto | off
  case "$1" in '>') echo gt ;; '<') echo lt ;; auto|on) echo auto ;; *) echo off ;; esac
}

# Parse a @themux_*_padding value into four side pads:
#   "N" -> "N N|N N"
#   "<leading-left> [leading-right]|<text-left> [text-right]"
#
# This is intentionally breaking: padding has one grammar only. The "|" marks
# the leading<->text seam, so each side can be spaced independently. A single
# value without "|" expands to all four sides; a single value on either side of
# "|" expands to both sides there. Invalid or malformed values fall back to the
# default "1" -> "1 1|1 1".
pad_default() { printf '1 1 1 1'; }

pad_is_cell() { [[ "$1" =~ ^[0-9]+$ ]]; }

pad_side_parse() { # $1 side value -> "left right"
  local -a f
  read -ra f <<<"$1"
  case "${#f[@]}" in
    1)
      pad_is_cell "${f[0]}" || return 1
      printf '%s %s' "${f[0]}" "${f[0]}"
      ;;
    2)
      pad_is_cell "${f[0]}" && pad_is_cell "${f[1]}" || return 1
      printf '%s %s' "${f[0]}" "${f[1]}"
      ;;
    *) return 1 ;;
  esac
}

pad_parse() { # $1 raw value -> "leading_left leading_right text_left text_right"
  local left right left_pad right_pad
  local -a f
  case "$1" in
    *'|'*) ;;
    *)
      read -ra f <<<"$1"
      case "${#f[@]}" in
        1)
          pad_is_cell "${f[0]}" || { pad_default; return; }
          printf '%s %s %s %s' "${f[0]}" "${f[0]}" "${f[0]}" "${f[0]}"
          ;;
        *) pad_default ;;
      esac
      return
      ;;
  esac
  left="${1%%|*}"
  right="${1#*|}"
  left_pad=$(pad_side_parse "$left") || { pad_default; return; }
  right_pad=$(pad_side_parse "$right") || { pad_default; return; }
  printf '%s %s' "$left_pad" "$right_pad"
}

# Emit N space cells (a non-numeric or empty N -> nothing).
spaces() { local n="$1"; [[ "$n" =~ ^[0-9]+$ ]] || n=0; printf "%${n}s" ''; }
