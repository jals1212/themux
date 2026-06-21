#!/usr/bin/env bash
# Assemble @themux_module_<name> from the variant grammar (shape/leading/text/
# notch), mirroring utils/pane_render.sh: the leading (icon) and text blocks are
# styled independently through the shared resolver. $1 is the module name.
#
# Each part picks a resting variant + accent, and (for a stateful module) an
# active variant + accent gated by a draw-time @themux_<name>_active_when (e.g.
# session's client_prefix). A plain module has no _active_when, so it renders the
# resting appearance only. The variant owns the (bg, fg) pair, so a contrasting
# variant can never collapse to bg == fg — there is no per-channel toggle.
#
# Three property tiers, most specific wins: @themux_<name>_<prop> (this module) >
# @themux_module_<prop> (all modules) > @themux_all_<prop> (everything). Colours
# fall back @themux_<name>_<slot>_color > @themux_<name>_color.
#
# The accent (@themux_<name>_color, a #{@thm_*} token) is expanded to the current
# theme's concrete colour here, so the segment stays literal and is re-baked on
# every reload — a theme switch tracks (like utils/window_render.sh). A draw-time
# accent — a live #{l:...} threshold ref (cpu/ram) or a #{?...} state conditional
# (session prefix) — is left raw so it keeps resolving per draw, as are the module
# text and icon. The option itself is stored with `tmux set` (no -F). This is in
# shell (not module_block.conf's %if branches) because tmux's %if is a parse-time
# test that does NOT see options set earlier in the same file.
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

# A property cascade: @themux_<name>_<prop> > @themux_module_<prop> > @themux_all_<prop>.
casc() { printf '#{?#{@themux_%s_%s},#{@themux_%s_%s},#{?#{@themux_module_%s},#{@themux_module_%s},#{@themux_all_%s}}}' "$name" "$1" "$name" "$1" "$1" "$1" "$1"; }
# A resting accent: @themux_<name>_<slot>_color > @themux_<name>_color.
acc() { printf '#{?#{@themux_%s_%s_color},#{@themux_%s_%s_color},#{@themux_%s_color}}' "$name" "$1" "$name" "$1" "$name"; }
# An active accent: @themux_<name>_<slot>_active_color > @themux_<name>_active_color > the resting accent ($2).
aacc() { printf '#{?#{@themux_%s_%s_active_color},#{@themux_%s_%s_active_color},#{?#{@themux_%s_active_color},#{@themux_%s_active_color},%s}}' "$name" "$1" "$name" "$1" "$name" "$name" "$2"; }

lead_acc=$(acc leading) text_acc=$(acc text)
IFS="$US" read -ra V < <(tmux display -p \
"$(casc shape)${US}$(casc leading_variant)${US}$(casc text_variant)${US}$(casc notch)${US}#{@themux_module_connect_separator}${US}${lead_acc}${US}${text_acc}${US}#{@thm_surface_0}${US}#{@thm_crust}${US}#{@thm_fg}${US}#{@themux_${name}_icon}${US}#{@themux_${name}_self_styled}${US}#{@themux_module_middle_separator}${US}#{@themux_${name}_when}${US}$(casc leading_position)${US}$(casc leading_active_variant)${US}$(casc text_active_variant)${US}$(aacc leading "$lead_acc")${US}$(aacc text "$text_acc")${US}#{@themux_${name}_active_when}${US}#{E:${lead_acc}}${US}#{E:${text_acc}}${US}#{E:$(aacc leading "$lead_acc")}${US}#{E:$(aacc text "$text_acc")}${US}#{@themux_${name}_icon_bg}${US}#{@themux_${name}_icon_fg}${US}#{@themux_${name}_text_bg}${US}#{@themux_${name}_text_fg}${US}END")
shape=${V[0]} leading=${V[1]} text_style=${V[2]} notch=${V[3]} connect=${V[4]}
lead_acc=${V[5]} text_acc=${V[6]} surface=${V[7]} crust=${V[8]} fg=${V[9]} icon=${V[10]}
self_styled=${V[11]} midsep=${V[12]} when=${V[13]} position=${V[14]}
lead_av=${V[15]} text_av=${V[16]} lead_aacc=${V[17]} text_aacc=${V[18]} active_when=${V[19]}
lead_acc_E=${V[20]} text_acc_E=${V[21]} lead_aacc_E=${V[22]} text_aacc_E=${V[23]}
icon_bg_ov=${V[24]} icon_fg_ov=${V[25]} text_bg_ov=${V[26]} text_fg_ov=${V[27]}
# The active variant defaults to the resting one — the active state keeps the same
# shape unless _active_variant is set, so only the colour swaps.
[ -n "$lead_av" ] || lead_av="$leading"
[ -n "$text_av" ] || text_av="$text_style"

# A static theme-ref accent (#{@thm_*}) is baked to the current theme's concrete
# colour (theme switch tracks). A draw-time ref — a live #{l:...} threshold or a
# #{?...} state conditional — is left raw so it keeps resolving per draw.
bake() { # $1 raw accent, $2 its E-expansion -> echoes the value to use
  case "$1" in
    *'l:'*|*'?'*) printf '%s' "$1" ;;
    *'#{'*)        printf '%s' "$2" ;;
    *)             printf '%s' "$1" ;;
  esac
}
lead_acc=$(bake "$lead_acc" "$lead_acc_E")
text_acc=$(bake "$text_acc" "$text_acc_E")
lead_aacc=$(bake "$lead_aacc" "$lead_aacc_E")
text_aacc=$(bake "$text_aacc" "$text_aacc_E")

