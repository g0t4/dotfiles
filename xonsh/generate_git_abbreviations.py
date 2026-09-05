#!/usr/bin/env python3
"""Generate Xonsh Git abbreviation declarations from the Fish inventory."""

from __future__ import annotations

import shlex
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/git.fish"
TARGET = ROOT / ".config/xonsh/lib/wes_git_abbreviations.py"

VALUE_SUBSTITUTIONS = {
    '"$(_repo_root)"': "$(_repo_root)",
    "$GIT_FULLY_AUTO_REBASE": "GIT_SEQUENCE_EDITOR=true",
    "$_unpushed_commits": "'HEAD@{push}~1..HEAD'",
    "$_unpushed_commits_without_last_pushed": "'HEAD@{push}..HEAD'",
    # This variable is misspelled and unset in the Fish source, so Fish expands
    # it to an empty string when registering glp/glpf.
    "$_unpunched_commits": "",
}


def parse_abbreviation(line_number: int, line: str):
    tokens = shlex.split(line, comments=True, posix=True)
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
        elif token in ("--command", "--function", "--regex", "--position", "--add"):
            options[token[2:]] = tokens[index + 1]
            index += 2
        elif token.startswith("--position="):
            options["position"] = token.partition("=")[2]
            index += 1
        else:
            remaining.append(token)
            index += 1

    name = str(options.get("add") or remaining.pop(0))
    replacement = " ".join(remaining)
    for old, new in sorted(VALUE_SUBSTITUTIONS.items(), key=lambda item: -len(item[0])):
        replacement = replacement.replace(old, new)
    replacement = " ".join(replacement.split())
    replacement = replacement.replace(r"\$(git rev-list --all)", "$(git rev-list --all)")
    return line_number, name, replacement, options


def declaration(line_number, name, replacement, options):
    command = options.get("command")
    if command == "nl" or name == "pln":
        return None

    if name == "-W" and options.get("function") == "_abbr_git_short_to_long":
        return '    abbr("-W", "--function-context", commands=("git", "diff"))'

    trigger = f"re.compile({options['regex']!r})" if "regex" in options else repr(name)
    replacement_expr = (
        f"_fish_abbreviation({options['function']!r})"
        if "function" in options
        else repr(replacement)
    )
    arguments = [trigger, replacement_expr]
    if options.get("position") == "anywhere":
        arguments.append('position="anywhere"')
    if command:
        arguments.append(f"commands=({command!r},)")
    if options.get("cursor"):
        arguments.append('cursor_marker="%"')
    return f"    abbr({', '.join(arguments)})  # Fish line {line_number}"


def generate() -> str:
    declarations = []
    for line_number, line in enumerate(SOURCE.read_text().splitlines(), 1):
        if not line.startswith("abbr "):
            continue
        parsed = parse_abbreviation(line_number, line)
        rendered = declaration(*parsed)
        if rendered:
            declarations.append(rendered)

    header = '''\
"""Git abbreviations generated from fish/load_last_interactive_only/git.fish."""

from __future__ import annotations

import re

from wes_abbreviations import abbr
from wes_fish_bridge import fish_function


def _fish_abbreviation(function_name):
    def expand(context, _match):
        return fish_function(function_name, context.token)

    return expand


def register_git_abbreviations():
'''
    return header + "\n".join(declarations) + "\n"


if __name__ == "__main__":
    TARGET.write_text(generate())
