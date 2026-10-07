"""Pure helpers for Vim-style Ctrl-A / Ctrl-X number increment & decrement.

Kept free of prompt_toolkit / xonsh dependencies so the logic can be unit
tested without spinning up an interactive shell.
"""

from __future__ import annotations

import re

_NUMBER_RE = re.compile(r"-?\d+")


def find_number_range(text: str, pos: int) -> tuple[int, int] | None:
    """Return the (start, end) span of the number to increment/decrement.

    Mirrors Vim's Ctrl-A/Ctrl-X: the number *under or after* the cursor wins.
    If no number is at or after the cursor, fall back to the nearest number
    *before* the cursor (so an end-of-line cursor still targets the trailing
    number).

    A leading minus sign is only folded into the number when it directly
    precedes the digits, so ``-5`` is one number while ``5 - 3`` yields the two
    numbers ``5`` and ``3``.
    """
    matches = list(_NUMBER_RE.finditer(text))
    if not matches:
        return None

    # 1. A number the cursor is inside (or sits immediately after) wins.
    for match in matches:
        if match.start() <= pos <= match.end():
            return match.start(), match.end()

    # 2. Otherwise the next number strictly after the cursor.
    for match in matches:
        if match.start() >= pos:
            return match.start(), match.end()

    # 3. Fall back to the last number before the cursor.
    for match in reversed(matches):
        if match.end() <= pos:
            return match.start(), match.end()

    return None


def _format_number(value: int, original: str) -> str:
    """Format ``value`` preserving any leading zeros from ``original``.

    Vim keeps the original field width (``007`` + 1 == ``008``). We mirror that,
    but never pad a lone ``0`` into a longer string.
    """
    sign = "-" if value < 0 else ""
    magnitude = abs(value)
    digits = original.lstrip("-")
    if digits.startswith("0") and len(digits) > 1:
        return sign + str(magnitude).zfill(len(digits))
    return sign + str(magnitude)


def _apply_delta(text: str, pos: int, count: int) -> tuple[str, int] | None:
    """Apply ``count`` (signed) to the number at/after ``pos``.

    Returns ``(new_text, new_cursor_pos)`` or ``None`` when no number is found.
    """
    found = find_number_range(text, pos)
    if found is None:
        return None
    start, end = found
    original = text[start:end]
    try:
        value = int(original)
    except ValueError:
        return None

    new_num = _format_number(value + count, original)
    new_text = text[:start] + new_num + text[end:]
    new_pos = start + len(new_num)
    return new_text, new_pos


def increment_number(text: str, pos: int, count: int = 1) -> tuple[str, int] | None:
    """Increment the number at/after ``pos`` by ``count``."""
    return _apply_delta(text, pos, count)


def decrement_number(text: str, pos: int, count: int = 1) -> tuple[str, int] | None:
    """Decrement the number at/after ``pos`` by ``count``."""
    return _apply_delta(text, pos, -count)