[ "$shape" = unstyled ] && exit 0

text="#{E:@themux_${name}_text}"

# Shape glyphs (octal UTF-8). squared is a full block; rounded/slanted/powerline taper.
case "$shape" in
  rounded)   lglyph=$(printf '\356\202\266'); rglyph=$(printf '\356\202\264') ;;
  slanted)   lglyph=$(printf '\356\202\272'); rglyph=$(printf '\356\202\274') ;;
  powerline) lglyph=$(printf '\356\202\262'); rglyph=$(printf '\356\202\260') ;;
  *)         lglyph=$(printf '\342\226\210'); rglyph=$(printf '\342\226\210') ;;
esac

# Each block resolves its variant twice — with the resting accent and the active
# accent — then a per-channel draw-time switch picks between them under
# active_when. With no active_when (a plain module) or when the two resolve to the
# same value, the channel is plain (no conditional).
chan() { # $1 active value, $2 resting value -> conditional or plain
  if [ -z "$active_when" ] || [ "$1" = "$2" ]; then
    printf '%s' "$2"
  else
    printf '#{?%s,%s,%s}' "$active_when" "$1" "$2"
  fi
}

resolve_style "$leading" "$lead_acc" "$surface" "$crust" "$fg"; ribg=$RS_BG rifg=$RS_FG
resolve_style "$lead_av" "$lead_aacc" "$surface" "$crust" "$fg"; aibg=$RS_BG aifg=$RS_FG
# Raw per-channel overrides (advanced): a module may pin a concrete colour on a
# channel, over the variant. cpu/ram use this to carry tmux-cpu's LIVE per-level
# fg/bg (#{<name>_fg_color}/#{<name>_bg_color}), so the block escalates colour at
# draw time — something a variant cannot do, since the segment is baked once at
# layout time. The two channels take different live refs, so they always contrast.
[ -n "$icon_bg_ov" ] && { ribg="$icon_bg_ov"; aibg="$icon_bg_ov"; }
[ -n "$icon_fg_ov" ] && { rifg="$icon_fg_ov"; aifg="$icon_fg_ov"; }
ibg=$(chan "$aibg" "$ribg") ifg=$(chan "$aifg" "$rifg")

resolve_style "$text_style" "$text_acc" "$surface" "$crust" "$fg"; rtbg=$RS_BG rtfg=$RS_FG
resolve_style "$text_av" "$text_aacc" "$surface" "$crust" "$fg"; atbg=$RS_BG atfg=$RS_FG
[ -n "$text_bg_ov" ] && { rtbg="$text_bg_ov"; atbg="$text_bg_ov"; }
[ -n "$text_fg_ov" ] && { rtfg="$text_fg_ov"; atfg="$text_fg_ov"; }
tbg=$(chan "$atbg" "$rtbg") tfg=$(chan "$atfg" "$rtfg")

# The accent used by a transparent (naked) block's cap: the active accent under
# active_when, else the resting one.
accent=$(chan "$lead_aacc" "$lead_acc")

# Caps: the shape glyph in the adjacent block's colour. A transparent block
# (naked) takes the accent as an outline; squared has no outline (a solid █ is
# not an edge), so it drops the cap there. connect_separator=yes joins the cap
# to the neighbour (no bg reset).
connstyle="#[bg=default]"
[ "$connect" = yes ] && connstyle=""
cap() { # $1 glyph, $2 block bg, $3 naked-accent for that block
  [ -z "$1" ] && return
  if [ "$2" = default ]; then
    [ "$shape" = squared ] && return
    printf '#[fg=%s]%s%s' "$3" "$connstyle" "$1"
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

# Block order follows the leading position: icon-then-text (left, default) or
# text-then-icon (right). first/second are the blocks in display order, fbg/sbg
# their backgrounds; the rest of the assembly is order-agnostic.
if [ "$position" = right ]; then
  first="$tblock" fbg="$tbg" facc="$(chan "$text_aacc" "$text_acc")" second="$iblock" sbg="$ibg" sacc="$accent"
else
  first="$iblock" fbg="$ibg" facc="$accent" second="$tblock" sbg="$tbg" sacc="$(chan "$text_aacc" "$text_acc")"
fi

# Seam between the two blocks, drawn only when they differ (matching bg would be
# an invisible phantom cell; else the plain separator). notch=on takes the shape's
# right cap; notch=off takes a flat block (█) so icon and text get a clean divider
# instead of abutting.
if [ "$fbg" != "$sbg" ]; then
  seamcol="$fbg"
  [ "$fbg" = default ] && seamcol="$facc"
  if [ "$notch" = on ]; then
    seam="#[fg=$seamcol,bg=$sbg]$rglyph"
  else
    seam="#[fg=$seamcol,bg=$sbg]$(printf '\342\226\210')"
  fi
else
  seam="$midsep"
fi

# Expose the bare core (blocks + seam, no outer caps) and the edge cap colours
# so utils/layout.sh can connect adjacent modules powerline-style: between two
# modules the slant/bulge is one module's right colour tapering into the next
# module's left background. A transparent (naked) edge falls back to the accent.
lcol="$fbg"; [ "$fbg" = default ] && lcol="$facc"
rcol="$sbg"; [ "$sbg" = default ] && rcol="$sacc"

out="$(cap "$lglyph" "$fbg" "$facc")${first}${seam}${second}$(cap "$rglyph" "$sbg" "$sacc")"

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
