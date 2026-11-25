# Clanker Mode

An in-process Xonsh agent using `ChatLlamaServer`, the same LangChain provider
as the iTerm2 ask helper. No dependency on the Neovim Clanker implementation.

Open a new Xonsh shell, then:

```xonsh
clank! What were my last few commands?
$CLANKER_DEMO_VALUE = 'hello from my shell'
clank! Read CLANKER_DEMO_VALUE from my shell environment
clank! Set a Python variable named clanker_greeting to hello
print(clanker_greeting)
```

Run bare `clank` to enter a conversational sub-REPL. Type follow-ups directly at
the `🐷🖕 clank [profile] ›` prompt without repeating the command. Ctrl+D or Enter on an empty prompt exits
only after the current turn is complete; entering `clank` again resumes the same
in-shell conversation. `/rollback`, `/clear`, `/trace`, and `/exit` are available
at the idle sub-REPL prompt.

`c` expands to `clank!` on Space or Enter. Use this Xonsh subprocess macro
for prose. Everything after the bang reaches Clanker as a single argument,
including shell operators such as `and`, `|`, and `>`. Use ordinary `clank`
for controls such as `clank --profile` and `clank manage list`.
Interactive input starting with `clank` that fails Xonsh syntax parsing is
dispatched as a literal request, e.g. `clank what does {} mean in c#`. The
`on_transform_command` handler runs before execution; it never executes the
request while checking syntax. Valid shell syntax keeps its normal behavior,
including expansion, comments, pipelines and redirects. Use `clank!` when
you want the entire prompt passed literally.
This fallback applies to interactive submissions, not scripts or tool code.
`clank --help` shows usage. Conversation and live shell state persist for this shell process.
`clank --clear` clears model context while retaining the trace with a reset event.
The next question starts a fresh context in the same trace. A new shell gets its
own conversation and trace; old shell traces are not automatically resumed.
Ctrl+C interrupts the turn (already executed changes persist).

While the model is thinking in an interactive terminal, `steer ›` accepts one or
more messages. Complete lines queue in order until the current model response and
its tool-result batch finish, then enter the conversation together before the
next model request. Only the active steering prompt appears below the message
boxes. It clears before each new box and when Clanker finishes.
A blank steering line is ignored. Tool execution remains on
the foreground Xonsh thread; steering input is offered during model inference,
not while a shell tool owns the terminal.

Text still being edited when inference finishes is not submitted or discarded.
It pre-fills the next steering prompt, or the next Clanker prompt when the turn
has completed. This pending input also survives leaving and re-entering `clank`
within the same Xonsh process; it is local UI state and is not written to the
conversation trace until submitted.

Shift-F7 toggles private voice dictation at both the Clanker and steering prompts.
It connects to the existing `voiced` Unix socket, requires private-dictation
support, and owns the microphone until Shift-F7 is pressed again. The final
transcript is inserted at the current cursor in that same editable buffer; it
does not submit the prompt or enter conversation context by itself. Existing text
is preserved. A bottom toolbar shows listening/finalizing state and socket or
microphone errors. If a model reply arrives during dictation, the steering prompt
waits for your final transcript before carrying the draft forward. Private
transcription goes directly to this prompt.

`rollback_turn` is also available to the model, and `clank --rollback` or
`/rollback` invokes the same operation manually. Rollback is context management
only: it excludes the latest prior active turn from future model requests. The
append-only trace retains the original turn and the rollback event, and no shell,
filesystem, process, network, or other external side effect is undone. This makes
it convenient to fork into a small exploration and pull the conversational context
back afterward, including after accidentally collecting noisy irrelevant output.

## Saved conversations and compaction

Infrequent context controls live under `clank manage`; `cm` expands to that prefix:

```xonsh
clank manage list
clank manage save [title]
clank manage rename <title>
clank manage restore [title-or-unique-fragment]
clank manage compact
clank manage delete [--both|--saved|--trace] <title-or-ID>
```

