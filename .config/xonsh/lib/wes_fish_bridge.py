"""Compatibility bridge to functions still owned by interactive Fish config."""

from __future__ import annotations

import inspect
import os
import platform
import shlex
import subprocess
import sys
import textwrap
from collections.abc import Sequence
from typing import IO, Any, TypeAlias

from rich.console import Console
from rich.syntax import Syntax
from rich.text import Text

from find_executables import find_fish
from wes_abbreviations import abbr
from wes_logging import get_wes_logger
from wes_syntax_theme import syntax_theme

_FILE: TypeAlias = None | int | IO[Any]
log = get_wes_logger(__name__)

class FishFunctionError(RuntimeError):
    pass


class UnsupportedFishFunctionError(RuntimeError):
    pass


def fish_function_stream(
    name: str,
    args: Sequence[str],
    stdin: _FILE = None,
    stdout: _FILE = None,
    stderr: _FILE = None,
) -> int:
    """Run a Fish function while streaming STDIN and STDOUT/STDERR"""
    env = os.environ.copy()
    # FYI ONLY_CALL_FISH_WRAPPED_FUNC should be used in the fish config to stop any extra ANSI escape codes from being displayed
    env["ONLY_CALL_FISH_WRAPPED_FUNC"] = "true"
    completed = subprocess.run(
        [find_fish(), "-ic", "$argv[1] $argv[2..]", "--", name, *map(str, args)],
        stdin=stdin,
        stdout=stdout,
        stderr=stderr,
        env=env
    )
    return completed.returncode


def fish_function_capture_stdout(
    name: str,
    *args: str,
    input_text: str | None = None,
    timeout: float = 5.0,
) -> str:
    """Call a function through the user's authoritative interactive Fish config.

    Values are passed through Fish's argv rather than interpolated into source.
    Returns stdout with trailing newlines removed, suitable for values or styling.
    """
    env = os.environ.copy()
    env["ONLY_CALL_FISH_WRAPPED_FUNC"] = "true"
    env.pop("TERM_PROGRAM", None)
    completed = subprocess.run(
        [find_fish(), "-ic", "$argv[1] $argv[2..]", "--", name, *map(str, args)],
        capture_output=True,
        text=True,
        input=input_text,
        timeout=timeout,
        env=env,
    )
    stdout = completed.stdout.rstrip("\n")
    stderr = completed.stderr.strip()
    # TODO we shouldn't throw away STDERR when non-zero exit code...
    # TODO also, nothing should be using this if it needs streaming STDOUT/STDERR!
    if completed.returncode:
        detail = f": {stderr}" if stderr else ""
        raise FishFunctionError(
            f"fish function {name!r} exited {completed.returncode}{detail}"
        )
    return stdout


def fish_function_source(function_name: str) -> str:
    """Fetch uncolored Fish source for viewers to style with our palette."""
    return fish_function_capture_stdout("functions", "--color", "never", function_name)


def fish_function_stream_invoke(function_name):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        try:
            return fish_function_stream(function_name, args, stdin=stdin, stdout=stdout, stderr=stderr)
        except FishFunctionError as error:
            print(error, file=stderr or sys.stderr)
            return 1

    return invoke


UNSUPPORTED_FISH_FUNCTIONS = {
    "_abbr_ze": "reads and rewrites the current command buffer",
    "_define_devtools_abbrs": "defines abbreviations in the current shell",
    "_expand_watch_last": "reads the current shell history",
    "_k3s_autocomplete": "reads the current command buffer",
    "cd2": "changes the current shell directory",
    "custom-kill-command-word": "rewrites the current command buffer",
    "toggle-git_commit_command": "rewrites the current command buffer",
    "toggle-grc": "rewrites the current command buffer",
    "toggle_show_verbose_prompt": "changes current-shell prompt state",
    "use_nvim_from_source": "changes current-shell environment variables",
}

