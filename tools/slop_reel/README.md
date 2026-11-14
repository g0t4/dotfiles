# Slop Reel

A local video inspection workbench: libmpv playback and waveform on the left,
a video inspection agent on the right. It shares LangChain connections and the
append-only trace serializer with Clanker, but runs in its own process/venv.

## Run

Requires `uv`, `ffmpeg`/`ffprobe`, and libmpv. On this machine libmpv is supplied
by Nix at `~/.nix-profile/lib/libmpv.dylib`; Homebrew's `/opt/homebrew/lib` is also
detected. `brew install mpv ffmpeg` supplies these dependencies on another Mac.

```sh
./tools/slop_reel/slop-reel '/path/to/video.mp4'
```

Fresh Xonsh sessions also have `slop-reel /path/to/video.mp4`.
The launcher provisions/uses `tools/slop_reel/.venv` with uv.
Pass one or more video paths; each opens a review window. With no paths, a launch
screen offers a file picker and accepts dropped files. **⌘O** opens more videos.

## macOS application

```sh
./tools/slop_reel/install-macos.sh
open -a 'Slop Reel' '/path/to/video.mp4'
```

The installer builds and registers `~/Applications/Slop Reel.app`, with a dedicated
icon, Dock identity, app-switcher entry, and video document types for Finder's
**Open With** menu. Launch it from Applications/Dock/Spotlight to select a file,
drop videos onto its Dock icon or launch screen, or use **File → Open Video…**.
Opening an already-open video focuses its existing review and conversation;
different videos have independent playback and traces. **⌘W** closes the current
window; **⌘Q** or **F9** quits and closes all review windows, stopping their work.

`sr`/`slop-reel` prefer the installed bundle executable and keep their original
source/uv fallback when it is absent. Direct CLI invocations start a separate
process; Finder/`open -a` delivers files to an existing application process.
CLI relative paths resolve from the calling shell's working directory, including
quoted filenames containing spaces. Pass a video file to Slop Reel; `.` itself is
a directory, not a video. Bundle startup preserves the caller's working directory.

This is a py2app **alias bundle**, like Pip Rot: it loads this live checkout and
its virtualenv, rather than copying the project into a portable distribution.
Edit and restart normally. Reinstall after moving the checkout, replacing Python
or its virtualenv, changing media-tool locations, or updating the icon/bundle
metadata. Finder gets the `ffmpeg`/`ffprobe` directories discovered at install time;
it does not need to load Xonsh configuration. Build dependencies are locked in the
optional `macos` uv group. Build output/log: `tools/slop_reel/build/`.

Registration requires a working macOS desktop/Launch Services session. If the
installer reports a registration failure after copying the bundle, rerun it from
your normal desktop terminal. It leaves existing default video handlers alone.
To make Slop Reel your default, select a video in Finder → **Get Info → Open with
→ Slop Reel → Change All…**; repeat for each desired video type. To uninstall,
move `~/Applications/Slop Reel.app` to Trash; source files and traces remain.

The editable icon master is [assets/slop-reel.svg](assets/slop-reel.svg).
`build_icon.py` renders the PNG preview and multi-resolution ICNS used by the app.

Your course clips are in
`/Users/wesdemos/FCT Dropbox/Wes Higbee/Sync/auto-edit-videos/face2camera/video1/`.
Generated fixtures and derivatives belong under its sibling `slop_reel/` directory;
original course files are never modified.

## Controls

- Play/Pause button or Space outside the chat editor. Playback includes sound.
- Previous/next frame buttons or Left/Right outside the editor. Stepping pauses.
- Click the waveform to seek. Videos without audio still have a seekable timeline.
- Frame zoom button or Z outside the editor pauses and opens the seven-frame
  inspection popup: three before, current, three after. Click a thumbnail to seek
  there. Missing boundary frames are marked; closing the popup leaves playback paused.
- Chat: Send or Ctrl+Return. Normal text sends no media.
- `/frame [question]`: current source frame; default question describes it.
- `/frames [question]`: seven consecutive neighboring source frames; default asks
  for a description and visible discontinuities. At boundaries send available frames.
- Cancel request aborts the asynchronous inference call; no automatic retries.
- F9 quits. Closing stops playback and owned media subprocesses and cancels inference.

The submitted playhead is frozen for extraction; playback may continue during chat.
Previews show the attached frame indices and source presentation timestamps.
Chat uses syntax-lab’s shared Markdown source theme: purple headings, amber
emphasis, teal inline code, blue links, and language-colored fenced code. Markdown
markers remain visible and copyable, with no bold/italic font changes. The chat
and input share its dark palette; edits to syntax-lab colors are picked up on
restart. Click the trace filename to copy its full absolute path; hover to see it.

