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
| ⌘W / F8 | Close tab (last tab closes the window) |
| F9 | Close current window |
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
The tree supports file dragging, directory drop targets, and explicit inline
rename. Explicit actions can also create directories or move selected items to Trash.
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
supports directory drops; renaming, creation, and moving items to Trash are
explicit actions. The Hammerspoon Copy Path action retains its existing shell-escaped output.

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
Pip Rot exports native local-file URLs with copy as the outbound default.
The receiving application decides whether it supports that format and drop
destination. Pip Rot never performs generic source-row deletion after an
external drop; filesystem destinations handle their own transfers.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/drag_test.py
```

## Shared z directory jumper

**Control+P** opens a fuzzy directory picker using the exact same `z` backend and
database as Xonsh. On macOS this is the physical Control key, matching Neovim.

- Start typing to fuzzy-match directory paths; multiple words narrow the match.
- Up/Down choose a result while the query keeps focus.
- Return navigates in the current tab and records normal Back/Forward history.
- Command+Return opens the result in a new tab.
- Escape cancels and returns focus to the file tree.
- The ordering selector switches between **Most recent** (default) and
  **Frequent + recent (z)**. Search uses only the shared z history; it does not
  crawl the filesystem. Use Command+L for directories outside that history.

Opening a directory, navigating, or changing to a different directory tab records
a visit through the existing shell backend. Expanding folders and changing file
selection do not add visits. Queries and visit recording run in a serialized
background queue, keeping shell startup/database work off the UI thread.

The backend is `.config/xonsh/lib/wes_fish_z.py`, which currently delegates to
Fish's `__z`/`__z_add` and honors its configured `Z_DATA` (currently
`~/.local/share/z/data`). There is no separate Pip Rot directory database.
Pip Rot rereads it whenever the picker opens or its ordering changes.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/directory_picker_test.py
```

## Dock icon

The running process uses the artwork in `assets/pip-rot.png` through Qt's
application icon setting. Relaunch Pip Rot to pick it up; a full `.app` bundle
is not required for this runtime icon. It does not install a persistent Dock
launcher. Artwork provenance and the generation prompt are in `assets/README.md`.

## Rename

Select one file or directory and press **Command+R** (File → Rename, or the
context menu). Qt opens an inline editor in the Name column. Return commits;
Escape cancels. Typing to jump and double-click behavior remain unchanged;
editing begins only through the Rename action. Existing destination names are
not overwritten, and errors appear in the status bar. The renamed item stays
selected and its action-picker context updates. Space and Command+Backspace in
the editor perform normal text editing, rather than previewing/trashing files.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/rename_test.py
```

## Restart App

From Pip Rot, open the Hammerspoon action picker (`Option+Command+/`) and choose
**Restart App**. File → Restart App is also available inside Pip Rot. Relaunch
once after installing this feature so the running process advertises support.

Pip Rot writes a private session snapshot, starts a new process using the same
Python virtualenv and current checkout, then closes the original window only
when the replacement publishes a ready context. The snapshot restores tab roots,
active tab, current item, scroll position, window size, and hidden-file setting.
Back/Forward history and preview windows are not restored yet. If startup fails
(including a directory no longer existing), the original stays open and reports
the local `~/.local/state/pip-rot/restart-<pid>.log` path.

`app_actions.lua` holds app-specific restart handlers. Pip Rot advertises the
`restart` capability in its context. The picker atomically writes:

```json
{"version": 1, "pid": 12345, "command": "restart"}
```

to `~/.local/state/pip-rot/request-12345.json`. Pip Rot checks only its own request
file, accepts the versioned restart command addressed to its PID, and consumes it.
There is no generic process-kill/relaunch fallback for other apps.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/restart_test.py
lua tools/pip-rot/app_actions_test.lua
```

## Rearrange files with drag and drop

