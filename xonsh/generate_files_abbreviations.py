#!/usr/bin/env python3
"""Generate Xonsh declarations from filesystem-related Fish abbreviations."""

from __future__ import annotations

import shlex
from pathlib import Path
from fish_to_xonsh import parse_abbreviation


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/files-specific.fish"
TARGET = ROOT / ".config/xonsh/lib/wes_files_abbreviations.py"

VALUE_SUBSTITUTIONS = {
    "$dust_lots_of_lines": "--number-of-lines 500",
}


def declaration(name, replacement, options):
    # TODO! consoldate this too? like parse_abbreviation?
    trigger = f"re.compile({options['regex']!r})" if "regex" in options else repr(name)
    if name == "ask_status":
        replacement_expression = "_ask_status"
    elif "function" in options:
        function_name = options["function"]
        # TODO! don't we have a better "native" approach?
        native = {
            "_expand_dots_in_command_position": "_expand_dots_command",
            "_expand_dots_only": "_expand_dots_only",
            "expand_zsh_equals": "_expand_zsh_equals",
        }
        replacement_expression = native.get(
            function_name, f"abbr_from_fish_function({function_name!r})"
        )
    else:
        replacement_expression = repr(replacement)

    arguments = [trigger, replacement_expression]
    if options.get("position") == "anywhere" or options.get("command"):
        arguments.append('position="anywhere"')
    if options.get("command"):
        arguments.append(f"commands=({options['command']!r},)")
    if options.get("cursor"):
        arguments.append('cursor_marker="%"')
    return f"    abbr({', '.join(arguments)})"


def generate() -> str:
    declarations = []
    for line in SOURCE.read_text().splitlines():
        if line.startswith("abbr "):
            declarations.append(declaration(*parse_abbreviation(line, VALUE_SUBSTITUTIONS)))

    header = '''\
"""Generated from fish/load_last_interactive_only/files-specific.fish."""

from __future__ import annotations

import re
import shlex
import shutil

from wes_abbreviations import abbr
from wes_fish_bridge import fish_function
from wes_fish_migration import abbr_from_fish_function


def _dot_count(token):
    dots = token.removeprefix("cd")
    return "../" * (len(dots) - 1)


def _expand_dots_command(context, _match):
    return "cd " + _dot_count(context.token)


def _expand_dots_only(context, _match):
    return _dot_count(context.token)


def _expand_zsh_equals(context, _match):
    return shutil.which(context.token.removeprefix("="))


def _ask_status(_context, _match):
    repositories = ("dotfiles", "ask-openai.nvim", "devtools.nvim")
    paths = [fish_function("__z", "--echo", repository) for repository in repositories]
    return "; ".join(f"git -C {shlex.quote(path)} status" for path in paths)


def register_files_abbreviations():
'''
    return header + "\n".join(declarations) + "\n"


if __name__ == "__main__":
    TARGET.write_text(generate())
