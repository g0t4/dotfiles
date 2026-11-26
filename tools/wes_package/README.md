# Syntax lab

Install the command globally from this directory. The editable install keeps
palette and source changes live:

```sh
cd tools/syntax-lab
uv tool install --editable .
```

`highlight` is the explicit renderer: it never delegates unsupported languages
or options to stock `bat`. Run it from any directory:

```sh
highlight
highlight --swatches
highlight --renderer rich --line-numbers
highlight ~/.config/xonsh/apps/hex.py
highlight --language lua
cat path/to/source.py | highlight - -l python
highlight --force-color | less -R
```

Python, Lua, Markdown, Xonsh, Bash/sh, and YAML are also handled directly by
the daily `bat.py` interceptor. Other `bat` languages or options still delegate
to stock `bat` without consuming stdin.

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

Interactive Xonsh loads `rc.d/syntax-theme.py` to make `bat` and interactive
`cat` use this palette for Python (`.py`, `.pyi`), Lua (`.lua`), Xonsh (`.xsh`),
Bash (`.bash`, `.sh` and common shell startup files), and Markdown. Enable it in
an existing REPL from the dotfiles root:

```xonsh
source .config/xonsh/rc.d/syntax-theme.py
bat tools/syntax-lab/examples/sample.py
bat tools/syntax-lab/examples/sample.lua
bat bash/.bashrc
bat -pl sh - < bash/.bashrc
cat tools/syntax-lab/examples/sample.py
echo 'print("hello\\n")' | bat -pl py
bat-stock tools/syntax-lab/examples/sample.py
```

The wrapper supports filenames, multiple files, stdin with `-l py`/`-l lua`/`-l bash`/`-l sh`,
`-p`/`-pp`/`--plain`, `-pl`, `-n`/`--number`, `--style=plain`/`numbers`,
`--color=auto`/`always`/`never`, and `--paging=never`. It uses plain output with
no pager by default, matching this repo's bat config. Other languages and options
(including headers, themes, ranges, and paging) delegate to stock bat with the
original arguments and stdin. `bat-stock` bypasses the wrapper explicitly.
Piped/redirected output remains plain unless color is forced. The wrapper is
interactive-only; noninteractive Xonsh commands retain stock bat/cat.

Existing command transforms that append `| bat -l yaml` now use this palette;
JSON and other unsupported languages still delegate to stock bat. Python source
previews in abbreviation help and Fish-wrapper help use this same palette through
Rich. Palette edits apply to the next invocation, without reloading Xonsh.

Bash and `sh` views color external command words (for example `git` and `jq`)
blue at command positions, while flags and other plain arguments remain neutral.
This also applies to `run_bash` commands in the Python chat viewer through the
shared `wes_syntax` renderer. The distinction is lexical; it does not check
whether a command is installed or execute the source.

## Markdown and grayscale experiments

Markdown source (`.md`, `.markdown`, `-l md`, `-l markdown`) now uses the same
palette: purple headings, teal inline code/quotes, amber emphasis, blue link
labels, and slate URLs. Language-tagged triple-backtick fences use the same
lexer selection as standalone source, including the custom Bash and Xonsh lexers.
Markdown punctuation stays visible. Use `highlight --pad-tables README.md` to
align pipe tables and draw box borders in the output. Wide tables wrap to the terminal width in
interactive use. Pass `--width 80` to choose a limit, including when piping.
Tables keep their natural width when the limit cannot fit the borders and
minimum column widths. The flag leaves the file and fenced examples intact. No bold
or italic font styles are applied. Interactive `cat file.md` no longer implicitly
pipes through glow; use `glow file.md` explicitly for its rendered view.

