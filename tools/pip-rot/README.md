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
- `Alt+Space` launcher: **Shift+Return** reveals a search result in Pip Rot;
  **Command+Shift+Return** reveals it in Finder (Command+Return also retains Finder reveal).

The filesystem model loads listings in the background and watches for changes.
The tree supports dragging files out; inline rename, moves, and incoming drops
remain disabled. Explicit
actions can create directories or move selected items to Trash.
The columns are Name, Size, Duration, and Date Modified (Type is hidden).
Duration appears when videos appear in the current directory or an expanded subdirectory. Collapsing the
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

## File actions and other consumers

`Option+Command+/` opens the existing Hammerspoon file-action picker from Finder
or Pip Rot. It captures the current selection before showing the picker. In an
empty tree (or with no selected rows), Pip Rot supplies the tab's root directory.
Multiple rows can be selected with Command/Shift. Existing Copy Path, Copy File
Contents, Open Terminal Here, Reveal, and other actions use this captured context.
New Nested Folder uses the selected directory directly when invoked from Pip Rot;
the Finder action retains its existing Finder workflow.

Native Pip Rot actions are also available in File and the tree's context menu:

| Key | Action |
| --- | --- |
| ⌘OptionT | Open Terminal Here (iTerm; selected directory or file's parent) |
| ⌘ShiftC | Copy Path (raw paths, one per line) |
| ⌘OptionShiftC | Copy File Contents (text files) |
| ⌘ShiftN | New Nested Directory inside the selected directory, or file's parent |
| ⌘Backspace | Move explicitly selected files/directories to Trash |

New Nested Directory accepts paths such as `drafts/notes`, selects the created
directory, and refuses existing targets or `..` traversal. The filesystem view
still disables inline rename and incoming drops; creation and moving items to
Trash are explicit actions. The Hammerspoon Copy Path action retains its existing shell-escaped output.

Pip Rot publishes selection changes atomically to a private per-process file:

```
~/.local/state/pip-rot/context-<pid>.json
```

Example contract:

```json
{
  "version": 1,
  "kind": "files",
  "source": "pip-rot",
  "pid": 12345,
  "selection_explicit": true,
  "directory": "/Users/you/Movies",
  "paths": ["/Users/you/Movies/example.mp4"],
  "window_title": "/Users/you/Movies — Pip Rot"
}
```

Consumers should match the PID and window title to a live Pip Rot window before
using the record. Files use mode 0600, live under a directory created with mode
0700, and are removed on normal window close. A crash can leave a stale record;
the picker rejects mismatched PIDs/windows. Each process currently owns one
window, with any number of tabs. No socket or command protocol is implemented.

Additional checks (from the repository root):

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/actions_test.py
lua tools/pip-rot/action_context_test.lua
```

Move to Trash uses Homebrew’s `trash -F` (`brew install trash`), asking Finder to preserve
its **Put Back** metadata. It runs asynchronously and reports failures. The
Hammerspoon picker uses the same command instead of moving files with `mv`.
There is no permanent-delete, empty-trash, or Pip Rot ⌘Z action. Restore through
Finder's Trash → Put Back. The native shortcut applies to the tree, so editing
text in the location field keeps normal text-editing behavior. No selected rows
means no trash operation; the picker hides Trash for a directory fallback
(`selection_explicit: false`).

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/trash_test.py
```

Both interfaces use exactly `/opt/homebrew/bin/trash`, regardless of PATH,
with no fallback to another executable. macOS also ships a
different `/usr/bin/trash` that does not accept `-F`; it is not used here.

## Preview

Focus the tree and press **Space** (or choose View → Quick Look) to preview the
selected file(s) or directory using macOS `/usr/bin/qlmanage -p`. Press Space
again from the tree to close that preview. If the selection changed, Space
replaces the old preview with the new selection. Quick Look owns its floating
window and its native close/Escape behavior. Space inside the location field
remains ordinary typing.

Pip Rot owns only the helper it launches and closes it when its browser window
closes. Selection changes alone do not update a running preview in this first
version. `preview.py:preview_command` is the dispatch point for future
format-specific overrides; all formats currently use Quick Look. No bat/jq
renderer is implemented yet.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/preview_test.py
```

## Drag files into other apps

Drag a selected file (or multiple selected rows) out of Pip Rot into another
application to open/import it—for example, drop a MOV/MKV onto Audacity.
Pip Rot exports native local-file URLs and offers **copy only**, so it does not
move or remove the source files. The receiving application decides whether it
supports that file format and drop destination. Pip Rot does not yet accept
incoming drops or move/copy files between its folders/tabs.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/drag_test.py
```
