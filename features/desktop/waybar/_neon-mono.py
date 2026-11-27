"""Make a monospaced copy of Oxanium for Waybar's scrolling media title.

Usage: python3 _neon-mono.py OXANIUM_VARIABLE.ttf OUT.ttf

ScrollMPRIS always shows the same number of characters. In a proportional
font their width changes as they scroll, so the media tab shuffles. This
gives every glyph the same advance: narrower ones are centred in it, and
wider ones (m, w, M, W, @, %) are squeezed horizontally to fit.

Oxanium is under the SIL Open Font License 1.1. It declares no Reserved
Font Name, but the result takes its own name, "Neon Mono", so it isn't
mistaken for the real Oxanium. The license asks every copy to carry the
copyright notice and license, so the font keeps Oxanium's copyright,
license and license URL fields, and _neon-mono.nix ships OFL.txt with it.
"""

import sys

from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import ttProgram
from fontTools.varLib.instancer import instantiateVariableFont

# style.css sets the bar's text to weight 600.
WEIGHT = 600
# In font units (1000 per em). Oxanium's digits are 578; its widest
# letter, W, is 943. 640 is a usual monospace width.
ADVANCE = 640
FAMILY = "Neon Mono"

src, dst = sys.argv[1:3]
font = instantiateVariableFont(TTFont(src), {"wght": WEIGHT})
glyf = font["glyf"]
hmtx = font["hmtx"]
order = font.getGlyphOrder()

# Composite glyphs (é built from e and an accent) would move twice once
# their parts move, so turn them into plain outlines first.
glyph_set = font.getGlyphSet()
for name in order:
    if glyf[name].isComposite():
        pen = TTGlyphPen(glyph_set)
        glyph_set[name].draw(pen)
        glyf[name] = pen.glyph()

empty_program = ttProgram.Program()
empty_program.fromBytecode(b"")

for name in order:
    advance, _ = hmtx[name]
    if advance == 0:
        # Combining marks sit over the previous glyph; leave them be.
        continue
    glyph = glyf[name]
    lsb = 0
    if glyph.numberOfContours > 0:
        coords = glyph.coordinates
        if advance > ADVANCE:
            coords.scale((ADVANCE / advance, 1))
            advance = ADVANCE
        coords.translate(((ADVANCE - advance) / 2, 0))
        coords.toInt()
        # Hinting refers to the old point positions, so drop it.
        glyph.program = empty_program
        glyph.recalcBounds(glyf)
        lsb = glyph.xMin
    hmtx[name] = (ADVANCE, lsb)

# Kerning and ligatures would break the fixed width, and the hinting
# programs and width caches no longer match the outlines.
for tag in ("GPOS", "GSUB", "kern", "fpgm", "prep", "cvt ", "hdmx", "LTSH", "VDMX", "STAT"):
    if tag in font:
        del font[tag]
if "GDEF" in font:
    del font["GDEF"]

font["post"].isFixedPitch = 1
font["OS/2"].panose.bProportion = 9  # monospaced
font["OS/2"].xAvgCharWidth = ADVANCE
font["hhea"].advanceWidthMax = ADVANCE

# Replace only the naming fields. Copyright (0), trademark (7), maker and
# designer (8, 9, 11, 12), and license (13, 14) stay as Oxanium has them.
name_table = font["name"]
original_version = name_table.getDebugName(5) or "unknown version"
name_table.names = [
    record for record in name_table.names if record.nameID not in (1, 2, 3, 4, 5, 6, 16, 17, 21, 22, 25)
]
postscript = FAMILY.replace(" ", "") + "-Regular"
for name_id, value in {
    1: FAMILY,
    2: "Regular",
    3: f"{postscript};monospaced from Oxanium",
    4: FAMILY,
    5: f"Version 1.0; monospaced from Oxanium {original_version}",
    6: postscript,
}.items():
    name_table.setName(value, name_id, 3, 1, 0x409)

for name_id in (0, 13, 14):
    if not name_table.getDebugName(name_id):
        sys.exit(f"Oxanium has no name {name_id}; the license notice must stay in the font")

font.save(dst)
