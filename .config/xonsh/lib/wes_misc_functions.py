"""Xonsh callable-alias adapters for functions still implemented by Fish."""

from __future__ import annotations

import inspect
import shlex
import textwrap

from rich.console import Console
from rich.syntax import Syntax
from rich.text import Text

from wes_fish_bridge import UnsupportedFishFunctionError, fish_function_command
from wes_abbreviations import abbr
from wes_logging import get_logger
log = get_logger(__name__)


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


def fish_command_alias(function_name):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        return fish_function_command(
            function_name,
            *args,
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
        )

    return invoke


def unsupported_fish_alias(function_name, reason):
    def invoke(_args, **_):
        raise UnsupportedFishFunctionError(
            f"Fish function {function_name!r} requires a native Xonsh migration: "
            f"{reason}"
        )

    return invoke


def register_misc_fish_functions(aliases, function_names):
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
                "python", theme="ansi_dark", background_color="default",
            ))
        except (KeyError, OSError, TypeError) as error:
            console.print(Text(f"Source unavailable: {error}", style="dim"))
        console.print()
        console.rule(Text(f"Fish implementation: {name}", style="bold green"), style="green")
        console.file.flush()
        return fish_function_command(
            "type", "--color=" + ("always" if console.is_terminal else "never"),
            name, stdin=stdin, stdout=stdout, stderr=stderr
        )

    aliases["_fish_help"] = fish_help
    for function_name in function_names:
        if function_name in SKIPPED_FISH_FUNCTIONS:
            continue
        reason = UNSUPPORTED_FISH_FUNCTIONS.get(function_name)
        aliases[function_name] = (
            unsupported_fish_alias(function_name, reason)
            if reason
            else fish_command_alias(function_name)
        )
        # register enhanced "superhelp" that includes the fish function body
        abbr(function_name + "??", f"_fish_help {shlex.quote(function_name)}")
