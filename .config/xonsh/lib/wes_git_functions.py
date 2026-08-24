"""Native helpers required where interactive Fish cannot preserve semantics."""

from __future__ import annotations


YELLOW = "\x1b[33m"
NORMAL = "\x1b[0m"


def format_line_numbers(text: str) -> str:
    """Mirror the numbered, yellow awk output used by Fish's line_numbers."""
    return "".join(
        f"{YELLOW}{number:4d}{NORMAL} {line}\n"
        for number, line in enumerate(text.splitlines(), 1)
    )
