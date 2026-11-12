# Clanker Mode

An in-process Xonsh agent using `ChatLlamaServer`, the same LangChain provider
as the iTerm2 ask helper. No dependency on the Neovim Clanker implementation.

Open a new Xonsh shell, then:

```xonsh
clank "What were my last few commands?"
$CLANKER_DEMO_VALUE = 'hello from my shell'
clank "Read CLANKER_DEMO_VALUE from my shell environment"
clank "Set a Python variable named clanker_greeting to hello"
print(clanker_greeting)
```

`c` expands to `clank` on Space or Enter through the existing abbreviation system.
Quote requests containing shell syntax to pass them literally. `clank --help`
shows usage. Conversation and live shell state persist for this shell process.
`clank --clear` clears model context while retaining the trace with a reset event.
The next question starts a fresh context in the same trace. A new shell gets its
own conversation and trace; old shell traces are not automatically resumed.
Ctrl+C interrupts the turn (already executed changes persist).

The sole tool, `execute_in_current_xonsh`, runs Xonsh source directly against
`XSH.ctx` on the foreground thread. It can read and change environment variables,
Python variables, aliases, history, cwd, and execute commands with your privileges.
There is deliberately no sandbox or subprocess boundary. Print values to return
results. The system prompt explains shell internals and history object access.

Connection defaults: `http://ask.lan:8014/v1`, key `none`.
Without a model override, `/v1/models` supplies the model ID: use the sole model
on a dedicated endpoint (including VLLM), or the sole loaded model on a router.
Ambiguous model lists require an explicit `$CLANKER_MODEL`; nothing is chosen
arbitrarily or loaded merely by discovery. Discovery has a 10-second timeout.
Optional Xonsh environment overrides: `$CLANKER_BASE_URL`, `$CLANKER_MODEL`,
`$CLANKER_API_KEY`. Uses a 120-second request timeout, no automatic retries,
and at most 20 model rounds per invocation.

Traces: `~/.local/state/nvim/ask-openai/clanker_mode/<session_id>.jsonl`.
One append-only trace per shell, created on first use. Files are user-only (0600).
These traces can contain any shell state inspected by the agent, including secrets
if explicitly requested. Tool side effects are not rolled back by interruption.

## JSONL format (schema version 1)

Each line is a complete JSON object, flushed and terminated by a newline. Every
record has `type`, a zero-based monotonic `sequence`, and an ISO 8601 UTC
`timestamp`. Only newly created records are serialized; earlier bytes are never
rewritten. Embedded newlines in content are JSON-escaped, so one event is one line.

| Type | Additional fields |
| --- | --- |
| `session` | `schema_version`, `session_id`, `trace_type: "clanker_mode"`, `pid` |
| `turn_start` | `turn_id` (one-based, increasing even across resets) |
| `message` | `turn_id`, `message` (role/content and tool-call fields), `metadata` |
| `error` | `turn_id`, `error: {class, message}` |
| `turn_end` | `turn_id`, `status: "success"`, `"error"`, or `"interrupted"` |
| `context_reset` | `after_turn_id` |

Message `metadata` contains `finished_at` and, for assistant messages, `response`
(provider response metadata) and `usage` (normalized token usage). Optional fields
include `provider_message_id`, `invalid_tool_calls`, `raw_tool_calls`, and
`synthetic: true` for tool-result placeholders created when a turn aborts.
There is no duplicated top-level response summary. Errors and turn endings remain
separate events, so later successes cannot overwrite earlier failures or timing.

The first turn includes the system message; subsequent turns append user,
assistant and tool messages. Resetting appends a `context_reset` event without
removing old records; the next turn appends a new system message. A reader can
show the whole shell lifetime or just messages after the most recent reset.

Outbound inference input is built separately from the current context's message
records. Event envelopes and local metadata are never sent. Reasoning from older
turns is omitted from outbound input, while the original reasoning remains in
the trace. The current provider also omits reasoning on the wire within a turn.
The system prompt is frozen until reset, and prior message content is not
summarized or edited. HTTP tests verify that earlier wire-message prefixes remain
identical across follow-ups. Server caching itself remains server-controlled.

Interrupted pending tool calls get synthetic result messages, never automatic
re-execution. This keeps follow-ups valid even when an interruption happens
mid-tool. Completed side effects remain in the live shell.

