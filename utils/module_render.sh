#!/usr/bin/env bash
# Assemble @themux_module_<name> from the v3 props (shape/indicator/text/notch),
# mirroring utils/pane_render.sh: the indicator (icon) and text blocks are styled
# independently through the shared resolver. $1 is the module name.
#
# Colours are read raw and embedded as-is, and the option is stored with `tmux
# set` (no -F): theme hex stays literal, while the draw-time refs — the module
# text and the alert modules' #{l:...} threshold overrides — resolve per draw.
# This is in shell (not module_block.conf's %if branches) because tmux's %if is
# a parse-time test that does NOT see options set earlier in the same file.
#
# Every option is read in ONE tmux round-trip and every result written in one
# more (chained `set`), so a used module costs ~3 forks instead of ~20 — this is
# the bulk of themux load time. The read uses a US-delimited display: it keeps
# empty values aligned by position and leaves the raw #{...} refs intact (unlike
# a plain #{option}, display does not re-expand the value).

name="$1"
# shellcheck source=render_style.sh
. "$(dirname "$0")/render_style.sh"

US=$(printf '\037')
IFS="$US" read -ra V < <(tmux display -p \
"#{@themux_module_shape}${US}#{@themux_module_indicator}${US}#{@themux_module_text}${US}#{@themux_module_notch}${US}#{@themux_module_connect_separator}${US}#{@themux_${name}_color}${US}#{@thm_surface_0}${US}#{@thm_crust}${US}#{@thm_fg}${US}#{@themux_${name}_icon}${US}#{@themux_${name}_icon_bg}${US}#{@themux_${name}_icon_fg}${US}#{@themux_${name}_text_bg}${US}#{@themux_${name}_text_fg}${US}#{@themux_${name}_self_styled}${US}#{@themux_module_middle_separator}${US}#{@themux_${name}_when}${US}END")
shape=${V[0]} indicator=${V[1]} text_style=${V[2]} notch=${V[3]} connect=${V[4]}
accent=${V[5]} surface=${V[6]} crust=${V[7]} fg=${V[8]} icon=${V[9]}
ibg=${V[10]} ifg=${V[11]} tbg=${V[12]} tfg=${V[13]} self_styled=${V[14]}
midsep=${V[15]} when=${V[16]}

[ "$shape" = unstyled ] && exit 0

text="#{E:@themux_${name}_text}"

# Shape glyphs (octal UTF-8). squared is a full block; rounded/slanted taper.
case "$shape" in
  rounded) lglyph=$(printf '\356\202\266'); rglyph=$(printf '\356\202\264') ;;
  slanted) lglyph=$(printf '\356\202\272'); rglyph=$(printf '\356\202\274') ;;
  *)       lglyph=$(printf '\342\226\210'); rglyph=$(printf '\342\226\210') ;;
esac

# Indicator/text colours: a module-set override wins (alert modules inject their
# live threshold colours), else resolve from the style.
resolve_style "$indicator" "$accent" "$surface" "$crust" "$fg"
[ -z "$ibg" ] && ibg="$RS_BG"
[ -z "$ifg" ] && ifg="$RS_FG"
resolve_style "$text_style" "$accent" "$surface" "$crust" "$fg"
[ -z "$tbg" ] && tbg="$RS_BG"
[ -z "$tfg" ] && tfg="$RS_FG"

# Caps: the shape glyph in the adjacent block's colour. A transparent block
# (naked) takes the accent as an outline; squared has no outline (a solid █ is
# not an edge), so it drops the cap there. connect_separator=yes joins the cap
# to the neighbour (no bg reset).
connstyle="#[bg=default]"
[ "$connect" = yes ] && connstyle=""
cap() { # $1 glyph, $2 block bg
  [ -z "$1" ] && return
  if [ "$2" = default ]; then
    [ "$shape" = squared ] && return
    printf '#[fg=%s]%s%s' "$accent" "$connstyle" "$1"
  else
    printf '#[fg=%s]%s%s' "$2" "$connstyle" "$1"
  fi
}

iblock="#[fg=$ifg,bg=$ibg] $icon "
# The text value carries its own leading space; add a trailing one so the block
# is padded both sides (the icon block is) and the right cap — squared █, rounded
# bulge, or the inward slant — has a cell to sit against. Re-assert the block bg
# first, so a self-styled text cannot leak its last colour into the pad/cap.
#
# A self-styled text (e.g. gitmux) sets its own colours and resets to default
# between segments; #[push-default] makes those resets fall back to the block's
# style instead of the bare bar, so the whole pill keeps one background.
text_open="" text_close="#[bg=$tbg]"
if [ "$self_styled" = yes ]; then
  text_open="#[push-default]" text_close="#[pop-default]#[bg=$tbg]"
fi
tblock="#[fg=$tfg,bg=$tbg]${text_open}${text}${text_close} "

# Notch seam: the icon block's right cap into the text bg, only when the blocks
# differ (matching bg would be an invisible phantom cell); else the separator.
if [ "$notch" = on ] && [ "$ibg" != "$tbg" ]; then
  seamcol="$ibg"
  [ "$ibg" = default ] && seamcol="$accent"
  seam="#[fg=$seamcol,bg=$tbg]$rglyph"
else
  seam="$midsep"
fi

# Expose the bare core (blocks + seam, no outer caps) and the edge cap colours
# so utils/layout.sh can connect adjacent modules powerline-style: between two
# modules the slant/bulge is one module's right colour tapering into the next
# module's left background. A transparent (naked) edge falls back to the accent.
lcol="$ibg"; [ "$ibg" = default ] && lcol="$accent"
rcol="$tbg"; [ "$tbg" = default ] && rcol="$accent"

out="$(cap "$lglyph" "$ibg")${iblock}${seam}${tblock}$(cap "$rglyph" "$tbg")"

# A module may only appear under a condition (@themux_<name>_when, e.g. zoom).
# The segment carries commas (styles), so stash it and gate via #{E:}; in a
# naked text it also keeps its own leading divider so it can vanish without
# leaving a dangling separator. All outputs go out in one chained `set`.
set_args=(set -g "@_tmx_module_${name}_core" "${iblock}${seam}${tblock}"
  ';' set -g "@_tmx_module_${name}_lcol" "$lcol"
  ';' set -g "@_tmx_module_${name}_rcol" "$rcol"
  ';' set -g "@_tmx_module_${name}_lbg" "$ibg"
  ';' set -g "@_tmx_module_${name}_rbg" "$tbg")
if [ -n "$when" ]; then
  prefix=""
  [ "$text_style" = naked ] && prefix="#{@_tmx_module_divider}"
  set_args+=(';' set -g "@_tmx_module_${name}_seg" "${prefix}${out}")
  out="#{?${when},#{E:@_tmx_module_${name}_seg},}"
fi
set_args+=(';' set -g "@themux_module_${name}" "$out")
tmux "${set_args[@]}"
exit 0