Save stores the active context as a named snapshot under the Clanker state
directory. With no title it uses the first user message. Subsequent saves update
the bound snapshot; rename also saves an unsaved conversation. Bare restore
selects the most reused snapshot. List sorts snapshots by restore count and recent
use. The original `--list`, `--saved`, `--save`, `--rename`, `--restore`,
`--compact`, `--rollback`, `--clear`, and `--trace` spellings remain compatible.
The sub-REPL has matching `/list`, `/save`, `/rename`, `/restore`, `/compact`,
`/rollback`, `/clear`, and `/trace` controls; `/saved` remains an alias for `/list`.

Native Xonsh completion describes the management commands and completes saved
titles after either `clank manage restore` or `clank --restore`. The sub-REPL
completes slash controls and saved titles after `/restore`; ordinary conversation
text never receives management completions.

Save captures the current active context and excludes turns removed by rollback
or clear. You can save immediately after compacting. Restore preserves individual
turns for rollback, including in older snapshots saved after a restore. Snapshot JSON is user-only (0600) and
separate from append-only traces. A restore adds a `context_restore` link to the
current trace; the complete restored messages stay in the snapshot.

Delete accepts the same title, unique title fragment, or ID prefix as restore.
It requires a target. By default it deletes the snapshot and its originating
shell's entire JSONL trace. Use `--saved` or `--trace` to remove one file.
A trace can span multiple conversations. If another saved conversation shares
the trace, use `--saved`. Close another running shell before deleting its trace.
Deleting this shell's trace starts a fresh log and keeps the current chat in
memory. The sub-REPL accepts the same selectors after `/delete`.

Use `clank manage messages` (or `/messages` inside the sub-REPL) to dump the
active conversation as JSON, including restored messages and tool results.
The dump can contain private conversation content.

`clank --compact` or `/compact` explicitly asks the current model for a durable
continuation summary, then reduces active inference context to the original system
instructions plus that summary. Compaction is never automatic. Original messages
and a `context_compaction` boundary remain in the trace; shell, filesystem and
other external state are unaffected.

The shell tool, `execute_in_current_xonsh`, runs Xonsh source directly against
`XSH.ctx` on the foreground thread. It can read and change environment variables,
Python variables, aliases, history, cwd, and execute commands with your privileges.
There is deliberately no sandbox or subprocess boundary. Print values to return
results. The system prompt explains shell internals and history object access.

Edit `apply_patch.md` beside `clanker_mode.py` to change the patch tool's
description. It is a local copy of ask-openai.nvim's instructions, loaded at the
start of each turn. Edits take effect on the next prompt without restarting
Xonsh, and changed definitions are recorded in the trace's `tools` events.

The experimental Clanker Code avatar font is documented in [FONT.md](FONT.md).
The prompt uses ordinary emoji so iTerm can keep GPU rendering enabled.

During each agent execution tool call, the interactive `cat` alias is temporarily
removed, so `cat` resolves to the executable on PATH. The exact alias and its
explicit help text are restored even after an exception or interruption. Other
aliases and unrelated shell state changes retain their normal behavior.
`AGENT_ALIAS_OVERRIDES` in `clanker_mode.py` is the policy: `None` removes an alias
for the scope; another value supplies a temporary replacement. Changes to those
scoped alias names are temporary too.

Tool execution captures both Python streams and OS stdout/stderr descriptors into
one anonymous temporary file, returning the combined text to the model. Bare
external commands, Python subprocesses with inherited output, direct descriptor
writes, and ordinary Python prints are covered. Explicit Xonsh capture such as
`print($(cat path/to/file))` still works. The file is automatically closed and
removed; completed tool results remain in the conversation trace. Xonsh terminal
title updates are suppressed during tool calls to keep their escape sequences
out of results. Capture works with `$XONSH_CAPTURE_ALWAYS` either on or off;
Clanker does not override it. That setting enables Xonsh capture for threadable
commands but does not cover all the descriptor writes handled here.

Capture applies process-wide while Clanker owns the foreground shell. Stdout and
stderr are not TTYs during execution, so commands may disable colors or change
buffering. Prefer noninteractive commands and wait for child processes to finish:
background writers are not isolated, and output after a call returns is not
reliably included. Explicit redirection to files or `/dev/tty` remains outside
capture. Streams and descriptors are restored after errors and Ctrl+C.

## Model profiles and retries