Model answers use Markdown. Chat retains earlier messages and image attachments
throughout this window's lifetime; a new window starts a fresh conversation.

## Models

Default: `http://build21.lan:8011/v1`, currently serving Gemma 4 E4B Q8_0 through
llama-server. The model ID is discovered from `/v1/models`.
Overrides: `SLOP_REEL_BASE_URL`, `SLOP_REEL_MODEL`, `SLOP_REEL_API_KEY`.
The same `ChatLlamaServer` provider as Clanker is used, with read-only video inspection tools.

Attached images are individual JPEGs capped at 640 pixels on the longest edge.
Frame inspection uses 1280-pixel previews and an approximately 42-frame JPEG cache.
FFprobe builds the frame timestamp index in the background; FFmpeg seeks accurately
and decodes neighboring frames. Indices are zero-based and timestamps are source
presentation times, including nonzero starts. Nominal FPS is not used for indexing.
Long videos can take time to index; playback does not wait for indexing.
Source files must remain unchanged while open.

This POC sends images only. Audio is played and shown as a waveform, **not sent to
the model**. `/frames` is consecutive-image inspection, not an encoded video upload.
It cannot establish synchronized audiovisual understanding. No agent playback or
shell-execution tools are provided yet. See [NOTES.md](NOTES.md) for the roadmap.

## Traces

Real traces: `~/.local/state/nvim/ask-openai/slop_reel/*.jsonl`.
Validation artifacts: sibling `slop_reel_validation/`, never mixed with real traces.
One file per window, version 1, append-only, with collision-safe local-time names,
turn IDs, system/user/assistant messages, response metadata, errors and cancellations.
Image content is stored inline, exactly as submitted to the provider; local message
metadata includes source path, captured playhead and frame positions. Metadata stays
out of model requests. Prior-turn reasoning is removed only from outbound views.
See [the shared format reference](../clanker_mode/SCHEMA.md); `session.trace_type`
is `slop_reel` here. No automatic trace pruning, context compaction, or disk resume.
A cancelled turn retains its submitted user message; subsequent questions can follow it.

## Validation

```sh
uv sync --project tools/slop_reel
./tools/slop_reel/.venv/bin/python tools/slop_reel/fixtures.py
./tools/slop_reel/.venv/bin/pytest -q tools/slop_reel/test_reel.py
./tools/slop_reel/.venv/bin/python tools/slop_reel/smoke_test.py '/path/to/video.mp4' --live
./tools/slop_reel/.venv/bin/ruff check tools/slop_reel tools/ai_shared
```

Fixture generation defaults to `face2camera/slop_reel/`; tests use temporary fixture
copies. Fixtures cover numbered frames, single/multiple black frames, nonuniform
frame intervals, silent video, and audio tones. Native smoke tests require a desktop
OpenGL context; they check rendering, playback, both step directions, seek, seven-frame
zoom, and optionally live image chat plus follow-up. Screenshots and traces persist
under `slop_reel_validation/` for review. Human listening remains part of the audio
playback acceptance check; automated position checks alone do not prove audibility.

## Reviewing material changes

After the frame index loads, a background pass decodes **every frame** once and
caches the detected change positions for this window. Playback/chat remain usable;
the status line shows scan progress. Closing kills the scan subprocess too.

- **Up**: next material change; **Down**: previous material change. Both pause and
  seek to the changed source frame. Existing Left/Right still step every frame.
- **Change sequence** or **Shift+Z**: show nearby material changes, skipping the
  static gaps. Earlier/Later buttons page through up to seven changes at a time.
  Up/Down also work inside the sequence popup; clicking a thumbnail seeks there.
- Frame zoom and change sequence both have **Diff against previous source frame**.
  Unchanged pixels are dimmed and changed pixels use the warm palette accent.
  A change's comparison is always its immediately preceding source frame, even
  when the sequence skips hundreds of unchanged frames. Labels identify that
  reference and show changed-area/local-tile percentages.
- Player keys leave the chat editor's typing and cursor navigation alone.

MVP definition: fit frames into a 640×360 canvas, apply a small spatial blur, then
mark pixels whose maximum RGB-channel difference is at least 24/255. A transition
counts when at least 0.3% of the canvas changes, **or** 25% of any 32×32 tile changes.
The local check helps retain small concentrated changes. These are fixed initial
heuristics in `changes.py`, not model judgments or scene-cut detection. Motion can
produce many consecutive changes; subtle/very small changes can still fall below
the threshold. This is a review aid, not a guarantee that sensitive content is absent.

There is no temporal subsampling, smoothing, or minimum duration: a one-frame flash
can produce both an entry and an exit. No previous-frame comparison exists for the
first source frame. Indexes live in memory and are rebuilt on a fresh launch.