```sh
highlight -l md
highlight -l md --grayscale
highlight --grayscale
highlight --grayscale --swatches
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
highlight path/to/project.py --sweep background
highlight path/to/project.py --sweep background-tint
highlight path/to/project.py --sweep vision
highlight path/to/project.py --sweep hue-shuffle --seed 42

# Zoom out, then rerun to fit more cells; or force a column count.
highlight -l md --sweep background --sample-lines 18 --columns 3

# Actual raster blur, shown inline in iTerm2.
highlight path/to/project.py --blur
highlight path/to/project.py --sweep blur --steps 5 --blur 3 --output /tmp/blur.png

# One-off transforms and combinations.
highlight path/to/project.py --vision deutan --severity 75
highlight path/to/project.py --hue-shuffle --seed 42
highlight path/to/project.py --sweep background --grayscale
highlight path/to/project.py --sweep background --blur 2 --output /tmp/backgrounds.png

# Keep variants so you can retry a favorite by number.
highlight path/to/project.py --sweep hue-shuffle --seed 42 --export-dir /tmp/themes
highlight path/to/project.py --palette /tmp/themes/03.json
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
These explorer flags belong to `highlight`; the daily `bat` wrapper is unchanged.

## Xonsh

Xonsh source uses Xonsh's own Pygments plugin (`xonsh.pyghooks.XonshLexer`)
with our palette and a small `SourceXonshLexer` subclass. It ends import states
at ordinary newlines so following Python statements aren't mistaken for module
names; explicit backslash continuations remain supported. `.xsh`, filenames ending in `xonshrc`, and `-l xsh`/`xonsh`
route through it in the daily wrapper. It also works in the preview tool, sweeps,
and Markdown fences labeled `xonsh` or `xsh`.

```xonsh
bat .config/xonsh/rc.d/learn.xsh
bat -pl xonsh .config/xonsh/rc.d/learn.xsh
```

```sh
highlight -l xonsh
highlight .config/xonsh/rc.d/learn.xsh --sweep background
```

Explicit subprocess constructs such as `$(cat foo.py)` and `$[cat ./foo.py]`
enter shell mode in the native lexer. Bare commands in whole-file highlighting
have limitations and may be classified as Python names; recognition can also
depend on the environment. Relative/absolute paths are included in the specimen
to make these cases visible as we iterate. Highlighting does not execute source.
Our normal Xonsh views no longer depend on the Sublime grammar. Stock bat remains
available for unsupported options and through `bat-stock`; its grammar is retained
for that fallback.

## Using the library in another Python tool

Install the local package into that tool's environment, preferably editable:

```sh
uv pip install --python /path/to/tool/.venv/bin/python -e "$WES_DOTFILES/tools/syntax-lab"
```

Or declare it in the tool's `pyproject.toml` (as the chat viewer does):

```toml
[project]
dependencies = ["wes-syntax"] # alongside the tool's existing dependencies

[tool.uv.sources]
wes-syntax = { path = "../dotfiles/tools/syntax-lab", editable = true }
```

```python
from rich.console import Console
from wes_syntax import syntax

Console().print(syntax(markdown_text, "markdown", word_wrap=True))
Console().print(syntax(python_source, "python", grayscale=True))
```

`syntax()` returns a Rich `Syntax` renderable, usable inside panels/groups/trees.
It preserves the terminal background and forwards Rich options such as
`word_wrap` and `line_numbers`. `load_style()`, `make_style()`,
`style_for_lexer()`, `source_lexer()`, and `grayscale_color()` are available for lower-level uses.
`palette=` accepts another palette JSON path. The CLI and library share the same
implementation; the existing `palette.json` path is a symlink to the packaged
palette in `wes_syntax/palette.json`. Editable installs read palette edits on
each new renderable. Library calls do not invoke the explorer or image renderer.

Pygments' `diff` lexer uses our green for inserted lines, red for deleted lines,
blue for file headers, teal for hunk headers, and neutral context. Use
`syntax(patch_text, "diff")` or pass a `.diff`/`.patch` file to the preview tool.
This colors an existing diff; it does not compute differences or syntax-highlight
the source language within changed lines.

`syntax(patch_text, "apply-patch")` extends those diff rules for tool patches:
Add File is green, Delete File red, Update File blue, Move to teal, and
Begin/End Patch or End of File markers slate. Hunk bodies retain ordinary diff
colors. This lexer only highlights text; it never applies a patch.
