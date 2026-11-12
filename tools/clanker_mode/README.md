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

During each agent execution tool call, the interactive `cat` alias is temporarily
removed, so `cat` resolves to the executable on PATH. The exact alias and its
explicit help text are restored even after an exception or interruption. Other
aliases and unrelated shell state changes retain their normal behavior.
`AGENT_ALIAS_OVERRIDES` in `clanker_mode.py` is the policy: `None` removes an alias
for the scope; another value supplies a temporary replacement. Changes to those
scoped alias names are temporary too.

The system prompt tells the agent to explicitly capture external output, e.g.
`print($(cat path/to/file))`. Bare external commands (notably Xonsh's unthreadable
`cat`) can write directly to the terminal without returning their output to the
model. Python prints and explicitly captured output are included in tool results.

Connection defaults: `http://ask.lan:8014/v1`, key `none`.
Without a model override, `/v1/models` supplies the model ID: use the sole model
on a dedicated endpoint (including VLLM), or the sole loaded model on a router.
Ambiguous model lists require an explicit `$CLANKER_MODEL`; nothing is chosen
arbitrarily or loaded merely by discovery. Discovery has a 10-second timeout.
Optional Xonsh environment overrides: `$CLANKER_BASE_URL`, `$CLANKER_MODEL`,
`$CLANKER_API_KEY`. Uses a 120-second request timeout, no automatic retries,
and at most 20 model rounds per invocation.

Traces live in `~/.local/state/nvim/ask-openai/clanker_mode/`. Names begin with
local time, for example `2026-11-12_1530.jsonl`. Only collisions add a suffix,
revealing as little of the microsecond timestamp as needed: `_1`, `_1b`, etc.
Files are user-only (0600), with one append-only JSONL trace per shell.

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
uv pip install --python ~/.local/share/uv/tools/xonsh/bin/python -e ../langchain-llama-server -e tools/syntax-lab
```

Unit/integration tests cover real Xonsh state mutations, exceptions, caller-thread
execution, traces, interruption, and an HTTP tool round trip through the real
provider. The opt-in live test generates a random hidden environment value and
asks the model to discover it using its tool; it requires ask.lan to be available.

To disable, remove `.config/xonsh/rc.d/clanker-mode.xsh` and start a new shell.

## Watching agent execution

Interactive `clank` displays a transient thinking spinner while waiting for a
complete model response. Before each tool executes, a message box shows the tool
name and syntax-lab-highlighted Xonsh source in an indented tree, matching the
chat trace viewer's style. Calls are numbered within each returned batch.

Tool results follow in separate boxes with literal output (including failures),
then the next tool or model response appears below. These boxes remain in terminal
scrollback so you can follow the agent's work and take over the shell afterward.
Intermediate assistant text and the final Markdown answer use assistant boxes.

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
