#!/usr/bin/env python3
"""Generate Xonsh abbreviations from files-search-specific.fish."""

from __future__ import annotations

import shlex
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/files-search-specific.fish"
TARGET = ROOT / ".config/xonsh/lib/wes_files_search_abbreviations.py"


def parse_abbreviation(line: str):
    tokens = shlex.split(line.strip(), comments=True, posix=True)
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
        elif token in ("--add", "--command", "--function", "--regex"):
            options[token[2:]] = tokens[index + 1]
            index += 2
        else:
            remaining.append(token)
            index += 1
    name = str(options.get("add") or remaining.pop(0))
    return name, " ".join(remaining), options


def declaration(name, replacement, options):
    trigger = (
        f"re.compile({options['regex']!r})"
        if "regex" in options
        else repr(name)
    )
    replacements = {
        "find": "FIND_COMMAND",
        "finde": "f\"{FIND_COMMAND} . -executable\"",
        "findud": "f\"{FIND_COMMAND} '%' -user wesdemos\"",
        "finduw": "f\"{FIND_COMMAND} '%' -user wes\"",
        "h": repr("history show all | bat -l xonsh --color always | less -F"),
        "hgr": repr('history show all | rg_grep "%"'),
        "hm": repr("history pull"),
        "hd": repr('history delete "%"'),
        "list_filetype_extensions": repr(
            "fd --type file | awk -F. 'NF > 1 {print $NF}' | sort | uniq -c | sort"
        ),
        "mdo": "_unsupported_abbreviation('md_open', 'changes directory from an interactive fzf picker')",
        "mdcd": "_unsupported_abbreviation('mdfind_cd_dir', 'changes directory from an interactive fzf picker')",
    }
    functions = {
        "_abbr_expand_fdX": "_expand_fd_depth",
        "_abbr_expand_rgu": "_expand_rgu",
    }
    if name in replacements:
        replacement_expression = replacements[name]
    elif "function" in options:
        replacement_expression = functions.get(
            options["function"], f"_fish_abbreviation({options['function']!r})"
        )
    else:
        replacement = replacement.replace("$find_cmd", "{FIND_COMMAND}")
        replacement_expression = (
            f"f{replacement!r}" if "{FIND_COMMAND}" in replacement else repr(replacement)
        )

    arguments = [trigger, replacement_expression]
    command = options.get("command")
    if command:
        arguments.append('position="anywhere"')
        command_expression = "FIND_COMMAND" if command == "$find_cmd" else repr(command)
        arguments.append(f"commands=({command_expression},)")
    if (
        options.get("cursor")
        and replacement.count("%") == 1
        and name not in ("_fdX", "rgu")
    ):
        arguments.append('cursor_marker="%"')
    return f"    abbr({', '.join(arguments)})"


def generate() -> str:
    declarations = []
    for line in SOURCE.read_text().splitlines():
        if line.lstrip().startswith("abbr "):
            declarations.append(declaration(*parse_abbreviation(line)))

    header = '''\
"""Generated from Fish's files-search-specific abbreviation inventory."""

from __future__ import annotations

import platform
import re

from wes_abbreviations import AbbreviationResult, abbr
from wes_fish_bridge import UnsupportedFishFunctionError, fish_function


FIND_COMMAND = "gfind" if platform.system() == "Darwin" else "find"


def _fish_abbreviation(function_name):
    def expand(context, _match):
        return fish_function(function_name, context.token)

    return expand


def _unsupported_abbreviation(function_name, reason):
    def expand(_context, _match):
        raise UnsupportedFishFunctionError(
            f"{function_name}: TODO SKIPPED_MIGRATION: {reason}"
        )

    return expand


def _expand_fd_depth(context, _match):
    return f"fd --max-depth={context.token.removeprefix('fd')}"


def _expand_rgu(context, _match):
    after_cursor = context.buffer[context.cursor :].strip()
    if after_cursor and not after_cursor.startswith("-"):
        return "rg -u"
    return AbbreviationResult('rg -u ""', cursor=len('rg -u "'))


def register_files_search_abbreviations():
'''
    return header + "\n".join(declarations) + "\n"


if __name__ == "__main__":
    TARGET.write_text(generate())
