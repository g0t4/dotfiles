#!/usr/bin/env python3
"""Generate Xonsh declarations from Docker-specific Fish abbreviations."""

from __future__ import annotations

import shlex
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/docker-specific.fish"
TARGET = ROOT / ".config/xonsh/lib/wes_docker_abbreviations.py"


def parse_abbreviation(line_number: int, line: str):
    tokens = shlex.split(line, comments=True, posix=True)
    options: dict[str, bool] = {}
    remaining: list[str] = []
    index = 1
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            remaining.extend(tokens[index + 1 :])
            break
        if token == "--set-cursor":
            options["cursor"] = True
        else:
            remaining.append(token)
        index += 1

    name = remaining.pop(0)
    replacement = " ".join(remaining)
    if replacement.startswith("(grcify ") and replacement.endswith(")"):
        # use_grc_with_docker is explicitly "no" in the Fish source.
        replacement = replacement[len("(grcify ") : -1]
    return line_number, name, replacement, options


def declaration(line_number, name, replacement, options):
    arguments = [repr(name), repr(replacement)]
    if options.get("cursor"):
        arguments.append('cursor_marker="%"')
    return f"    abbr({', '.join(arguments)})  # Fish line {line_number}"


def generate() -> str:
    declarations = []
    for line_number, line in enumerate(SOURCE.read_text().splitlines(), 1):
        if line.startswith("abbr "):
            declarations.append(declaration(*parse_abbreviation(line_number, line)))

    header = '''\
"""Generated from fish/load_last_interactive_only/docker-specific.fish."""

from __future__ import annotations

from wes_abbreviations import abbr


def register_docker_abbreviations():
'''
    return header + "\n".join(declarations) + "\n"


if __name__ == "__main__":
    TARGET.write_text(generate())
