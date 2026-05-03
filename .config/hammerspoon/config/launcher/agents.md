---
repo_path: .config/hammerspoon/config/launcher/
---
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
* **Cancel functions** – every handler returns a cancel function stored in
  `currentCancelFunc`.  It is called on every keystroke *and* when `onChoice`
  fires (escape or selection), ensuring no stale tasks or open windows linger.
* **WebView companion** – the `o ` (LLM) mode breaks away from the chooser
  results list entirely.  It collapses the chooser to the input bar only
  (`chooser:rows(0)`) and opens a separate `hs.webview` window to render the
  streamed AI response as markdown.  All other modes use normal chooser results.
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
| `o `   | `o explain recursion` | **LLM completion** – streams response into a WebView (see below). |
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

## LLM WebView (`o ` mode)
The `o ` prefix is the first mode to break away from the chooser results list,
serving as a prototype for a future custom launcher UI.

**Flow:**
1. `handleLLM` is called; it collapses the chooser to input-bar-only
   (`chooser:rows(0)`) and calls `createLLMWebView()`.
2. `createLLMWebView()` opens an `hs.webview` window (WKWebKit, nonactivating,
   floating level, `bringToFront`) positioned below the chooser.
3. The view loads `getLLMWebViewHTML()` — a self‑contained HTML page with a dark
   VSCode‑style theme, `marked.js` (markdown rendering) and `highlight.js`
   (syntax highlighting) loaded from CDN.  Plain‑text fallbacks are included for
   offline use.
4. A streaming `curl` POST hits `LLM_SERVER/v1/chat/completions`.  Each SSE
   chunk updates `llmCurrentResponse` and calls `pushLLMContent()`, which calls
   `webview:evaluateJavaScript("updateContent(...)")`.
5. When streaming completes, `setComplete()` is called in the page JS; it removes
   the blinking cursor and **re-executes any `<script>` tags** found in the
   rendered content (browsers don't run scripts injected via `innerHTML`).
6. Dismissing the launcher (escape or any `onChoice` call) invokes
   `currentCancelFunc()` → terminates curl + calls `closeLLMWebView()` →
   deletes the webview and restores `chooser:rows(10)`.

**Rendering capabilities the model is told about (system prompt):**
- GitHub Flavored Markdown with syntax-highlighted fenced code blocks
- Raw HTML passes through (`html: true` in marked.js) — `<div>`, `<canvas>`,
  `<svg>`, `<style>` tags render directly
- `<script>` tags execute after streaming completes — interactive JS, animations,
  canvas visualizations all work
- Dark VSCode-style theme is pre-applied; can be overridden with inline `<style>`

**Key helpers:**
| Function | Purpose |
|----------|---------|
| `jsStr(s)` | Escapes a Lua string for embedding in a JS string literal (replaces `hs.json.encode` which only accepts tables) |
| `getLLMWebViewHTML()` | Returns the full self-contained HTML template |
| `createLLMWebView()` | Creates, styles, and shows the WebView window |
| `pushLLMContent()` | Calls `evaluateJavaScript` with current accumulated response |
| `closeLLMWebView()` | Deletes the webview, resets state, restores chooser rows |

**Module-level state:**
```
llmWebView          -- active hs.webview instance (nil when closed)
llmWebViewReady     -- true after didFinishNavigation fires
llmCurrentQuery     -- query string shown in WebView header
llmCurrentResponse  -- accumulated response text (markdown)
llmIsThinking       -- true while model is in reasoning/thinking phase
```

**TODO:** multiple parallel generations — each generation gets its own card,
identified by a `generationId`, shown side-by-side or stacked with headers.

## Bookmarks & Actions
The `bookmarks` table defines static entries (trash, lock, sleep, logout, …) each
with a `name`, `keywords`, display `text`, `subText`, and an icon.  When a bookmark
is selected the corresponding function in `bookmarkActions` is executed – e.g.
`trash` runs `open "trash://"`, `mute` toggles the default output device, and
`dark` flips macOS dark mode via AppleScript.

## Courtesy Commands

* Agents that modify the Hammerspoon config should reload it with `hs -C -c 'hs.reload()'`
  before asking the user to test the changes.
  Note: `-C` mirrors console log output, so you may see CFMessagePort errors like
  "dropping corrupt reply Mach message". These are harmless and can be ignored.

## Emoji Picker Cache
* Cache directory: `~/.local/share/hammerspoon`.
* Cache file: `emoji-data.json` – downloaded from the Unicode CLDR repo.
* Cache validity: 30 days (`EMOJI_CACHE_MAX_AGE`).  If stale, the module updates
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
* **Always first** – `currentCancelFunc()` is called to terminate any in-flight
  task and close any open WebView.
* **Bookmarks** – run the mapped action.
* **Calculator** – result is copied to the clipboard and a brief alert shown.
* **LLM** – no chooser selection (results list is empty); closing the launcher
  dismisses the WebView.
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
  every keystroke and on chooser close to prevent stray processes.
* The `o ` mode is the **prototype for a custom launcher UI** pattern: use
  `hs.chooser` only for the input box (`rows(0)` hides results), and show output
  in a custom `hs.webview` or other window.  Future modes can follow this pattern
  to escape the limitations of the chooser results list.
* The module relies heavily on **Spotlight (`mdfind`)** and **`stdbuf -o0`** to get
  unbuffered line‑by‑line output.
* Adding a new mode typically requires:
  1. A handler function `handle<Mode>(query, searchId, callback)` that returns a
     cancel function.
  2. A prefix check in `onQueryChange` that calls the handler.
  3. (Optional) an entry in `showModes()` for the help screen.
* Keep naming consistent with the Lua‑style conventions used throughout the
  project (snake_case for functions/variables, PascalCase for classes).
* `hs.json.encode` only accepts Lua tables — use the local `jsStr(s)` helper to
  safely embed strings in `evaluateJavaScript` calls.

## APIs

- https://www.hammerspoon.org/docs/hs.chooser.html
- https://www.hammerspoon.org/docs/hs.webview.html

---
*File maintained by the AI assistant as a quick reference for the
Hammerspoon launcher module.*
