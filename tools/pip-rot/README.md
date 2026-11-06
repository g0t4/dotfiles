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
| ⌘` / ⌘Shift` | Next / previous Pip Rot window across processes (Hammerspoon) |
| ⌘L | Enter a directory path (Return to navigate in current tab) |
| ⌘↑ / Option↑ | Move the tab root up a directory |
| Shift+P | Select the parent node within the tree (stops at the tab root) |
| < / > | Previous / next sibling, skipping expanded descendants (no wrapping) |
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
New Folder Inside uses the selected directory directly when invoked from Pip Rot;
the Finder action retains its existing Finder workflow.

Native Pip Rot actions are also available in File and the tree's context menu:

| Key | Action |
| --- | --- |
| ⌘OptionT | Open Terminal Here (iTerm; selected directory or file's parent) |
| ⌘ShiftC | Copy Path (raw paths, one per line) |
| ⌘OptionShiftC | Copy File Contents (text files) |
| ⌃⌘N | New Folder with Selection, then inline rename (items must share a parent) |
| ⌘ShiftN | New Folder Inside: create immediately inside the selected directory, or file's parent, then rename inline |
| File / action picker | New Path…: prompt for a relative file or directory path (`mkpath` semantics) |
| ⌘Backspace | Move explicitly selected files/directories to Trash |

New Path… follows the shell `mkpath` convention: `drafts/notes/` creates a
directory; `drafts/notes.md` creates a file. Missing parents are created in both
cases, then the result is selected. Existing directories are accepted; existing
files are touched without truncating their contents. Absolute paths and `..`
traversal are refused. The filesystem view
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

Select one file or directory and press **Return/Enter** or **Command+R** (File → Rename, or the
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

## Directory picker everywhere

Hammerspoon provides **Control+Option+P** globally and **Control+P** inside
standard macOS Open/Save panels. The latter passes through unchanged elsewhere,
including Neovim and terminals. The picker reuses Pip Rot's shared z history.

- Type a fuzzy directory query; use arrows to select a result.
- **Return** uses the folder in the active Open/Save dialog, or opens it in Pip Rot elsewhere.
- **Command+Return** explicitly opens the folder in Pip Rot, even from a file dialog.
- **Option+Return** copies the full folder path and returns focus to the original app;
  it does not navigate the dialog or open a browser.
- **Control+R** toggles fuzzy search and `zr` semantic search, preserving the query.
  Semantic search uses the existing embedding/reranking service at `build21.lan:8015`.
  If unavailable, its error appears in the picker; Control+R returns to local fuzzy search.
- **Escape / F9** cancels.
- From an Open/Save panel, selection navigates that same panel through its Go to
  Folder sheet. The filename is preserved; you still press Open/Save yourself.
- Elsewhere, selection opens the directory in Pip Rot.

The panel handoff uses Accessibility identifiers (`save-panel` / `open-panel`,
`GoToWindow`, `PathTextField`). Custom app dialogs without these identifiers are
not recognized. It sets the path directly through Accessibility, without using
the clipboard. Missing/closed panels abort the handoff.

Standalone selection for other consumers (JSON with `path` and `action`
(`use`, `open`, or `copy`) on stdout; empty stdout on cancel):

```sh
uv run --project tools/pip-rot python tools/pip-rot/directory_picker.py
```

## File icons

The tree uses bundled `nvim-web-devicons` filename/extension mappings and colors,
with light/dark variants selected from Qt's palette. SauceCodePro Nerd Font is
preferred, followed by another installed Nerd Font. Icons are rendered separately
from filenames, cached, and drawn at Retina resolution. Directories get a folder
glyph; unknown extensions get a generic file glyph. Without a suitable font or
when a glyph is unavailable, Qt's native icon remains the fallback. Neovim is
not needed at runtime. Upstream attribution and license are in `assets/devicons`.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/file_icons_test.py
```

## Compare file contents

Select exactly two regular files and choose **Compare File Contents** from the
Hammerspoon file-actions picker (Option+Command+/). `/usr/bin/cmp -s` compares
bytes in the background, including binary files, without opening a diff viewer
or changing the clipboard. Results distinguish identical files, different files,
and comparison errors. Pip Rot receives a status-line message for 15 seconds;
identical files use a prominent green band and checkmark; differences/errors use
the amber warning style. Finder and older Pip Rot
processes get a Hammerspoon alert instead. Restart Pip Rot to enable status delivery.

The comparison ignores names and metadata. It reads live files, so avoid modifying
them while comparing. The versioned `status-<pid>.json` transport is consumed by
Pip Rot's existing request timer and checks the destination PID.

```sh
lua tools/pip-rot/compare_files_test.lua
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/comparison_status_test.py
```

## Refresh and filesystem diagnostics

Qt normally watches the filesystem automatically. **F5** or **View → Refresh**
rebuilds the current tab's filesystem model to force a fresh read, preserving
surviving expanded folders, selected rows, current item, scroll position, filters,
sort order, and navigation history. Cmd+R remains Rename.

Refresh diagnostics append to `~/.local/share/devtools/pip-rot.log`, rotating at
2 MB with two backups. Start/completion entries include the PID, root, and loaded
row counts for the root and expanded directories. A refresh still waiting after
five seconds logs the outstanding directories. If a view looks stale, press F5
and inspect these entries; they diagnose manual refreshes, not every OS watcher
event, and cannot reconstruct earlier missed events.

```sh
QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/refresh_test.py
```

The test disables watching, changes real files, triggers F5, then checks fresh
contents, nested expansions, multiple selection, scroll, history, repeated
refreshes, and diagnostic output.

Completed drag/drop transfers explicitly refresh affected tabs after filesystem
publication finishes, preserving tree state instead of depending solely on Qt's
watcher. A transfer finishing during a refresh queues another read afterward.
Diagnostics include transfer submission, completed source/target pairs, copy/move
mode, and errors alongside the refresh entries.

Explicit **Restart App** also snapshots expanded folders for each tab. Nested
expansions are restored as directories load, before selection and scroll are
restored; directories that no longer exist are skipped. This state exists only
in the restart handoff: ordinary launches do not resume prior expansions.

New Folder with Selection creates `New Folder` (or the next free `New Folder~2`,
`New Folder~3`, …), moves the selected items without overwriting, and starts
inline rename. Escape keeps the created folder and its contents. Moves run in
the background; if an error interrupts a move, completed items remain in the
new folder and the error reports the partial result.

Pip Rot advertises the `folder-actions` capability. Its app actions include
**New Folder Inside**, **New Folder with Selection** (explicit siblings only),
and **New Path…**. The launcher sends a versioned JSON request
to the captured process, with the captured directory and paths; Pip Rot rejects
stale selections and handles creation/selection/rename itself. Finder retains
its existing New Nested Folder AppleScript behavior. Restart Pip Rot once to
load the new capability. Ordinary folder creation and gathering share the inline
rename completion helper; path creation retains a prompt for slash-separated paths (trailing `/` means directory).

The first inline rename of a **new, empty folder** also accepts a relative path:
`drafts/notes.md` creates a file with its parents; `drafts/notes/` creates a directory
path. A plain name still renames the folder normally. Slash-containing input is
resolved relative to the temporary folder's parent, and the temporary folder is
removed/replaced only while empty. Existing destinations are refused, without
merging or overwriting. Absolute paths, `..`, paths inside the temporary folder,
and symlinks leading outside the creation directory are rejected. Escape or
finishing the first edit disables this behavior; later renames and folders with
gathered contents remain ordinary filename-only renames. Unlike the New Path…
prompt, this inline creation flow never touches an existing target.


### Inline path creation contract

Paths entered during the first rename of a new, empty folder are relative to
that folder's **parent**, not to the folder itself. Existing parent directories
are reused; only the missing suffix is created. For example, if `drafts/` already
contains other work, entering `drafts/new/notes.md` creates `new/notes.md` under
it without moving, replacing, or merging the existing work.

| Filesystem state | Result |
| --- | --- |
| All parents are missing | Create the parents and final file or directory. |
| Some or all parents already exist as directories | Reuse those parents and create the missing suffix. Existing contents stay intact. |
| A file occupies a required parent component | Refuse the path; preserve the file and temporary folder. |
| The final destination already exists as a file, directory, or symlink | Refuse the path; never overwrite, merge, or touch the destination. |
| The temporary folder acquired contents during editing | Refuse path conversion; preserve those contents. |

On a blocked conversion, the status line reports the error and the temporary
folder remains available for another ordinary rename. Missing parents created
by a failed attempt are removed only if still empty. This is not a general
transaction or an app-wide undo facility.

Keep this contract distinct from **New Path…**: that explicit prompt follows
`mkpath`/`touch` semantics, accepts existing directories, and touches existing
files without truncating them. Inline creation instead requires a fresh final
destination (except leaving the temporary folder itself unchanged with its
current name plus `/`). Future creation actions should explicitly choose which
contract they follow rather than accidentally inheriting overwrite behavior.

Regression coverage lives in `inline_path_test.py`: real Qt editor commits,
partially existing parents ending in files and directories, existing contents
and parent identity preserved, destination collisions, and conversion safety.
`actions_test.py` covers the separate New Path… prompt behavior.

Shift+P and sibling shortcuts operate only with tree focus. Rename/path editors
retain normal text input, lowercase `p` retains type-to-jump, and these selection
movements leave the tab root, expansions, and navigation history unchanged.

### Nested path pickers

Search beneath the current tab's directory with the shell's picker shortcuts:

| Shortcut | Source |
| --- | --- |
| ⌥⇧D | Directories |
| ⌥⇧F | Files and symlinks |
| ⌥⇧B | Files, directories, and symlinks |
| ⌥⇧U | Files and symlinks, including hidden/ignored paths |

These also appear in **Go**. Requires `fd`; lookup checks PATH, then
`~/.nix-profile/bin`, `/opt/homebrew/bin`, and `/usr/local/bin` so Hammerspoon
launches work without an interactive shell. Results arrive asynchronously;
Escape cancels the scan. Type to fuzzy filter, use Up/Down to select, Return to
navigate to a directory or reveal a file, and ⌘Return for a new tab.
Ctrl+P remains the shared z-history directory picker.

MRU is shared with Fish/Xonsh at `~/.cache/fzf-mru/<picker>/<sha1(cwd + newline)>`,
using the same relative-path format and 30-entry cap. Empty queries show recent
selections first, followed by fresh results; query scores rank matches with MRU
order breaking ties. Only accepted selections enter MRU. Newline-containing
filenames can be picked but are not written into the shell's line-based cache.

`path_picker.PathProvider` supplies a namespace, title, shortcut, and argv command.
Commands run in the tab root and emit NUL-delimited relative paths. The dialog
handles fuzzy matching, shared MRU, cancellation, and selection independently
of the producer, so another path-producing command can reuse it. Commands are
executed directly, without shell interpolation. This initial interface is for
path pickers; arbitrary non-path results would need a separate result handler.

Picker command startup, completion counts, and errors are recorded in
`~/.local/share/devtools/pip-rot.log`; failed commands also show an error in the picker.

### macOS development app

Run `./tools/pip-rot/install-macos.sh` to install `~/Applications/Pip Rot.app`.
The app has its own Dock/app-switcher identity and logo. Its py2app alias bundle
loads this checkout and virtualenv directly: edit and restart as usual. Reinstall
if you move the checkout or replace the Python environment. This is a local
development installation, not a portable app distribution.

The launcher and `pip-rot` command prefer the installed bundle executable;
without it they retain source execution. Explicit macOS folder opens work with
`open -a 'Pip Rot' ~/Downloads`. Folder-open events create new windows in the
existing process; direct command/launcher invocations retain separate processes.
Restart App uses the bundle too and preserves the selected window's session.

Finder remains the system default. Optional `install-macos.sh --set-default`
tries `duti` registration for `public.folder`; this macOS installation rejects
that operation with error -50. `--restore-default` restores the saved handler
only if Pip Rot is currently the default; `--uninstall` also moves the installed
bundle to Trash. No `public.directory` association is changed.

### Directory notes

Put Markdown in `.rotten.md` inside any directory. Pip Rot displays it above
that directory's files: above the tree for the tab root, or beneath the folder
name when expanded. Notes aren't extra selectable nodes, so navigation and file
actions continue to operate on real files and folders. The backing dotfile is
visible when Show Hidden Files is enabled. Press **⌘Shift+R** from the tree to
edit directory Markdown in place. Clicking a description does not start editing. **⌘Return** (Control+Return outside macOS) or **Save** writes
it; **Escape** or **Cancel** discards the draft and returns focus to the tree.
File → **Edit Directory Notes**, the tree context menu, and Pip Rot's launcher
App Actions also open the editor, including a blank field if no notes exist.
They target the selected directory, or a selected file's parent (the tab root
when nothing is selected). The file is created only on Save.

Saves replace `.rotten.md` atomically; last write wins. External updates never
replace an open draft. Save failures keep the draft open for retry. You can also
edit the file with your usual editor.
Changes, including atomic editor saves, update live. Moving or copying the whole
directory naturally carries its notes along.

Expanded-folder previews occupy at most 200 pixels. Enter the folder to read its
notes in the scrollable root box. Markdown images/resources are disabled; this
is a text surface. Reads are bounded to 64 KiB, with a truncation notice for
larger notes. Missing/unreadable notes display nothing. File notes are left for later.

### Shared file-open history

Double-click and keyboard opens record files after the default app handler accepts
an open. Browsing, selecting, revealing, and previewing do not record a file.
The Hammerspoon launcher's file opens use the same store. Code/editor and shell
activity are not tracked automatically.

History lives at `~/.local/state/file-history/history.sqlite3` (or beneath
`XDG_STATE_HOME`), with an absolute path, open count, and last-open timestamp.
SQLite transactions support independent Pip Rot processes and the launcher.
No contents are read and no directories are crawled. History errors are logged
without blocking the file open. A successful handler handoff does not prove that
the target app finished loading the document.

The launcher's command-less mode searches these files alongside the existing
shared z directory history. Words fuzzy-match filenames and parent paths; match
quality takes priority over usage. Empty input shows recent files and z directories.
Bookmarks and prefix hints still match when typing. Explicit path browsing and
prefixed search modes remain available. The z database is unchanged. Missing
paths are omitted from results but retained for disconnected drives; moved files
are learned at their new path when opened. History starts empty; picker selections
are not imported as opens.

To remove a remembered file, run from the dotfiles checkout:

```sh
.venv/bin/python .config/xonsh/lib/wes_file_history.py forget '/absolute/path/to/file'
```

Restart existing Pip Rot windows to activate tracking after an update.

### Launcher history inspector

Type `info report` in the Hammerspoon launcher to search remembered files and
z directories, **including missing paths**. Press Return to inspect metadata;
Escape closes the inspector. This does not open the file or record another use.
`info /absolute/path` and `info ~/path` also inspect paths that have never been
tracked. Paths supplied explicitly are treated literally, including spaces.

The inspector shows each history store, accepted-open counts or z rank, last
usage timestamps, match/usage scores, normal-search eligibility, and current
filesystem type, size, permissions, owner IDs, and timestamps. Missing paths are
retained; unavailable paths and broken symlinks are identified. Diagnostic
queries do not clean z or migrate/write the SQLite database. File-open source
attribution distinguishes new Pip Rot and launcher opens; older opens are marked
as predating source tracking. z cannot distinguish shell visits from Pip Rot
visits. Filesystem access time is shown separately from tracked usage.

For terminal diagnostics, use:

```sh
.venv/bin/python .config/xonsh/lib/wes_file_history.py info 'report'
```
