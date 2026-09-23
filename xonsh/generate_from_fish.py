#!/usr/bin/env python3
"""Generate one-to-one Xonsh modules from dedicated Fish source files."""

from __future__ import annotations

from pathlib import Path

from fish_to_xonsh import generate
from generate_misc_abbreviations import (
    DEDUPLICATED_ABBREVIATIONS,
    declaration,
    should_skip,
)


ROOT = Path(__file__).resolve().parents[1]


def gen(fish_file: str, xonsh_module: str) -> None:
    fish_source = ROOT / "fish/load_last_interactive_only" / fish_file
    xonsh_target = ROOT / ".config/xonsh/lib" / f"wes_{xonsh_module}_abbreviations.py"
    content = generate(
        fish_source,
        title=f"{xonsh_module.replace('_', ' ').title()} abbreviations generated "
        f"from Fish {fish_file}.",
        function_name=f"register_{xonsh_module}_abbreviations",
        declaration_factory=declaration,
        should_skip=should_skip,
        deduplicated_names=frozenset(DEDUPLICATED_ABBREVIATIONS),
    )
    xonsh_target.write_text(content)


if __name__ == "__main__":
    # Keep this as the single list of dedicated Fish -> Xonsh mappings.
    gen("cloud-ai-specific.fish", "cloud_ai")
