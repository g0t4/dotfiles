#!/usr/bin/env python3
"""Generate Xonsh declarations from Fish Ansible abbreviations."""

from __future__ import annotations

import re
import shlex
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/ansibles.fish"
TARGET = ROOT / ".config/xonsh/lib/wes_ansible_abbreviations.py"


def parse_abbreviation(line_number: int, line: str):
    tokens = shlex.split(line, comments=True, posix=True)
    cursor = False
    remaining = []
    for token in tokens[1:]:
        if token == "--set-cursor":
            cursor = True
        else:
            remaining.append(token)
    name = remaining.pop(0)
    return line_number, name, " ".join(remaining), cursor


def generate() -> str:
    declarations = []
    functions = []
    for line_number, line in enumerate(SOURCE.read_text().splitlines(), 1):
        if re.match(r"^\s*abbr(?:\s|$)", line):
            number, name, replacement, cursor = parse_abbreviation(line_number, line)
            arguments = [repr(name), repr(replacement)]
            if cursor:
                arguments.append('cursor_marker="%"')
            declarations.append(
                f"    abbr({', '.join(arguments)})  # Fish line {number}"
            )
        function_match = re.match(r"^\s*function\s+([^\s]+)", line)
        if function_match:
            functions.append((function_match.group(1), line_number))

    function_inventory = "".join(
        f"    {name!r},  # Fish line {line_number}\n"
        for name, line_number in functions
    )
    header = '''\
"""Generated from fish/load_last_interactive_only/ansibles.fish."""

from __future__ import annotations

from wes_abbreviations import AbbreviationRegistry, abbr


FISH_FUNCTIONS = (
'''
    footer = '''\
)


def register_ansible_abbreviations():
'''
    return header + function_inventory + footer + "\n".join(declarations) + "\n"


if __name__ == "__main__":
    TARGET.write_text(generate())
