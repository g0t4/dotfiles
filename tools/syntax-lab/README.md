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
