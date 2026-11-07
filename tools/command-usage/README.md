# Command usage experiments

Three components, deliberately independent of GUI history and file pickers:

- `wes_command_usage.capture.Recorder`: Xonsh execution hooks and optional Python audit observations.
- `wes_command_usage.analysis`: deterministic evidence interpretation and non-executing Xonsh source explanation.
- `wes_command_usage.store.Store`: disposable raw events and a replaceable resource index.

New interactive Xonsh sessions load `.config/xonsh/rc.d/command-usage.xsh`.
Already running shells need a restart. Defaults:

```xonsh
$XONSH_COMMAND_USAGE = True
$XONSH_COMMAND_USAGE_PYTHON_IO = True
```

These settings are read on installation. Set either in the environment before
starting a shell to disable it. The Python audit hook is installed once per
interpreter and becomes inactive when the recorder closes. It cannot be removed
from Python's audit-hook registry. Recorder-generated metadata checks are
suppressed from audit capture. Background writer errors are reported once and
must not change command execution.

## Diagnostics

```xonsh
command-usage events
command-usage explain 'cat @(files) | jq .'
command-usage rebuild
command-usage reset
```

Output is JSON for inspection and piping. `explain` parses source without
executing expressions, expanding globs, or attempting to recover old variables.
It is a syntax explanation, not a claim that operands were accessed. `rebuild`
returns resource evidence and replaces the entire derived index transactionally;
repeated rebuilds of the same events are identical and do not accumulate counts.
No picker consumes this index yet.

Outside a configured Xonsh shell, from the checkout:

```sh
PYTHONPATH=.config/xonsh/lib .venv/bin/python -m wes_command_usage explain 'cat @(files)'
PYTHONPATH=.config/xonsh/lib .venv/bin/python -m wes_command_usage --database /tmp/my-experiment.sqlite3 events
```

The default database is `$XDG_STATE_HOME/command-usage/events.sqlite3`, falling
back to `~/.local/state/command-usage/events.sqlite3`. Raw source/argv can include
sensitive strings; the recorder does not copy full environment or stdout/stderr.
There is no sharing, upload, GUI history integration, or automatic history import.

## Disposable data

**No migrations. Breaking changes mean reset.** Keep the tests and examples;
throw away the data. An incompatible store reports that reset is required.
The CLI reset deletes the database even if its schema cannot be opened.
The shell alias closes its recorder, resets, and starts a new recorder/session.
Restart other shells using that same database after reset; do not reset a
live shared store from another process and expect those recorders to recover.
`Store.reset()` clears both raw and derived rows for isolated experiments.

## What is observed

Each event has a dataset ID, session ID, sequence number, operation ID when
available, timestamp, current working directory, host, PID/parent PID, explicit
origin (`cli`), producer (`xonsh`), acquisition (`live`), and optional correlation
ID. Invocation events retain resolved argv, original spec arguments, alias and
executable identity, stream destinations, background status, pipeline position,
and argument existence/type observations at capture time. Invocation IDs link
launch observations to process IDs; **launch is not completion**.

Interactive `on_precommand`/`on_postcommand` provide submitted-operation boundaries
and the shell's final return status. The source is the command Xonsh is executing,
not necessarily the exact pre-transformation keystrokes. A crashed/exiting shell
can leave an operation without a finish event. Background completion and
per-invocation exit statuses are not inferred from a command-level status.

For noninteractive embedding, initialize a Xonsh session and use:

```python
from wes_command_usage import Recorder
recorder = Recorder(database_path, session='caller-session', origin='cli',
                    correlation='optional-caller-id').install()
try:
    recorder.execute(source)  # Execute NEW requested work, never replay history.
finally:
    recorder.close()
```

The embedding boundary supplies an operation for scripts and `xonsh -c`, where
interactive command events are unavailable. Its finish status records Python
execution errors when raised; otherwise the subprocess completion status is
unknown. Python context lives in `XSH.ctx`.

Python audit capture records selected `open` and filesystem events on the command
thread while an operation is active. These are **attempts**, not confirmations.
It includes incidental Python/library/import activity. Worker-thread IO is not
currently attributed. Relative paths using directory descriptors remain unresolved
in the index. No file contents are captured. Counts of audit events are not counts
of deliberate user file selections.

The analyzer preserves origin/acquisition and labels argument candidates,
stream destinations, and Python IO attempts separately. Common command operand
roles are heuristic (especially options, filters, and arbitrary custom tools).
Unknowns remain unknown. Static Python calls and dynamic expressions are not
executed or promoted into observed file accesses. Historical importers can later
supply poorer evidence; they must never fill in missing historical runtime state
using today's filesystem.

## Tests and future spikes

```sh
.venv/bin/pytest -q tests/xonsh/test_command_usage.py
```

Tests launch real Xonsh subprocesses, including an interactive dumb shell with the
actual rc file, using isolated databases/directories. They cover arguments from
Python variables/environment/globs, list and callable aliases, streams, pipelines,
Python IO attempts, changing directories, failures, background launches, writer
failure, reset/version mismatch, deterministic rebuilds, and non-evaluating parsing.
A script silently reading `pyproject.toml` and writing an output is deliberately
verified as **not observed internally**.

**Future spike: OS-level tracing**, including child-process/descendant IO and the
platform-specific privileges and overhead involved. No syscall tracing now.
Also future: independent historical/trace importers, stdout/stderr evidence,
Bash parsing, MCP correlation adapters, session/window grouping and embeddings.
Those consumers can use isolated datasets; they need not share personal history.
