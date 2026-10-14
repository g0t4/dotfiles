# Syntax lab

Run from the dotfiles root (uv installs the isolated script dependencies):

```sh
uv run tools/syntax-lab/highlight.py
uv run tools/syntax-lab/highlight.py --swatches
uv run tools/syntax-lab/highlight.py --renderer rich --line-numbers
uv run tools/syntax-lab/highlight.py .config/xonsh/apps/hex.py
uv run tools/syntax-lab/highlight.py --language lua
cat tools/syntax-lab/examples/sample.py | uv run tools/syntax-lab/highlight.py - -l python
uv run tools/syntax-lab/highlight.py --force-color | less -R
```

Edit `palette.json`, then rerun the same specimen. `--palette path/to/variant.json`
lets you compare copies. No terminal preferences are changed. Output uses truecolor
foreground escapes and preserves the terminal background; redirected output is plain
unless `--force-color` is supplied. `NO_COLOR` is respected unless forced.

The starting palette aims for visible comments, clear structure, and restrained
punctuation, without bold or italics. Docstrings use the comment color. Definitions
are blue, keywords violet, strings green, numbers orange, classes/exceptions amber,
and builtins/decorators teal. Ordinary names use the terminal's neutral foreground.

Accepted baseline: subtle pastels with distinct hues, especially the rich purple
keywords (`#b394e3`); no bold; neutral ordinary names with red reserved for errors;
matching semantic roles across Python and Lua; amber escapes stand apart from green
string text. Preserve these choices when integrating into daily tools.

Background reference: `#1f2229`, foreground `#cecece`, from the dark variant of your
iTerm2 `Recording 1080p` profile in local and synced preferences. The same background
is configured in `.config/nvim/lua/plugins/colors.lua`. iTerm stores these as Display
P3 components; the hex values here reuse their numeric components as sRGB, so swatch
contrast is an approximation of the terminal appearance. Neither renderer paints
that reference background.

Pygments is lexical: it colors function definitions but does not resolve every
function call or distinguish every type annotation from an ordinary name. Use
`--tokens` to see exactly what it recognized before changing a color mapping.
The optional Rich renderer consumes the same custom Pygments style.

For the first tuning pass, compare comment readability, keyword saturation,
string brightness, and punctuation contrast. Change one role at a time against
the same sample, then verify it on a real file.

## Daily use in Xonsh

Interactive Xonsh loads `rc.d/syntax-theme.xsh` to make `bat` and interactive
`cat` use this palette for Python (`.py`, `.pyi`) and Lua (`.lua`). Enable it in
an existing REPL from the dotfiles root:

```xonsh
source .config/xonsh/rc.d/syntax-theme.xsh
bat tools/syntax-lab/examples/sample.py
bat tools/syntax-lab/examples/sample.lua
cat tools/syntax-lab/examples/sample.py
echo 'print("hello\\n")' | bat -pl py
bat-stock tools/syntax-lab/examples/sample.py
```

The wrapper supports filenames, multiple files, stdin with `-l py`/`-l lua`,
`-p`/`-pp`/`--plain`, `-pl`, `-n`/`--number`, `--style=plain`/`numbers`,
`--color=auto`/`always`/`never`, and `--paging=never`. It uses plain output with
no pager by default, matching this repo's bat config. Other languages and options
(including headers, themes, ranges, and paging) delegate to stock bat with the
original arguments and stdin. `bat-stock` bypasses the wrapper explicitly.
Piped/redirected output remains plain unless color is forced. The wrapper is
interactive-only; noninteractive Xonsh commands retain stock bat/cat.

Existing command transforms that append `| bat -l json` or `yaml` naturally reach
the wrapper and delegate to stock bat. Python source previews in abbreviation
help and Fish-wrapper help use this same palette through Rich. Palette edits
apply to the next invocation, without reloading Xonsh.

## Markdown and grayscale experiments

Markdown source (`.md`, `.markdown`, `-l md`, `-l markdown`) now uses the same
palette: purple headings, teal inline code/quotes, amber emphasis, blue link
labels, and slate URLs. Fenced code uses its language lexer with our code colors.
Markdown punctuation stays visible; tables retain their source layout. No bold
or italic font styles are applied. Interactive `cat file.md` no longer implicitly
pipes through glow; use `glow file.md` explicitly for its rendered view.

```sh
uv run tools/syntax-lab/highlight.py -l md
uv run tools/syntax-lab/highlight.py -l md --grayscale
uv run tools/syntax-lab/highlight.py --grayscale
uv run tools/syntax-lab/highlight.py --grayscale --swatches
```

In interactive Xonsh:

```xonsh
bat tools/syntax-lab/examples/sample.md
bat --theme=wes-gray tools/syntax-lab/examples/sample.md
bat --theme=wes-gray tools/syntax-lab/examples/sample.py
```

`wes-gray` is derived from the current palette on every invocation. It removes
chroma while preserving linear sRGB relative luminance (within 8-bit rounding),
which keeps the brightness hierarchy and approximate contrast rather than using
a simple RGB average or HSL lightness. The color theme remains the default.
The terminal background is always preserved, even for grayscale; the grayscale
swatch report uses a converted background reference for its contrast calculation.
Custom `wes-gray`/`wes-dark` theme names apply to supported wrapper requests;
other languages and advanced bat options still use stock bat and its own themes.

