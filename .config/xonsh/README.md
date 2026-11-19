# Xonsh configuration conventions

Use Python mode for configuration. Treat Xonsh shell syntax as an interactive
interface, not as the default configuration language.

## Variables and environment

Use ordinary Python variables for state that exists only inside the shell
process:

```python
completion_timeout = 0.25
feature_enabled = True
```

Do not put `$` in front of Python-only variables. A `$NAME` is an environment
variable in Xonsh, not a general-purpose variable declaration.

Set environment variables explicitly through `XSH.env`:

```python
from xonsh.built_ins import XSH

XSH.env["EDITOR"] = "nvim"
XSH.env["MY_TOOL_HOME"] = "/path/to/tool"
```

This makes the export boundary visible in the code. Xonsh uses `XSH.env` when
constructing environments for child processes. With `UPDATE_OS_ENVIRON` enabled,
the same assignment is also synchronized into Python's `os.environ`.

`XSH.env` retains typed Python values inside Xonsh. Access through `$NAME` returns
the same typed value; conventional process-environment interfaces receive its
detyped string representation:

```python
import os
from pathlib import Path
from xonsh.built_ins import XSH

project_root = Path("/Users/wesdemos/repos/github/g0t4/example")
XSH.env["PROJECT_ROOT"] = project_root

assert XSH.env["PROJECT_ROOT"] is project_root
assert isinstance(XSH.env["PROJECT_ROOT"], Path)

# UPDATE_OS_ENVIRON mirrors the detyped value for ordinary Python libraries.
assert os.getenv("PROJECT_ROOT") == str(project_root)
assert isinstance(os.getenv("PROJECT_ROOT"), str)
```

The equivalent access in Xonsh syntax also retains the `Path`:

```xonsh
assert isinstance($PROJECT_ROOT, Path)
```

Child processes can only receive strings, so Xonsh detypes the value when it
constructs their environment as well. This is independent of
`UPDATE_OS_ENVIRON`; that setting controls the additional in-process mirror into
Python's `os.environ`.

Names ending in `PATH` are a special case in Xonsh: they normally match its
`EnvPath` type and detype to an OS-separated path string. Use a name such as
`PROJECT_ROOT` when the intended in-shell value is one `Path` object rather than
a path-list environment variable.

Do not use `$NAME = value` in committed configuration files. The `$` syntax is
fine for ad-hoc commands at the interactive Xonsh prompt, where its shell meaning
is obvious:

```xonsh
$EDITOR = "nvim"
echo $EDITOR
```

Do not use `os.environ` as the primary configuration API. `XSH.env` is the
authoritative environment for the shell; synchronization is intentionally from
Xonsh into `os.environ`.

Use uppercase names for environment variables and ordinary lower-case Python
names for internal state. This makes the boundary recognizable without reading
the assignment:

```python
request_timeout = 0.25
XSH.env["REQUESTS_CA_BUNDLE"] = "/path/to/ca.pem"
```

Register types for custom environment settings that must survive inheritance by
nested Xonsh processes:

```python
XSH.env.register("MY_FEATURE", type="bool", default=True)
XSH.env["MY_FEATURE"] = False
```

Without a registered converter, process inheritance turns values such as
`False` into strings.

## File and execution mode

Prefer `.py` files for shell configuration, including:

- environment setup;
- aliases and callable registration;
- event handlers and keybindings;
- filesystem operations;
- parsing and data transformation;
- invoking Xonsh or Prompt Toolkit APIs.

Prefer importable modules with explicit registration functions over repeatedly
executed fragments:

```python
from wes_example import register_example

register_example(XSH)
```

This gives normal Python import caching, clearer ownership, and focused tests.
Keep registration idempotent when a file may be reloaded interactively.

Use `.xsh` only when the file genuinely benefits from literal shell syntax, such
as a shell script built around pipelines, redirections, background jobs, or
Xonsh-specific command composition. Shell mode remains appropriate for ad-hoc
commands in the REPL.

When loading trusted configuration fragments that do not need `source` semantics
such as `$ARGS`, `$XONSH_MODE`, or temporary `__file__` values, execute them
directly instead of dispatching the `source` shell alias:

```python
source_text = config_file.read_text()
XSH.builtins.execx(source_text, "exec", XSH.ctx, filename=str(config_file))
```

## External commands

Use the narrowest execution mechanism that expresses the task:

1. Prefer an in-process Python API such as `Path.read_text()`.
2. Use `subprocess.run()` when an external executable is necessary.
3. Use Xonsh shell mode when pipelines, redirection, alias dispatch, or other
   shell composition provides real value.

This is primarily a clarity rule, but it also avoids measurable configuration
overhead. A shell command activates command resolution, argument expansion,
pipeline and proxy setup, redirection, process tracking, and shell events.

## Startup discipline

Keep top-level configuration deterministic and cheap:

- Do not launch subprocesses merely to discover static configuration.
- Defer optional discovery until the feature is first used.
- Import heavy or rarely used modules inside the function that needs them.
- Build collections such as PATH in memory and assign the environment once.
- Prefer targeted filesystem traversal and prune generated trees such as
  `.venv`, `node_modules`, `.git`, and `__pycache__` before descending.
- Cache stable discovery results with an invalidation rule instead of rescanning
  on every shell startup or prompt render.
- Keep diagnostics on-demand unless their startup check prevents immediate data
  loss or a security failure.

File organization is not a meaningful optimization target by itself. Empty or
comment-only rc files cost roughly a fraction of a millisecond each; keep related
configuration separated when that improves comprehension. Profile executable
top-level work before consolidating files.

## Practical review checklist

For new configuration, ask:

- Is this value Python-only? Use a normal Python variable.
- Must shell commands or child processes receive it? Use `XSH.env` explicitly.
- Must a custom value retain a type across nested shells? Register its type.
- Am I using `.xsh` only because the repository already contains `.xsh` files?
  Prefer `.py` for new configuration.
- Am I launching a command to do something available directly in Python? Use the
  Python API.
- Do I genuinely need shell composition? If yes, shell mode is appropriate.
- Is this import or discovery needed before the first prompt? If not, defer it.
- Am I assigning the same environment collection repeatedly? Build it locally
  and publish it once.

Apply these conventions prospectively. Existing `.xsh` configuration can be
migrated when it is already being changed or when profiling identifies a useful
reason; a wholesale rewrite is not required.
