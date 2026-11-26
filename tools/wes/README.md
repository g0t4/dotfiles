# tools/wes

Wes's personal Python toolbox. Import with the repo root on your path
(e.g. `uv run` from the repo root):

```python
from tools.wes import print
print({"key": 42})  # dict rendered with the syntax-lab palette
```

## print

`tools.wes.print` wraps `rich.print` on a console themed from the
syntax-lab palette (`wes_syntax/palette.json` -- the same single source of
truth `highlight` uses). Palette edits apply on import.

- `print(*objects, sep=" ", end="\n", file=None, flush=False, **kwargs)` --
  same as `rich.print`, plus any `Console.print` keyword
  (`style=`, `highlight=`, `markup=`, ...).
- `console` -- the module-level themed `Console` (stdout).
- `make_console(file=None)` -- a fresh themed console, e.g. for a file.
- `wes_theme(palette=None, grayscale=False)` -- the underlying
  `rich.theme.Theme`.

Palette roles are theme names, so markup works:

```python
print("[keyword]def[/keyword] [function]greet[/function]([string]name[/string])")
```

Tests are co-located (`print_test.py`, `theme_test.py`); run with
`uv run pytest tools/wes`.