`fixtures.py` also creates `slide-changes.mp4` and its ground-truth JSON in the test
media directory: static slides plus a single black frame at index 115. This is a
useful demo of skipping unchanged spans, browsing event pages, and inspecting diffs.

Native change-review acceptance check (uses the generated slide fixture):

```sh
./tools/slop_reel/.venv/bin/python tools/slop_reel/change_smoke_test.py '/Users/wesdemos/FCT Dropbox/Wes Higbee/Sync/auto-edit-videos/face2camera/slop_reel/slide-changes.mp4'
```

It checks keyboard jumps in both directions (including rapid repeats), sequence
paging, source-adjacent diff references, and isolation from chat-editor keys.
Model-judged candidate filtering, extra sensitivity levels, and desktop-wrapper acceptance
are tracked in [TODO.md](TODO.md). Desktop file-open/lifecycle checks run without
OpenGL using `pytest -q tools/slop_reel/test_macos_app.py`; they cover queued and
running Finder events, duplicate opens, picker/drop paths, menus, and multi-window
quit cleanup. They do not substitute for Finder/Dock acceptance on a live desktop.


## Talking to the agent

Hold **F6** (with this review window focused) or the **Hold to talk** button,
then release. Whisper's final transcript is inserted at your captured text-box
cursor/selection; review it and send separately. Existing text is preserved outside
the selection. Live hypotheses appear in the status line, without repeatedly
rewriting your draft. Losing window focus releases dictation too.

This uses the **resident voiced daemon** in the adjacent `ask-openai.nvim` repo;
no second Whisper model is loaded in Slop Reel. Start it with:

```sh
cd ../ask-openai.nvim
.venv/bin/python -m tools.voiced
```

Restart an older running daemon after updating it. Slop Reel requires the private
protocol handshake and deliberately refuses to record through older broadcast-only
versions. Its private session's live/final transcripts go only to its connection,
not Clankerd or Neovim. Global hardware PTT/VAD do not interrupt an owned session.
If another utterance is already active, dictation reports that the microphone is
busy. The daemon remains running after Slop Reel closes; an owned recording is
released on close/disconnect. Whisper errors release microphone ownership too.

Socket default: `$XDG_STATE_HOME/ask-openai/voiced.sock`, falling back to
`~/.local/state/ask-openai/voiced.sock`. Override with `SLOP_REEL_VOICED_SOCKET`.
Other clients can adopt the same protocol documented in voiced's README. Ownership
is explicit per connection; foreground-app detection is not required.

## Agent-controlled video inspection

Ask naturally, e.g. **“Are there any black frames in this video?”** No slash command
or manual attachment is required. The agent has a read-only `inspect_video` tool:

- `info`: source frame count, timestamp bounds, and the playhead captured at Send.
- `current`: that playhead's source frame.
- `frames`: inclusive source frame index range; defaults to three neighbors either side.
- `time`: inclusive source timestamp range; defaults to +/-0.5 seconds around the playhead.
- `changes`: material-change candidates throughout the video, plus source frame zero;
  optional start/end source timestamps restrict the search to a nearby period.

Images are delivered in pages of at most eight, with `total_candidates`,
`returned_indices`, and `next_offset`. The agent can keep paging or request exact
neighbors. Results include source timestamps plus measured mean luma and the pixel
fraction below luma 12, useful for black-frame checks. Dark frames can be intentional.
Changed-frame candidates are heuristic coverage, not an exhaustive guarantee about
all frames. The system prompt requires honest coverage reporting and confirmation
of anomalies. The model still makes mistakes: the first live test missed a visible
blackout until measured brightness was added to tool results.

Tool calls and images are saved in the same append-only JSONL conversation as
ordinary chat. Tool-selected images use an automatically generated user-role
observation after tool replies for compatibility with Gemma's image template;
`metadata.tool_observation` links it to the call. Tool status appears in the chat.
There is a 25-inference-step limit per request. Cancel stops both inference and
agent-owned media subprocesses without stopping playback or the UI's change scan.
The agent uses its own worker-owned decoder and lazily cached change scan to avoid
sharing mutable decoding state with the frame zoom worker. No source audio or
playback-control capability is exposed. `/frame` and `/frames` remain available.

Validation: `test_agent.py` checks actual decoded black-frame identity, pagination,
bounds, automatic tool observations, and trace replay. `test_voice.py` exercises Qt
socket framing, final-only insertion, release-before-connect, and refusal of an old
daemon. The voiced tests verify isolation from other subscribers, busy handling,
disconnect cleanup, recognition failures, and legacy global PTT behavior. Live model
validation traces stay under `slop_reel_validation/agent-tools/`.
