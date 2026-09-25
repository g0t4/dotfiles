#!/usr/bin/env python3
"""Generate Xonsh declarations from filesystem-related Fish abbreviations."""

from __future__ import annotations

import shlex
from pathlib import Path
from fish_to_xonsh import declaration, parse_abbreviation


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/files-specific.fish"
TARGET = ROOT / ".config/xonsh/lib/wes_files_abbreviations.py"

VALUE_SUBSTITUTIONS = {
    "$dust_lots_of_lines": "--number-of-lines 500",
}


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


def register_files_abbreviations():
'''
    return header + "\n".join(declarations) + "\n"


if __name__ == "__main__":
    TARGET.write_text(generate())
