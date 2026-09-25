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
    stdlib_imports = []
    if "re.compile" in declaration_text:
        stdlib_imports.append("import re")
    platform_constants = []
    if "MAN_COMMAND" in declaration_text:
        platform_constants.append(
            'MAN_COMMAND = "gman" if platform.system() == "Darwin" else "man"'
        )
    if "SED_COMMAND" in declaration_text:
        platform_constants.append(
            'SED_COMMAND = "gsed" if platform.system() == "Darwin" else "sed"'
        )
    if platform_constants:
        stdlib_imports.insert(0, "import platform")
    stdlib_imports_text = (
        "\n".join(stdlib_imports) + "\n\n" if stdlib_imports else ""
    )
    platform_constants_text = (
        "\n".join(platform_constants) + "\n\n" if platform_constants else ""
    )

    return f'''\
"""{title}"""

from __future__ import annotations

from xonsh.built_ins import XSH
{stdlib_imports_text}\
from wes_abbreviations import abbr
from wes_fish_migration import (
    wrap_fish_functions,
    abbr_from_fish_function,
    platform_abbreviation,
    unsupported_abbreviation,
)

{platform_constants_text}\
FISH_FUNCTIONS = (
{"".join(f"    {name!r},\n" for name in functions)}\
)


def {function_name}():
    wrap_fish_functions(XSH.aliases, FISH_FUNCTIONS)
{declaration_text}
'''
