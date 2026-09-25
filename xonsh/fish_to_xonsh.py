"""Reusable machinery for generating Xonsh abbreviation modules from Fish."""

from __future__ import annotations

import re
import shlex
from pathlib import Path
from typing import Callable


DeclarationFactory = Callable[[int, str, str, dict[str, str | bool]], str]


def parse_abbreviation(line_number: int, line: str):
    """Parse one Fish ``abbr`` declaration without losing Fish quoting."""
    # Fish accepts backslash-escaped single quotes inside single-quoted text;
    # POSIX shlex does not. Protect those legacy awk expressions while
    # tokenizing, then restore the intended quote character.
    quote_placeholder = "__WES_FISH_SINGLE_QUOTE__"
    tokens = [
        token.replace(quote_placeholder, "'")
        for token in shlex.split(
            line.replace("\\'", quote_placeholder), comments=True, posix=True
        )
    ]
    options: dict[str, str | bool] = {}
    remaining: list[str] = []
    index = 1
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            remaining.extend(tokens[index + 1 :])
            break
        if token == "--set-cursor":
            options["cursor"] = True
            index += 1
        elif token in ("--add", "-a", "--command", "--function", "--regex", "--position"):
            key = "add" if token == "-a" else token[2:]
            options[key] = tokens[index + 1]
            index += 2
        elif token.startswith("--position="):
            options["position"] = token.partition("=")[2]
            index += 1
        else:
            remaining.append(token)
            index += 1

    name = str(options.get("add") or remaining.pop(0))
    return line_number, name, " ".join(remaining), options


def generate(
    source: Path,
    *,
    title: str,
    function_name: str,
    declaration_factory: DeclarationFactory,
    should_skip: Callable[[str, str, dict[str, str | bool]], bool] = (
        lambda _name, _replacement, _options: False
    ),
    deduplicated_names: frozenset[str] = frozenset(),
    call_register: bool = False
) -> str:
    """Render one importable Xonsh module from a Fish source file."""
    declarations = []
    functions = []
    seen = set()
    for line_number, line in enumerate(source.read_text().splitlines(), 1):
        if "# fish-only" in line:
            continue
        if re.match(r"^\s*abbr(?:\s|$)", line):
            parsed = parse_abbreviation(line_number, line)
            _, name, replacement, options = parsed
            identity = (name, replacement, tuple(sorted(options.items())))
            duplicate = name in deduplicated_names and identity in seen
            if not should_skip(name, replacement, options) and not duplicate:
                declarations.append(declaration_factory(*parsed))
            seen.add(identity)
        function_match = re.match(r"^\s*function\s+([^\s]+)", line)
        if function_match:
            functions.append(function_match.group(1))

    declaration_text = "\n".join(declarations)

    register_text = "" if not call_register else f"\n\n{function_name}()"

    return f'''\
"""{title}"""

from __future__ import annotations

import re
import os
import platform

from xonsh.built_ins import XSH
from wes_abbreviations import abbr
from wes_fish_migration import (
    wrap_fish_functions,
    abbr_from_fish_function,
    platform_abbreviation,
    unsupported_abbreviation,
)

# FYI defining this globally clobbers the value for all other modules that came before... b/c there's only one namespace...
# SO, keep in mind, if you try to check this later it will have FISH_FUNCTIONS values from the last module loaded that defined it...
# IOTW only call register immediately and use it right away... IDEALLY lets just inline the list into register function
FISH_FUNCTIONS = (
{"".join(f"    {name!r},\n" for name in functions)}\
)


def {function_name}():
    wrap_fish_functions(XSH.aliases, FISH_FUNCTIONS)
{declaration_text}

{register_text}
'''
