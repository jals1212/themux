#!/usr/bin/env bash
# Assemble @themux_module_<name> from the v3 props (shape/indicator/text/notch),
# mirroring utils/pane_render.sh: the indicator (icon) and text blocks are styled
# independently through the shared resolver. $1 is the module name.
#
# The accent (@themux_<name>_color, a #{@thm_*} token) is expanded to the current
# theme's concrete colour here, so the segment stays literal and is re-baked on
# every reload — a theme switch tracks (like utils/window_render.sh). A live
# #{l:...} threshold ref (the cpu/ram alert modules) is left raw so it keeps
# resolving per draw, as are the module text and the icon/text overrides. The
# option itself is stored with `tmux set` (no -F). This is in shell (not
# module_block.conf's %if branches) because tmux's %if is a parse-time test that
# does NOT see options set earlier in the same file.
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
"#{?#{@themux_module_shape},#{@themux_module_shape},#{@themux_all_shape}}${US}#{?#{@themux_module_indicator},#{@themux_module_indicator},#{@themux_all_indicator}}${US}#{?#{@themux_module_text},#{@themux_module_text},#{@themux_all_text}}${US}#{?#{@themux_module_notch},#{@themux_module_notch},#{@themux_all_notch}}${US}#{@themux_module_connect_separator}${US}#{@themux_${name}_color}${US}#{@thm_surface_0}${US}#{@thm_crust}${US}#{@thm_fg}${US}#{@themux_${name}_icon}${US}#{@themux_${name}_icon_bg}${US}#{@themux_${name}_icon_fg}${US}#{@themux_${name}_text_bg}${US}#{@themux_${name}_text_fg}${US}#{@themux_${name}_self_styled}${US}#{@themux_module_middle_separator}${US}#{@themux_${name}_when}${US}#{?#{@themux_module_indicator_highlight},#{@themux_module_indicator_highlight},#{@themux_all_indicator_highlight}}${US}#{?#{@themux_module_text_highlight},#{@themux_module_text_highlight},#{@themux_all_text_highlight}}${US}#{?#{@themux_module_indicator_position},#{@themux_module_indicator_position},#{@themux_all_indicator_position}}${US}#{E:@themux_${name}_color}${US}END")
shape=${V[0]} indicator=${V[1]} text_style=${V[2]} notch=${V[3]} connect=${V[4]}
accent=${V[5]} surface=${V[6]} crust=${V[7]} fg=${V[8]} icon=${V[9]}
ibg_ov=${V[10]} ifg_ov=${V[11]} tbg_ov=${V[12]} tfg_ov=${V[13]} self_styled=${V[14]}
midsep=${V[15]} when=${V[16]} ind_hl=${V[17]} text_hl=${V[18]} position=${V[19]}
accent_exp=${V[20]}
[ -n "$ind_hl" ] || ind_hl=both
[ -n "$text_hl" ] || text_hl=both

# A static theme-ref accent (#{@thm_*}) is baked to the current theme's concrete
# colour, so the segment stays literal and is re-baked on every reload (theme
# switch tracks, mirroring utils/window_render.sh). A live #{l:...} threshold ref
# (the cpu/ram metric modules) is left raw so it keeps resolving per draw.
case "$accent" in
  *'l:'*) ;;
  *'#{'*) accent="$accent_exp" ;;
esac

[ "$shape" = unstyled ] && exit 0

text="#{E:@themux_${name}_text}"

# Shape glyphs (octal UTF-8). squared is a full block; rounded/slanted/powerline taper.
case "$shape" in
  rounded)   lglyph=$(printf '\356\202\266'); rglyph=$(printf '\356\202\264') ;;
  slanted)   lglyph=$(printf '\356\202\272'); rglyph=$(printf '\356\202\274') ;;
  powerline) lglyph=$(printf '\356\202\262'); rglyph=$(printf '\356\202\260') ;;
  *)         lglyph=$(printf '\342\226\210'); rglyph=$(printf '\342\226\210') ;;
esac

# Indicator/text colours: a module-set override (alert modules inject their live
# threshold colours) wins on the channels the highlight toggle includes, else the
# style's resolved colour. Default both -> any override applies (as before).
resolve_style "$indicator" "$accent" "$surface" "$crust" "$fg"
ibg="$RS_BG" ifg="$RS_FG"
case "$ind_hl" in bg|both) [ -n "$ibg_ov" ] && ibg="$ibg_ov" ;; esac
case "$ind_hl" in fg|both) [ -n "$ifg_ov" ] && ifg="$ifg_ov" ;; esac
resolve_style "$text_style" "$accent" "$surface" "$crust" "$fg"
tbg="$RS_BG" tfg="$RS_FG"
case "$text_hl" in bg|both) [ -n "$tbg_ov" ] && tbg="$tbg_ov" ;; esac
case "$text_hl" in fg|both) [ -n "$tfg_ov" ] && tfg="$tfg_ov" ;; esac

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

# One leading space; the trailing one comes from the icon value (every icon is
# "<glyph> "), so the icon block is padded 1+1 like the window number block " #I "
# rather than 1+2 — a tighter, matching footprint.
iblock="#[fg=$ifg,bg=$ibg] $icon"
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

# Block order follows the indicator position: icon-then-text (left, default) or
# text-then-icon (right). first/second are the blocks in display order, fbg/sbg
# their backgrounds; the rest of the assembly is order-agnostic.
if [ "$position" = right ]; then
  first="$tblock" fbg="$tbg" second="$iblock" sbg="$ibg"
else
  first="$iblock" fbg="$ibg" second="$tblock" sbg="$tbg"
fi

# Notch seam: the first block's right cap into the second block's bg, only when
# the blocks differ (matching bg would be an invisible phantom cell); else the
# plain separator.
if [ "$notch" = on ] && [ "$fbg" != "$sbg" ]; then
  seamcol="$fbg"
  [ "$fbg" = default ] && seamcol="$accent"
  seam="#[fg=$seamcol,bg=$sbg]$rglyph"
else
  seam="$midsep"
fi

# Expose the bare core (blocks + seam, no outer caps) and the edge cap colours
# so utils/layout.sh can connect adjacent modules powerline-style: between two
# modules the slant/bulge is one module's right colour tapering into the next
# module's left background. A transparent (naked) edge falls back to the accent.
lcol="$fbg"; [ "$fbg" = default ] && lcol="$accent"
rcol="$sbg"; [ "$sbg" = default ] && rcol="$accent"

out="$(cap "$lglyph" "$fbg")${first}${seam}${second}$(cap "$rglyph" "$sbg")"

# A module may only appear under a condition (@themux_<name>_when, e.g. zoom).
# The segment carries commas (styles), so stash it and gate via #{E:}; in a
# naked text it also keeps its own leading divider so it can vanish without
# leaving a dangling separator. All outputs go out in one chained `set`.
set_args=(set -g "@_tmx_module_${name}_core" "${first}${seam}${second}"
  ';' set -g "@_tmx_module_${name}_lcol" "$lcol"
  ';' set -g "@_tmx_module_${name}_rcol" "$rcol"
  ';' set -g "@_tmx_module_${name}_lbg" "$fbg"
  ';' set -g "@_tmx_module_${name}_rbg" "$sbg")
if [ -n "$when" ]; then
  prefix=""
  [ "$text_style" = naked ] && prefix="#{@_tmx_module_divider}"
  set_args+=(';' set -g "@_tmx_module_${name}_seg" "${prefix}${out}")
  out="#{?${when},#{E:@_tmx_module_${name}_seg},}"
fi
set_args+=(';' set -g "@themux_module_${name}" "$out")
tmux "${set_args[@]}"
exit 0
