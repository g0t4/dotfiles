# colorcode

A command-line color inspector that mirrors the layout and features of
[imagecolorpicker.com](https://imagecolorpicker.com/color-code/c69676).

Given a color it prints a terminal breakdown using ANSI true-color swatches:

- **Color conversion** - HEX, RGB, HSL, HSV, HWB, CMYK, XYZ, LAB, LCH, LUV, xyY
- **Variations** - shades (add black) and tints (add white) in 10% steps
- **Color combinations** - Complement, Split-complementary, Triadic, Analogous,
  Monochromatic, Tetradic harmonies
- **Color contrast checker** - WCAG contrast ratio against a background (AA/AAA)
- **Blindness simulator** - Protanopia, Deuteranopia, Tritanopia, Achromatopsia

## Usage

```sh
colorcode c69676                  # full report on a hex color
colorcode '#c69676'               # quote it if it starts with #
colorcode 198,150,118             # rgb triple
colorcode rgb(198, 150, 118)      # rgb() function form
colorcode hsl(24, 41%, 62%)       # hsl() function form
colorcode c69676 --bg 000000      # contrast check against a dark bg
colorcode c69676 --sections conversion,harmonies
```

`--sections` accepts a comma list of `conversion`, `variations`, `harmonies`,
`contrast`, `blindness`; the default is `all`.

## Where it lives

Source: `tools/colorcode/`. It runs on the repository's `.venv` (only `rich` is
needed beyond the stdlib; all color math is `colorsys` + `math`). Run it with
the repo `.venv`:

```sh
.venv/bin/python3 tools/colorcode/colorcode.py c69676
```

The Xonsh alias `colorcode` is registered in
`.config/xonsh/rc.d/python-specific.xsh` and launches directly so interactive
output (swatches) stays on the terminal.
