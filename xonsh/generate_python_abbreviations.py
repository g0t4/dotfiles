#!/usr/bin/env python3
"""Generate Xonsh abbreviations from Fish's python-specific config."""

from __future__ import annotations

import re
from pathlib import Path

from generate_misc_abbreviations import parse_abbreviation


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/python-specific.fish"
TARGET = ROOT / ".config/xonsh/lib/wes_python_abbreviations.py"

COMMON_PACKAGES = "ipython ipykernel yapf rope rich httpx pytest pytest-watch"

EXACT_REPLACEMENTS = {
    7: 'PYTHONPROFILEIMPORTTIME=1 python -c "from sentence_transformers import SentenceTransformer"',
    63: "source .venv*/bin/activate.xsh",
    147: "uv pip install --upgrade $(uv pip list --outdated | tail +3 | cut -d' ' -f1)",
}


def _declaration(line_number: int, name: str, replacement: str, options: dict) -> str:
    replacement = EXACT_REPLACEMENTS.get(line_number, replacement)
    replacement = replacement.replace("$_pypi_common", COMMON_PACKAGES)

    if line_number == 28:
        replacement_expression = (
            "platform_abbreviation("
            "'pkill -ilf \"python.*3.13.5\"', "
            "'pkill -if \"python.*3.13.5\"')"
        )
    elif "function" in options:
        replacement_expression = f"fish_abbreviation({options['function']!r})"
    else:
        replacement_expression = repr(replacement)

    arguments = [repr(name), replacement_expression]
    if options.get("command"):
        arguments.extend((
            'position="anywhere"',
            f"commands=({options['command']!r},)",
        ))
    if options.get("cursor") and (replacement.count("%") == 1 or "function" in options):
        arguments.append('cursor_marker="%"')
    return f"    abbr({', '.join(arguments)})  # Fish line {line_number}"


def _source_inventory():
    abbreviations = []
    functions = []
    for line_number, line in enumerate(SOURCE.read_text().splitlines(), 1):
        if re.match(r"^\s*abbr(?:\s|$)", line):
            abbreviations.append(parse_abbreviation(line_number, line))
        function_match = re.match(r"^\s*function\s+([^\s]+)", line)
        if function_match:
            functions.append((function_match.group(1), line_number))
    return abbreviations, functions


def generate() -> str:
    abbreviations, functions = _source_inventory()

    # Fish replaces an existing abbreviation when the same trigger is declared
    # again. Preserve the final declaration while retaining source order.
    last_declaration_by_name = {
        name: index
        for index, (_line_number, name, _replacement, _options) in enumerate(abbreviations)
    }
    declarations = [
        _declaration(*abbreviation)
        for index, abbreviation in enumerate(abbreviations)
        if last_declaration_by_name[abbreviation[1]] == index
    ]
    function_inventory = "".join(
        f"    {name!r},  # Fish line {line_number}\n"
        for name, line_number in functions
    )
    declaration_text = "\n".join(declarations)

    return f'''\
"""Python abbreviations generated from Fish python-specific.fish."""

from __future__ import annotations

from wes_abbreviations import abbr
from wes_misc_abbreviation_bridge import fish_abbreviation, platform_abbreviation


FISH_FUNCTIONS = (
{function_inventory})


def register_python_abbreviations():
{declaration_text}
'''


if __name__ == "__main__":
    TARGET.write_text(generate())
