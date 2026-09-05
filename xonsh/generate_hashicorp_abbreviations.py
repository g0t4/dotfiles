#!/usr/bin/env python3
"""Generate Xonsh abbreviations from the Fish-compatible HashiCorp source."""

from __future__ import annotations

import shlex
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "zsh/compat_fish/hashicorp.zsh"
TARGET = ROOT / ".config/xonsh/lib/wes_hashicorp_abbreviations.py"


def generate() -> str:
    declarations = []
    for line_number, line in enumerate(SOURCE.read_text().splitlines(), 1):
        if not line.lstrip().startswith("abbr "):
            continue
        tokens = shlex.split(line, comments=True, posix=True)
        trigger, replacement = tokens[1:3]
        declarations.append(
            f"    abbr({trigger!r}, {replacement!r})"
            f"  # HashiCorp line {line_number}"
        )

    return '''\
"""Generated from zsh/compat_fish/hashicorp.zsh."""

from __future__ import annotations

from wes_abbreviations import abbr


def register_hashicorp_abbreviations():
''' + "\n".join(declarations) + "\n"


if __name__ == "__main__":
    TARGET.write_text(generate())
