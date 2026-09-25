"""Reusable machinery for generating Xonsh abbreviation modules from Fish."""

from __future__ import annotations

import re
import shlex
from pathlib import Path
from typing import Callable


DeclarationFactory = Callable[[int, str, str, dict[str, str | bool]], str]


def parse_abbreviation(line: str, VALUE_SUBSTITUTIONS:dict[str, str] = {}):
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
    # import rich
    # rich.print(tokens)
    #
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
    replacement = " ".join(remaining)
    for old, new in VALUE_SUBSTITUTIONS.items():
        if type(old) == re.Pattern:
            replacement = re.sub(old, new, replacement)
        else:
            replacement = replacement.replace(old, new)
    return name, replacement, options


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
            parsed = parse_abbreviation(line)
            name, replacement, options = parsed
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


def {function_name}():
    fish_funcs = (
{"".join(f"        {name!r},\n" for name in functions)}\
    )
    wrap_fish_functions(XSH.aliases, fish_funcs)
{declaration_text}

{register_text}
'''
