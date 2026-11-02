# Pip Rot

Rotten to the core. A small Python / Qt file browser with an expandable tree per tab.

```sh
pip-rot                         # current directory
pip-rot ~/Movies ~/Downloads     # one tab per directory
pip-rot --reveal ~/Movies/a.mp4  # select the item in its parent
```

Xonsh adds this directory to PATH on startup. In an existing shell:

```xonsh
$PATH.insert(0, $WES_DOTFILES + '/tools/pip-rot')
```

Or run `./tools/pip-rot/pip-rot` directly from the checkout. Requires `uv` and
Python 3.12+; uv installs the isolated, locked Qt dependency on first launch.
Each invocation opens a separate window. Tabs and layouts are currently in memory.

| Key (macOS) | Action |
| --- | --- |
| ↑ / ↓, type a name | Select a file or directory |
| → / ← | Expand / collapse a directory |
| ⌘Return | Open selected directory in a new tab |
| ⌘T | Duplicate current tab's root |
| ⌘O | Open file with its default app, or directory in a new tab |
| ⌘W | Close tab (last tab closes the window) |
| ⌘L | Enter a directory path (Return to navigate in current tab) |
| Option↑ | Parent directory |
| ControlTab / ControlShiftTab | Next / previous tab |
| ⌘Shift. | Toggle hidden files across tabs |

Double-click a file to open it; double-click a directory to expand it.
Right-click offers opening in a new tab and copying the path. File, View, and
application menus expose the keyboard actions too. On other platforms, Qt maps
Command shortcuts to Control.

Hammerspoon integration:

- `Option+Command+/` file actions: **Reveal in Pip Rot**, alongside **Reveal in Finder**.
- `Alt+Space` launcher: **Command+Shift+Return** reveals a search result in Pip Rot;
  Command or Shift alone still reveals it in Finder.

The filesystem model loads listings in the background and watches for changes.
It is read-only: no rename, move, delete, or drag-and-drop operations yet.
The initial columns are Name, Size, Type, and Date Modified. Media duration is a
future addition; this app does not read or modify Finder's `.DS_Store` files.

Verification:

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/smoke_test.py
```
