#!/usr/bin/env python3
"""Generate Xonsh abbreviations from files-search-specific.fish."""

from __future__ import annotations

import shlex
from pathlib import Path

from fish_to_xonsh import declaration, parse_abbreviation


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/files-search-specific.fish"
TARGET = ROOT / ".config/xonsh/lib/wes_files_search_abbreviations.py"


# def declaration(name, replacement, options):
    # if (
    #     options.get("cursor")
    #     and replacement.count("%") == 1
    #     and name not in ("_fdX", "rgu")
    # # TODO do I need to move _fdX / rgu exclusions to fish_to_xonsh.py?
    # ):


def generate() -> str:
    declarations = []
    for line in SOURCE.read_text().splitlines():
        if line.lstrip().startswith("abbr "):
            declarations.append(declaration(*parse_abbreviation(line)))

    header = '''\
"""Generated from Fish's files-search-specific abbreviation inventory."""

from __future__ import annotations

import os
import platform
import re

from wes_abbreviations import AbbreviationResult, abbr
from wes_fish_bridge import UnsupportedFishFunctionError, fish_function
from wes_fish_migration import abbr_from_fish_function, unsupported_abbreviation


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
