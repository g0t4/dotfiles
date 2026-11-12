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
shows usage. Each invocation is a fresh conversation; live shell state persists.
Ctrl+C interrupts the turn (already executed changes persist).

The sole tool, `execute_in_current_xonsh`, runs Xonsh source directly against
`XSH.ctx` on the foreground thread. It can read and change environment variables,
Python variables, aliases, history, cwd, and execute commands with your privileges.
There is deliberately no sandbox or subprocess boundary. Print values to return
results. The system prompt explains shell internals and history object access.

Connection defaults: `http://ask.lan:8014/v1`, model `FIXED_MODEL`, key `none`.
Optional Xonsh environment overrides: `$CLANKER_BASE_URL`, `$CLANKER_MODEL`,
`$CLANKER_API_KEY`. Uses a 120-second request timeout, no automatic retries,
and at most 20 model rounds per invocation.

Traces: `~/.local/state/nvim/ask-openai/clanker_mode/*-trace.json`, with
`trace_type: clanker_mode` and the existing `session_id`, `messages`, `response`
shape. Includes tool arguments/results, response metadata and errors, saved after
each step and on interruption. Files are user-only (0600). These traces can contain
any shell state inspected by the agent, including secrets if explicitly requested.
Tool side effects themselves are not rolled back by interruption.

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