`clank --profile` opens a keyboard picker in the terminal. Use ↑/↓ and Enter.
Use `/profile` inside Clanker. Both commands also accept a name and offer Tab
completion. For a Stream Deck text action, submit the command in the target shell:

```xonsh
clank --profile inkling-2-mini
clank --retry deepseek
```

Selecting a profile updates the current shell immediately and saves the default
for new Xonsh shells in `$XDG_STATE_HOME/clanker_mode/profile`
(usually `~/.local/state/clanker_mode/profile`). Each shell reads it once at startup,
so other open shells keep their selection. Retry leaves the saved default alone. The default
`deepseek` profile discovers the model at `http://ask.lan:8014/v1` and honors
the existing connection overrides. The `inkling-2-mini` profile uses the named
model at `http://build21:8017/v1`. Both use the same LangChain client. Before the first saved selection,
Xonsh uses an inherited `$CLANKER_PROFILE` or falls back to `deepseek`.

`--retry` (or `/retry`) forks the latest locally submitted turn using its original
conversation input. With no name, it opens the picker in a terminal or uses the
selected profile in a pipeline. The alternate answer prints immediately and gets
its own linked trace. Follow-ups continue the original conversation using the
selected profile. Both runs can execute tools against the live shell, so a retry
can repeat side effects or see different tool results. Clear, restore, compact,
rollback of the latest turn, or trace replacement invalidates that retry.

Connection defaults: `http://ask.lan:8014/v1`, key `none`.
Without a model override, `/v1/models` supplies the model ID: use the sole model
on a dedicated endpoint (including VLLM), or the sole loaded model on a router.
Ambiguous model lists require an explicit `$CLANKER_MODEL`; nothing is chosen
arbitrarily or loaded merely by discovery. Discovery has a 10-second timeout.
Optional Xonsh environment overrides: `$CLANKER_BASE_URL`, `$CLANKER_MODEL`,
`$CLANKER_API_KEY`. Uses a 120-second request timeout, no automatic retries,
and at most 50 model rounds per invocation.

### Code-based worker profiles

Use `/profile inkling-low` to select Inkling with low reasoning effort, or
`/retry inkling-low` to try it on the previous input once. The original profiles
leave sampling, effort, and output length at their provider defaults.

A launcher can derive an immutable profile for one call. Passing the object
directly to `run_agent`, `retry_agent`, or `compact_session` bypasses named preset
lookup and leaves the shell's saved selection alone. Start from
`resolve_profile(xsh, "deepseek")` to include the existing shell connection
overrides, or use a preset object directly to specify its configured endpoint.

```python
from dataclasses import replace
from clanker_profiles import INKLING
from clanker_mode import run_agent

worker = replace(INKLING, name="reproduce-flake", reasoning_effort=0.42,
                 temperature=0, max_output_tokens=2048, request_timeout=60,
                 max_rounds=6)
run_agent("Reproduce the failure and report the seed.", xsh, profile=worker)
```

Effort is model-specific. Temperature controls sampling; the output cap bounds
generated tokens per request, including reasoning on these endpoints. Timeout
is the model client's request timeout in seconds. Rounds bound the number of
model requests in a turn; one answer may request several tools. A worker still
needs its own shell for concurrent execution. Endpoint credentials are looked up
at connection time by environment variable name.

