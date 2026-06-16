#!/usr/bin/env bash
# Shared style resolver for the variant grammar (v3). Each styleable sub-part of
# an item — the indicator (icon/number) and the text — picks a named style; this
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
resolve_style() {
  case "$1" in
    solid)  RS_BG="$2"; RS_FG="$4" ;;
    subtle) RS_BG="$3"; RS_FG="$2" ;;
    naked)  RS_BG="default"; RS_FG="$2" ;;
    *)      RS_BG="$3"; RS_FG="$5" ;; # soft (the default)
  esac
}
