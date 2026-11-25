# /// script
# requires-python = ">=3.12"
# dependencies = ["fonttools", "pillow"]
# ///
"""Build a separately named SauceCodePro fork with a two-cell Clanker avatar."""

import argparse
import io
import shutil
from pathlib import Path

from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont, newTable
from fontTools.ttLib.tables.sbixGlyph import Glyph
from fontTools.ttLib.tables.sbixStrike import Strike
from PIL import Image

CODEPOINTS = (0xF8E0, 0xF8E1)


def build(source, avatar, destination):
    font = TTFont(source)
    names = ("clankerLeft", "clankerRight")
    order = list(font.getGlyphOrder())
    cmap = font.getBestCmap()
    if any(code in cmap for code in CODEPOINTS):
        raise ValueError(f"Clanker codepoints already occupied in {source}")
    advance = font["hmtx"]["space"][0]
    for name in names:
        font["glyf"][name] = TTGlyphPen(None).glyph()
        font["hmtx"][name] = (advance, 0)
    font.setGlyphOrder(order + list(names))
    for table in font["cmap"].tables:
        if table.isUnicode() and table.format in (4, 12):
            table.cmap.update(zip(CODEPOINTS, names))

    style = font["name"].getDebugName(17) or font["name"].getDebugName(2)
    postscript = "ClankerCode-" + style.replace(" ", "")
    replacements = {
        1: "Clanker Code",
        2: style,
        3: postscript + ";1.0",
        4: "Clanker Code " + style,
        6: postscript,
        16: "Clanker Code",
        17: style,
    }
    for record in font["name"].names:
        if record.nameID in replacements:
            record.string = replacements[record.nameID].encode(record.getEncoding())
    for name_id, value in replacements.items():
        font["name"].setName(value, name_id, 3, 1, 0x409)

    bitmap = newTable("sbix")
    units = font["head"].unitsPerEm
    with Image.open(avatar) as image:
        for ppem in (16, 24, 32, 48, 64, 96, 128, 192, 256):
            width = round(advance / units * ppem)
            size = width * 2
            scaled = image.convert("RGBA").resize(
                (size, size), Image.Resampling.LANCZOS
            )
            strike = Strike(ppem=ppem, resolution=72)
            baseline = round(font["hhea"].descent / units * ppem)
            for index, name in enumerate(names):
                output = io.BytesIO()
                scaled.crop((index * width, 0, (index + 1) * width, size)).save(
                    output, format="PNG"
                )
                strike.glyphs[name] = Glyph(
                    glyphName=name,
                    graphicType="png ",
                    imageData=output.getvalue(),
                    originOffsetX=0,
                    originOffsetY=baseline,
                )
            bitmap.strikes[ppem] = strike
    font["sbix"] = bitmap
    font.save(destination)
    font.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path.home() / "Library/Fonts")
    parser.add_argument(
        "--output", type=Path, default=Path(__file__).with_name("font-build")
    )
    parser.add_argument("--install", action="store_true")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    avatar = Path(__file__).with_name("assets") / "clanker-mode.png"
    sources = sorted(args.source.glob("SauceCodeProNerdFont-*.ttf"))
    if not sources:
        parser.error(f"No SauceCodePro Nerd Font files in {args.source}")
    for source in sources:
        destination = args.output / source.name.replace(
            "SauceCodeProNerdFont", "ClankerCode"
        )
        build(source, avatar, destination)
        if args.install:
            shutil.copy2(destination, Path.home() / "Library/Fonts" / destination.name)
        print(destination)


if __name__ == "__main__":
    main()