## Palette explorer

Every view accepts the same file argument (or `- -l python` for stdin). With no
file, it uses the built-in sample for the selected language. Sweeps repeat the
same text in each cell and never change your saved palette or terminal settings.

```sh
# Real files work as the sample for every sweep.
uv run tools/syntax-lab/highlight.py path/to/project.py --sweep background
uv run tools/syntax-lab/highlight.py path/to/project.py --sweep background-tint
uv run tools/syntax-lab/highlight.py path/to/project.py --sweep vision
uv run tools/syntax-lab/highlight.py path/to/project.py --sweep hue-shuffle --seed 42

# Zoom out, then rerun to fit more cells; or force a column count.
uv run tools/syntax-lab/highlight.py -l md --sweep background --sample-lines 18 --columns 3

# Actual raster blur, shown inline in iTerm2.
uv run tools/syntax-lab/highlight.py path/to/project.py --blur
uv run tools/syntax-lab/highlight.py path/to/project.py --sweep blur --steps 5 --blur 3 --output /tmp/blur.png

# One-off transforms and combinations.
uv run tools/syntax-lab/highlight.py path/to/project.py --vision deutan --severity 75
uv run tools/syntax-lab/highlight.py path/to/project.py --hue-shuffle --seed 42
uv run tools/syntax-lab/highlight.py path/to/project.py --sweep background --grayscale
uv run tools/syntax-lab/highlight.py path/to/project.py --sweep background --blur 2 --output /tmp/backgrounds.png

# Keep variants so you can retry a favorite by number.
uv run tools/syntax-lab/highlight.py path/to/project.py --sweep hue-shuffle --seed 42 --export-dir /tmp/themes
uv run tools/syntax-lab/highlight.py path/to/project.py --palette /tmp/themes/03.json
```

The grid defaults to `terminal columns / (longest sample line + divider)` with a
minimum cell width of 32. Labels also count toward cell width. Zooming out changes
the terminal's reported column count; rerun to recompute the layout. `--columns`
overrides it. Very long lines or too many forced columns can be cropped by the
terminal; use fewer columns, zoom out, or export an image with `--output`.
Full file contents are used by default; `--sample-lines N` selects its first N
lines. Tabs expand to four spaces. Trailing blank lines are trimmed for the grid.

Background selection starts with **fixed foreground colors**. `background`
sweeps OKLab lightness around your existing background, keeping its hue/chroma
when they fit in sRGB. Default: seven variants spanning 0.21 in lightness;
`--bg-span` adjusts that range and `--steps` sets the count. Odd counts contain
the exact original background. First choose the brightness neighborhood where
prose feels comfortable and comments stay readable. Then `background-tint`
compares the current background, a neutral gray, and five gentle tints at that
same lightness. It has seven fixed variants. Try short samples, then long files.
Explorer cells paint their background explicitly; ordinary highlighting still
preserves your terminal background. No terminal preferences are written.

`vision` compares the original with protan (red discrimination), deutan (green),
and tritan (blue/yellow) simulations. `--vision` selects one; `--severity` ranges
from 0 to 100. These use the Machado et al. model through
[Colorspacious](https://colorspacious.readthedocs.io/en/latest/reference.html#simulation-of-color-vision-deficiency)
on linear sRGB, including the background, with output clipped to sRGB gamut.
They are contrast experiments, not a literal prediction of an individual's vision;
intermediate tritan severities are particularly approximate.

Hue shuffles permute the distinct accent hues in OKLCH, preserving each role's
lightness and chroma where possible. Out-of-gamut colors reduce chroma while
keeping lightness/hue. Neutral text/comments/punctuation and background stay
fixed; roles sharing an original accent remain grouped. `--seed` makes shuffles
reproducible. A sweep includes the original plus `--steps - 1` consecutive seeds.

`--blur [radius]` uses Pillow Gaussian blur on a rendered text image (default
2 pixels at `--font-size 16`). A blur sweep runs from sharp to the selected radius,
or 3 pixels by default. Labels stay sharp. Images use a regular monospace font,
with no bold or italics; `--font` supplies a different TTF/TTC and `--font-size`
sets its size. This is a controlled specimen, not a screenshot of your terminal.
PNG output defaults to `/tmp/syntax-lab-blur.png`; `--output` chooses a path and
can export any sweep. iTerm2 gets an inline preview using its image protocol,
with explicit width in terminal cells rather than native pixels. This accounts
for zoom and Retina scaling; the raster grid's padding counts toward the width,
and oversized grids shrink to fit the pane while preserving aspect ratio. Saved
PNGs keep their original pixel dimensions. Other terminals can open the PNG in
an image viewer.

Sweep builders live in `explorer.py`'s `SWEEPS` registry and return labeled
`Variant` objects. Terminal layout, image rendering, composition, and palette
exports are shared, so new sweep techniques can use the same machinery. Exports
contain numbered palette JSON files and a manifest with labels and blur radii.
These explorer flags belong to `highlight.py`; the daily `bat` wrapper is unchanged.
