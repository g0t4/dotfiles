# Hammerspoon Launcher – Overview (agents.md)

## Purpose
`config/launcher/init.lua` implements a **universal launcher** that is invoked with
`Alt+Space`.  It presents an `hs.chooser` UI where the user can type a query and
receive live, incremental results from a variety of back‑ends.  The module
behaves like a *command palette* for macOS, offering fast access to files,
applications, system settings, web searches, LLM completions, and many other
utilities.

## Core Architecture
* **`hs.chooser`** – the UI component.  `onQueryChange` is the query‑changed
  callback; it cancels any previous async task, increments a global
  `currentSearchId`, and dispatches the query to the appropriate handler.
* **Async handlers** – each mode spawns an `hs.task` (or `hs.execute`) that
  streams results back via a `callback(searchId, results)` closure.  The
  `searchId` guards against race conditions from overlapping searches.
* **Result merging** – the default (file‑search) mode merges bookmark matches
  (`matchBookmarks`) with Spotlight (`mdfind`) results before feeding the
  chooser.
* **History** – queries are persisted in
  `~/.local/share/hammerspoon/launcher-history.txt`.  `Cmd+Up/Down` navigates the
  history while the chooser is active.
* **Hotkey bindings** – while the chooser is visible the module registers:
  * `Cmd+R` / `Ctrl+R` – refresh the current query.
  * `Cmd+Up` / `Cmd+Down` – walk through the query history.
  * Tab – prefix‑completion (see *Tab Completion* below).

## Modes (prefixes)
| Prefix | Example | Description |
|--------|---------|-------------|
| `b `   | `b lock` | **Bookmarks** – fixed actions (trash, lock, mute, etc.). |
| `a `   | `a safari` | **Application search** – uses Spotlight to list apps. |
| `s `   | `s network` | **System Settings** – opens a specific pane via its identifier. |
| `d `   | `d Downloads` | **Directory search** – Spotlight limited to folders. |
| `define ` | `define recursion` | **Dictionary lookup** – CoreServices via a temporary Python script. |
| `g `   | `g hammerspoon docs` | **Google web search** – opens a URL in the default browser. |
| `l `   | `l 2+2` | **Lua calculator** – evaluates a Lua expression and shows the result. |
| `o `   | `o explain recursion` | **LLM completion** – streams a chat completion from `http://ask.lan:8013`. |
| `f `   | `f pkill hammerspoon` | **Fish shell command** – runs the command with `/opt/homebrew/bin/fish`. |
| `py `  | `py print(2+2)` | **Python code** – executes via the repository‑wide virtualenv. |
| `e `   | `e smile` | **Emoji picker** – loads CLDR emoji data (cached) and filters by keyword. |
| `v `   | `v repos ask` | **Live filter** – two‑stage: `mdfind` broad filter + fuzzy refine. |
| (none) | `README.md` | **File search** – default Spotlight (`mdfind`) file search. |
| `/` or `~` | `/Applications` | **Path browsing** – shows folder contents; `Enter` opens or reveals in Finder. |

### Tab Completion
* **Shortcuts** – typing a single‑character prefix (`a`, `b`, `s`, `d`, …) and pressing
  `Tab` expands it to `<prefix> `.
* **Aliases** – e.g. `app` → `a `, `book` → `b `, `google` → `g `, etc.
* **Bookmark keywords** – typing a bookmark keyword (e.g. `tra`) and Tab expands to the
  bookmark name (`trash`).

## Bookmarks & Actions
The `bookmarks` table defines static entries (trash, lock, sleep, logout, …) each
with a `name`, `keywords`, display `text`, `subText`, and an icon.  When a bookmark
is selected the corresponding function in `bookmarkActions` is executed – e.g.
`trash` runs `open "trash://"`, `mute` toggles the default output device, and
`dark` flips macOS dark mode via AppleScript.

## Emoji Picker Cache
* Cache directory: `~/.local/share/hammerspoon`.
* Cache file: `emoji-data.json` – downloaded from the Unicode CLDR repo.
* Cache validity: 30 days (`EMOJI_CACHE_MAX_AGE`).  If stale, the module updates
  the file in the background and reloads the JSON.
* Data structure: `{emoji = {default = {keywords…}}}` – only the `default`
  keyword list is used for searching.

## History Persistence
* File: `~/.local/share/hammerspoon/launcher-history.txt`.
* Loaded on `M.init()`, saved after each query via `addToHistory`.
* Maximum items: `MAX_HISTORY_ITEMS = 1000`.
* Navigation: `Cmd+Up` (older) and `Cmd+Down` (newer, or back to empty).

## Selection Behaviour
When a chooser entry is chosen (`onChoice`):
* **Bookmarks** – run the mapped action.
* **Calculator / LLM** – result is copied to the clipboard and a brief alert shown.
* **Applications** – opened via `open "<path>"`.
* **Dictionary** – copies definition or opens the Dictionary app.
* **Web search** – opens the constructed Google URL.
* **System Settings** – opens the pane using the `x-apple.systempreferences:` URL scheme.
* **Fish / Python** – executes the command, copies any output, and shows an alert.
* **Emoji** – copies the emoji and simulates `Cmd+V` to paste it immediately.
* **File / Path** – default action opens the item; with `Cmd`/`Shift` it reveals in Finder;
  with `Alt` it copies the absolute path.

## Implementation Notes (for future modifications)
* All async searches return a **cancel function**; `currentCancelFunc` is invoked on
  every keystroke to prevent stray processes.
* The module relies heavily on **Spotlight (`mdfind`)** and **`stdbuf -o0`** to get
  unbuffered line‑by‑line output.
* Adding a new mode typically requires:
  1. A handler function `handle<Mode>(query, searchId, callback)` that returns a
     cancel function.
  2. A prefix check in `onQueryChange` that calls the handler.
  3. (Optional) an entry in `showModes()` for the help screen.
* Keep naming consistent with the Lua‑style conventions used throughout the
  project (snake_case for functions/variables, PascalCase for classes).

---
*File generated by the AI assistant to serve as a quick reference for the
Hammerspoon launcher module.*

