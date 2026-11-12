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
uv pip install --python ~/.local/share/uv/tools/xonsh/bin/python -e ../langchain-llama-server
```

Unit/integration tests cover real Xonsh state mutations, exceptions, caller-thread
execution, traces, interruption, and an HTTP tool round trip through the real
provider. The opt-in live test generates a random hidden environment value and
asks the model to discover it using its tool; it requires ask.lan to be available.

To disable, remove `.config/xonsh/rc.d/clanker-mode.xsh` and start a new shell.