- Drag from Pip Rot onto a **directory row** to move files/folders into it.
- Hold **Option** while dropping to copy instead.
- Drop onto **blank tree space** to use that tab's root directory.
- Hover over another tab to switch to it, then drop into its tree. Hover over
  a collapsed directory to expand it. Edge scrolling is provided by Qt.
- Files dragged in from Finder or other apps **copy** into the chosen directory,
  preserving those external sources. Only local-file URLs are accepted.
- A target outline and the status bar identify the destination and Move/Copy
  action. Dropping onto an ordinary file is rejected.

Operations run in a background queue. Preflight rejects existing destination
names (including dangling symlinks), duplicate basenames, and moving a directory
inside itself. Dropping onto the same parent is a no-op for moves. Directories
are not merged and targets are never overwritten: macOS `renamex_np` with
`RENAME_EXCL` also protects against a name appearing after preflight.

Copies use `ditto` to preserve macOS metadata and stage their output on the
destination volume before publishing it. Moves use an atomic rename on the same
volume. Cross-volume moves are blocked during preflight (with an EXDEV guard at
execution too); there is no copy-and-delete fallback. The warning offers **Open
in Finder**, revealing the source and opening the destination so you can finish
there. Cross-volume copies remain supported and leave their sources untouched.
Failures are reported, including completed counts if part of a batch succeeded.
While a transfer is running, Pip Rot refuses to close the last tab, close the
window, or restart; retry after it finishes. Open tab/history paths within this window follow
directories moved by its transfer queue. Transfer undo is not implemented yet.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/transfers_test.py
```

## Duplicate

Select one file or directory and press **Command+D** (File → Duplicate, or the
context menu). Pip Rot makes a separate sibling copy in the background and then
opens its name for inline editing, selecting the basename without its extension.
Return accepts your edit; Escape keeps the automatically named duplicate.
If you navigate or move focus elsewhere during a large copy, completion does not
steal focus to start renaming.

Names use the lowest available `~N` starting at 2:

```
clip.mov       → clip~2.mov
clip~2.mov     → clip~3.mov
lesson 12.mov  → lesson 12~2.mov
archive.tar.gz → archive~2.tar.gz
folder.v2/     → folder.v2~2/
```

Existing `~N` suffixes (N ≥ 2) are recognized; meaningful ordinary trailing
numbers are left alone. Hidden files and known compound tar extensions are
preserved. Names are allocated when the background job runs, and publication is
exclusive. If another process takes a candidate name during the copy, the staged
data is reused under the next free name. Directories are copied as new siblings;
there is no merge or overwrite. Symlinks are duplicated as links.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/duplicate_test.py
```

## Status-line warnings

Rejected actions (for example, duplicating or renaming multiple selected items)
show an amber status-line band with high-contrast text and a warning glyph.
They keep keyboard focus in the tree and do not open a prompt. Routine updates
use normal styling; message expiry or clearing also resets the warning treatment.
The same warning style covers rename failures, missing selection, history/context
errors, and attempts to close/restart during a transfer.

## Stream Deck

The startup-loaded global Hammerspoon helper launches asynchronously:

```lua
StreamDeckPipRot()             -- Home
StreamDeckPipRot("~/Movies")   -- directory
StreamDeckPipRot("/absolute/path/to/file.mov") -- select file in its parent
```

From a shell action, use `/opt/homebrew/bin/hs -c 'StreamDeckPipRot()'`.
It returns immediately; each invocation currently opens a new Pip Rot process.

## Address bar

Entering an existing file path navigates to its containing directory and updates
the address bar to that directory. Relative paths start at the current tab's
directory; `~` expands to Home.

For a missing path, Pip Rot walks upward to the nearest existing directory and
asks whether that is what you meant. **Yes** navigates there and updates the
address bar. **No** (the default) keeps the typed address available for editing
and leaves the directory and navigation history unchanged.

The integration test submits addresses with Return and clicks both buttons in
real Qt dialogs, checking directory, address bar, and back/forward history:

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/location_test.py
```