Inkling accepts numbers from 0 through 0.99 and seven preset names. Its template
renders a system message such as `Thinking effort level: 0.42`. The names map to
`none=0`, `minimal=0.1`, `low=0.2`, `medium=0.7`, `high=0.9`, and both
`xhigh=max=0.99`. The default in the pinned template is 0.9. For the current
vLLM client, numeric values go through `chat_template_kwargs`; named choices
use the top-level effort field. The DeepSeek profile exposes `none`, `low`,
`high`, and `max`.
[Inkling chat template](https://huggingface.co/thinkingmachines/Inkling-2-Mini/blob/b85c3cfa615fc413cc9af3379f491b963f3b586a/chat_template.jinja)

On the local Inkling vLLM endpoint, we asked for the visible effort without
giving its value in the user message. It identified 0.2 and 0.9; at 0.42 it hit
the 1024-token output cap before returning an answer. A shorter follow-up asking
only for the number returned 0.42, and the named low setting returned 0.2.
In a separate probe the
prompt was “How many unordered multisets of coins of values 1, 3, and 4 total
exactly 17? Use unlimited coins. Return just the integer.” At temperature zero
and the same cap, each setting returned 18. The table records one call per
setting on 2026-11-24.

| Numeric effort | 0 | 0.2 | 0.42 | 0.7 | 0.9 | 0.99 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Server-reported reasoning tokens | 356 | 374 | 347 | 315 | 435 | 445 |

Traces live in `~/.local/state/nvim/ask-openai/clanker_mode/`. Names begin with
local time, for example `2026-11-12_1530.jsonl`. Only collisions add a suffix,
revealing as little of the microsecond timestamp as needed: `_1`, `_1b`, etc.
Files are user-only (0600), with one main JSONL trace per shell and one per retry.

**[Trace format reference: version 1](SCHEMA.md)** documents every record type,
field, filename rule, outbound filtering policy, and complete example for readers
and agents. The first record explicitly declares `type: "version", version: 1`.

`clank --trace` prints this shell's trace path for `tail -f` or a live formatter.
`clank --clear` appends a context reset; it does not delete the trace. These files
can contain shell state inspected by the agent, including explicitly requested
secrets. Tool side effects are not rolled back by interruption.

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
uv tool install 'xonsh[full]' --with-requirements xonsh/requirements.txt \
  --with-editable ../langchain-llama-server --with-editable tools/syntax-lab
```

Unit/integration tests cover real Xonsh state mutations, exceptions, caller-thread
execution, traces, interruption, and an HTTP tool round trip through the real
provider. The opt-in live test generates a random hidden environment value and
asks the model to discover it using its tool; it requires ask.lan to be available.

To disable, remove `.config/xonsh/rc.d/clanker-mode.py` and start a new shell.

## Watching agent execution

Interactive `clank` displays a transient thinking spinner while waiting for a
complete model response. Before each tool executes, a message box shows the tool
name and syntax-lab-highlighted Xonsh source in an indented tree, matching the
chat trace viewer's style. Calls are numbered within each returned batch.

Tool results follow in separate boxes with literal output (including failures),
then the next tool or model response appears below. These boxes remain in terminal
scrollback so you can follow the agent's work and take over the shell afterward.
Intermediate assistant text and the final Markdown answer use assistant boxes.
Assistant text and calls align left. Tool results align right. Above 160 terminal
columns the conversation is centered with equal outer margins (one cell more on
the right for an odd remainder). Boxes fit their content, including borders and
padding. They start at 50 cells and grow up to 90% of the conversation width.
Below 50 cells they use the entire pane. ANSI colors in tool output occupy no
cells; wide characters are measured in terminal cells.

Progress and tool boxes use stderr and are enabled only when it is a terminal.
The final answer uses stdout; pipes and redirection receive plain original answer
text. The thinking spinner is stopped before tool execution and on failures or
Ctrl+C. UI output is outside tool capture, excluded from trace messages, and never
sent back to the model. Direct `run_agent` callers are quiet unless they provide
an `on_event(event, payload)` callback.

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

Validation and demo traces persist separately under
`~/.local/state/nvim/ask-openai/clanker_mode_validation/<run>/<model>/<case>/<attempt>/`.
They are retained between runs; interactive shell traces stay in `clanker_mode/`. Override
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

## Design notes for a model-first shell

`clanksh` is a working name for a possible next UX for `clanker_mode`. Open a
terminal and land at `🐷🖕 clank [profile] ›`. Plain text goes to the model, and
slash commands such as `/profile` control the REPL. A leading `!` could send a
command straight to the live Xonsh session. It mirrors today's `clank!` in the
other direction. Xonsh can keep supplying the working directory, variables,
aliases, and execution while gradually receding from the everyday interface.

### Work on a command together

Keep one editable command draft alongside the conversation. Either of us can
change it. I can paste a half-written pipeline, ask “what would this touch?”,
edit a filename myself, then ask Clanker to change just the filter. Clanker
should see the draft as it stands when I ask. If I keep typing while it thinks,
its proposed edit should preserve my newer work or let me reconcile the edits.

For example, I paste `sort names.txt > names.txt` and say “sort this in place.”
Clanker can point out that the shell opens the output file before `sort` reads
it and propose `sort -o names.txt names.txt` in the draft. I can inspect the
change, edit it again, or run it. Sending a chat message and executing the draft
need distinct gestures so we can keep talking with a runnable command on screen.

The conversation should also span execution. Once I run the draft, “fix that”
should refer to the exact command I ran, its exit status, and its relevant
output. Clanker can explain the failure and put a repair back in the draft.
That gives the model a role both before execution, when it can catch a mistake,
and afterward, when the shell has evidence about what happened.

A small first experiment would be to try the shared draft inside the existing
REPL. The gestures for opening it, accepting an edit, and running it are open
questions. Trying those on a real command would help decide whether this feels
good enough to make Clanker the terminal's default entry point.

### Clanker Swarm

Each shell session has a primary model. Main Clanker oversees the investigation
and can delegate a specific question to a child. The user can pair with either
one. Address a child by its task (“ask whoever reproduced the flake to try a warm
cache”). A child reports a finding, the evidence, and a way back into its live
shell. “Take me there” focuses the session that still has the failing seed and
scratch files. Joining a branch and accepting its edits are separate operations.

The first proposed demo is “reproduce this in another tab while we keep
talking.” Give the child a task ID, a snapshot of the conversation through the
request, a model profile, and an execution destination. Record the parent task
and originating iTerm2 session ID. Create a background tab without moving the
keyboard, and associate the returned session ID with the child. Task ownership
and focus can then change independently. The existing iTerm2 AutoLaunch script,
tab/profile helpers, and ID-based socket routing are precedents.
[wes.py](../../iterm2/scripts/AutoLaunch/wes/wes/wes.py) ·
[split.py](../../iterm2/scripts/AutoLaunch/wes/wes/split.py) ·
[session lookup](../../iterm2/scripts/AutoLaunch/wes/wes/semantic_save_window_state.py)

The human and model can be clients of the same tool service, potentially using
MCP. Address a long-lived shell by session ID so cwd, variables, and jobs survive
between calls. A terminal attachment lets the user take the keyboard for an
interactive program, then hand control back. Model selection, shell destination
(local Xonsh, SSH, or container), and toolbox image are independent choices.
A pinned Linux/GNU toolbox gives competing models the same commands and flags.
The host shell remains useful for macOS-specific work.

For three simultaneous attempts, start from the same input and dirty workspace,
including untracked fixtures. First try a Docker image containing the working
files and give each child a writable layer. Host bind mounts share edits across
containers. Docker Sandbox kits can package a toolbox and its agent instructions;
local templates capture filesystem state, and the cloud snapshot API offers
memory capture where supported. A Linux alternative is a stable filesystem
snapshot with a private overlay and mount namespace per child. Inherited file
descriptors and cwd need explicit handling. Forking a live threaded Python
interpreter adds another constraint. A fresh shell per worker is a smaller MVP
than capturing live Python objects. Docker would own the environment lifecycle;
Clanker would own the task, conversation, evidence, and handoff.
[Docker templates](https://docs.docker.com/ai/sandboxes/usage/#saving-a-sandbox-as-a-template) ·
[Snapshot and fork](https://docs.docker.com/ai/sandboxes-api/cookbook/snapshot-and-fork-a-sandbox/)

A Linux image that boots straight to Clanker could test the OS idea. Measure
time to first retained keystroke separately from time to first model token.
A capability-based microkernel experiment could delegate explicit handles for a
private workspace and services to each worker. A vetted model could propose a
grant; the kernel would enforce the caller's authority. Inference could remain
an independently restartable user-space service. Scope external side effects
separately from filesystem snapshots (for example, pushing a Git ref).

### Further out

If the shared draft feels right in `clanksh`, the next idea is `clankerterm`:
what would a terminal built around that interaction feel like? And if we keep
going, `clankeros` would be a command-line-only OS built on a microkernel.
The boot target is one second flat to a prompt that accepts input. 🐷
