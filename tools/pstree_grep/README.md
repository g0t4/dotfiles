# pstree_grep

Search process names and full arguments, then show the complete descendant trees
of the rootmost matches. Nested matches appear once, with their tree context.

```sh
pstree_grep                 # live TUI, start typing a regex
pstree_grep --tui codex     # live TUI with an initial filter
pstree_grep codex           # original printed snapshot
pstree_grep -f codex        # snapshot with full command lines
```

The existing Fish/Xonsh command still works. From the dotfiles root you can also
run `.venv/bin/python -m tools.pstree_grep`. Dependencies are in the root
`pyproject.toml` / `uv.lock`.

The TUI refreshes processes every second, independently of typing. Matches are
pink with `*`; compact names can match arguments you cannot see. The actual
running Python helper is marked `[self: pstree_grep]`. Colors come from
syntax-lab's shared palette, with pink reserved for matches.

| Key | Action |
| --- | --- |
| Type | Edit the regex in the initially focused filter |
| Esc / Enter | Browse the tree |
| `/` | Return to the filter |
| Up / Down / PageUp / PageDown | Scroll, including while editing the filter |
| Left / Right | Scroll horizontally while browsing |
| `f` / Ctrl+L | Toggle full commands (`f` while browsing) |
| `i` / Ctrl+G | Toggle case sensitivity (`i` while browsing) |
| `q` | Quit while browsing |
| F9 / Ctrl+C | Quit from anywhere |

Invalid regexes show an error and continue refreshing with the last valid filter.
Clearing the filter shows all trees. Refreshes preserve the scroll offset, bounded
by the remaining content. Nothing signals or changes the inspected processes.

Validation:

```sh
PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 .venv/bin/python -m pytest -q tools/pstree_grep/test_pstree_grep.py
```
