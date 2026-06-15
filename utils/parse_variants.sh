#!/usr/bin/env bash
# Parse @themux_<scope>_variant "shape [fill] [notch]" into the single-value
# options the renderers read: @_tmx_<scope>_{shape,fill,notch}. Doing the parse
# once here means the window/pane/module renderers never split strings in tmux.
#
#   shape : squared | rounded | slanted | naked | unstyled   (default squared)
#   fill  : icon (default) | fill | none
#   notch : "yes" when present — the icon<->text seam inherits the cap glyph
#
# Order-independent: each token is matched by what it is, not its position.
for scope in module window pane; do
  read -ra toks <<<"$(tmux show -gqv "@themux_${scope}_variant")"
  shape="" fill="icon" notch="no"
  for tok in "${toks[@]}"; do
    case "$tok" in
      squared | rounded | slanted | unstyled) shape="$tok" ;;
      icon | fill | none | naked) fill="$tok" ;;
      notch) notch="yes" ;;
    esac
  done
  [ -z "$shape" ] && shape="squared"
  tmux set -g "@_tmx_${scope}_shape" "$shape"
  tmux set -g "@_tmx_${scope}_fill" "$fill"
  tmux set -g "@_tmx_${scope}_notch" "$notch"
done
exit 0