SKIPPED_FISH_FUNCTIONS = {
    # This is a Fish variable event handler, not a user-facing command.
    "on_change_show_verbose_prompt",
    # z.xsh already provides a state-aware bridge that changes Xonsh's cwd.
    "z",
    # processes.xsh installs the native current-shell implementation.
    "build_abbrs_for_filetype",
    # python-specific.xsh installs a native wrapper that can change Xonsh's cwd.
    "wcl",
}

def abbr_from_fish_function(function_name):
    def expand(context, _match):
        reason = UNSUPPORTED_FISH_FUNCTIONS.get(function_name)
        if reason:
            raise UnsupportedFishFunctionError(
                f"Fish abbreviation function {function_name!r} requires a native "
                f"Xonsh migration: {reason}"
            )
        return fish_function_capture_stdout(function_name, context.token)

    return expand


def unsupported_abbreviation(name, reason):
    def expand(_context, _match):
        raise UnsupportedFishFunctionError(
            f"Fish abbreviation {name!r} requires a native Xonsh migration: "
            f"{reason}"
        )

    return expand


def platform_abbreviation(darwin, other):
    return darwin if platform.system() == "Darwin" else other

def unsupported_fish_alias(function_name, reason):
    def invoke(_args, **_):
        raise UnsupportedFishFunctionError(
            f"Fish function {function_name!r} requires a native Xonsh migration: "
            f"{reason}"
        )

    return invoke


def wrap_fish_functions(aliases, function_names):

    # !!! FYI if there are any ANSI escape codes coming out of fish...
    # ! ... do not fix them here, instead fix them in the fish config
    # ! INSTEAD, BLOCK them in the fish config with `set --query ONLY_CALL_FISH_WRAPPED_FUNC`

    def fish_help(args, stdin=None, stdout=None, stderr=None, spec=None, **_):
        if len(args) != 1:
            print("usage: _fish_help FUNCTION", file=stderr)
            return 2
        name = args[0]
        # Xonsh's REPL dispatcher stream may not report itself as a TTY.
        # Color the last pipeline command, including explicit file redirects.
        use_color = spec and bool(spec.last_in_pipeline)
        log.info(f'{use_color=} {spec=}')
        console = Console(file=stdout, force_terminal=use_color)
        console.rule(Text(f"Xonsh wrapper: {name}", style="bold cyan"), style="cyan")
        try:
            wrapper = aliases[name]
            wrapper = getattr(wrapper, "func", wrapper)
            console.print(Syntax(
                textwrap.dedent(inspect.getsource(wrapper)).rstrip(),
                "python", theme=syntax_theme(), background_color="default",
            ))
        except (KeyError, OSError, TypeError) as error:
            console.print(Text(f"Source unavailable: {error}", style="dim"))
        console.print()
        console.rule(Text(f"Fish implementation: {name}", style="bold green"), style="green")
        console.file.flush()
        fish_func_definition = fish_function_source(name)
        console.print(Syntax(fish_func_definition, "fish", theme=syntax_theme(), background_color="default"))

    aliases["_fish_help"] = fish_help
    for function_name in function_names:
        if function_name in SKIPPED_FISH_FUNCTIONS:
            continue
        reason = UNSUPPORTED_FISH_FUNCTIONS.get(function_name)
        aliases[function_name] = (
            unsupported_fish_alias(function_name, reason)
            if reason
            else fish_function_stream_invoke(function_name)
        )
        # register enhanced "superhelp" that includes the fish function body
        abbr(function_name + "??", f"_fish_help {shlex.quote(function_name)}")


def captured_fish_alias(function_name):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        input_text = stdin.read() if stdin is not None else None
        try:
            output = fish_function_capture_stdout(function_name, *args, input_text=input_text)
        except FishFunctionError as error:
            print(error, file=stderr or sys.stderr)
            return 1
        if output:
            print(output, file=stdout or sys.stdout)
        return 0

    return invoke
