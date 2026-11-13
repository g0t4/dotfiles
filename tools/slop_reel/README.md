# Slop Reel

A local video inspection workbench: libmpv playback and waveform on the left,
explicit multimodal chat on the right. It shares LangChain connections and the
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
Pass one file, not a wildcard expanding to multiple files. There is no file picker.

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
Model answers use Markdown. Chat retains earlier messages and image attachments
throughout this window's lifetime; a new window starts a fresh conversation.

## Models

Default: `http://build21.lan:8011/v1`, currently serving Gemma 4 E4B Q8_0 through
llama-server. The model ID is discovered from `/v1/models`.
Overrides: `SLOP_REEL_BASE_URL`, `SLOP_REEL_MODEL`, `SLOP_REEL_API_KEY`.
The same `ChatLlamaServer` provider as Clanker is used without tool binding.

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