```xonsh
clank --trace
```

Prints this shell's trace path. From another terminal, use:

```sh
tail -n +1 -f /path/printed/above.jsonl | your-formatter
```

Readers should buffer until a newline and tolerate an incomplete final line after
a crash. Records are flushed to the OS on each append, not fsynced per record.
The session is kept in process memory; the file is an event log, not an automatic
restart/resume mechanism. Prior JSON traces are left untouched. Conversation
context grows until you clear it; no automatic trimming or compaction is applied.

## Development

```sh
uv sync --project tools/clanker_mode
 tools/clanker_mode/.venv/bin/pytest -q tools/clanker_mode
CLANKER_LIVE_TEST=1 tools/clanker_mode/.venv/bin/pytest -q tools/clanker_mode -m live
 tools/clanker_mode/.venv/bin/ruff check tools/clanker_mode
```

The dedicated venv is only for development. Runtime imports use Xonsh's own Python.
Install the provider there (the sibling provider checkout is also used by uv.lock):

```sh
uv pip install --python ~/.local/share/uv/tools/xonsh/bin/python -e ../langchain-llama-server -e tools/syntax-lab
```

Unit/integration tests cover real Xonsh state mutations, exceptions, caller-thread
execution, traces, interruption, and an HTTP tool round trip through the real
provider. The opt-in live test generates a random hidden environment value and
asks the model to discover it using its tool; it requires ask.lan to be available.

To disable, remove `.config/xonsh/rc.d/clanker-mode.xsh` and start a new shell.

## Model capability validation

The terminal displays responses as Markdown source using syntax-lab's shared
palette. Markdown punctuation remains visible; raw answers remain in traces.
Pipes and redirection receive the original text without wrapping or ANSI escapes.

`capability_models.json` names endpoints/models for DeepSeek, Muse and GPT-OSS.
Edit or add entries to validate another model. Run one, several, or all entries:

```sh
tools/clanker_mode/.venv/bin/pytest -v -s tools/clanker_mode/test_capabilities.py \
  --clanker-live --clanker-model muse --clanker-model gpt-oss \
  --junitxml=/tmp/clanker-capabilities.xml
```

Omit `--clanker-model` to run all configured entries. Ordinary pytest runs skip
these calls. Capability validation uses the production system prompt, provider,
and tool with fresh disposable Xonsh state for each model/case. It never loads
your startup files or real history. Each case checks:

- Environment: discover a random value through the live shell tool.
- Python state: discover and copy a variable, verifying the mutation persists.
- History: discover a random argument from an actual Xonsh history object.
- Recovery: observe a requested NameError, then fix state and report its value.

Answers can use prose, Markdown or other formatting; no exact sentence matching
or model judge. Checks require the random value in the answer and tool evidence,
plus the applicable state changes. These are capability probes, not claims of
universal reliability. Review the printed answers and traces as well as passes.
Connection/protocol errors are reported separately in pytest's error text; they
are not proof that a model lacks the capability.

Traces persist under `clanker_mode/validation/<run>/<model>/<case>/<attempt>/`. Override
with `--clanker-traces <directory>`. JUnit XML records answers and trace paths
for completed calls, and failures retain their production traces too. Run the
suite repeatedly when assessing reliability across sampling variation.

## Suggested commands at the next prompt

```xonsh
clank "Help me write a command to find files larger than 100 MB; put it on my command line"
```

The model can call `from clanker_mode import replace_commandline` through its
existing execution tool. `replace_commandline(command)` sets
`XSH.env['XONSH_PROMPT_NEXT_CMD']`, the same one-shot mechanism as Esc+A
(accept and hold). After `clank` returns, the command appears in your next
editable prompt. You decide whether to edit, submit or discard it.

Pass command source without Markdown fences. Multiline commands work. An optional
`<cursor>` marker chooses where the cursor starts; otherwise it starts at the end.
The latest call replaces an earlier suggestion. This is a regular in-process
function, not a second model tool. Like other shell state mutations, a queued
suggestion persists even if the agent is interrupted later in the turn.

Capability validation also probes command-line suggestions: the model must call
the helper and leave the requested command unexecuted. Only then does the test
simulate accepting it and verify its behavior. The answer's prose is ungraded.
