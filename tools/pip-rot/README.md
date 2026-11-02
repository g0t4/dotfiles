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
| ⌘↓ / ⌘O | Enter directory in current tab, or open file with its default app |
| ⌘W | Close tab (last tab closes the window) |
| ⌘L | Enter a directory path (Return to navigate in current tab) |
| ⌘↑ / Option↑ | Parent directory |
| ⌘[ / ⌘] | Back / forward in this tab’s directory history |
| ControlTab / ControlShiftTab | Next / previous tab |
| ControlPageDown / ControlPageUp | Next / previous tab |
| ⌘Shift. | Toggle hidden files across tabs |

Double-click a file to open it; double-click a directory to expand it.
Right-click offers opening in a new tab and copying the path. File, View, and
application menus expose the keyboard actions too. On other platforms, Qt maps
Command shortcuts to Control.

Hammerspoon integration:

- Type `pip` or `pip-rot` in the launcher (or `b pip`) to open Pip Rot at Home.
- `Option+Command+/` file actions: **Reveal in Pip Rot**, alongside **Reveal in Finder**.
- `Alt+Space` launcher: **Command+Shift+Return** reveals a search result in Pip Rot;
  Command or Shift alone still reveals it in Finder.

The filesystem model loads listings in the background and watches for changes.
It is read-only: no rename, move, delete, or drag-and-drop operations yet.
The columns are Name, Size, Type, and Date Modified, plus Duration when videos
appear in the current directory or an expanded subdirectory. Collapsing the
last video-containing branch hides Duration again. Common video extensions are
recognized case-insensitively. Only visible video rows are probed, with two
background jobs maximum and an eight-second timeout per probe. Results are
cached across tabs for this window and invalidated when a file's size or
modification time changes. Duration is display-only; sort by the other columns.

Duration uses `ffprobe` (`brew install ffmpeg` if missing). `…` means loading;
`—` means unavailable, unsupported, or corrupt media. Files and folders that
are not videos have blank duration cells. Long durations use `h:mm:ss`.
This app does not read or modify Finder's `.DS_Store` files.

Verification:

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/smoke_test.py
```

With ffmpeg installed, verify real video metadata too:

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/media_test.py
```

Each tab keeps its own directory history, including selection and scroll position.
Going to a directory with ⌘L or going up records a visit; expanding a folder does
not. Navigating somewhere new after going back discards the forward history.
Back/Forward also appear in the Go menu and location toolbar. History lasts for
the current window session.
