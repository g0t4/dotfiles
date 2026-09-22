"""Tests for the ``showkey`` Python clone."""

from __future__ import annotations

import pytest

from wes_showkey import utf8_continuations, visualize_byte, visualize_char


@pytest.mark.parametrize(
    ("byte", "expected"),
    [
        (0x00, 0),
        (0x7F, 0),
        (0xC2, 1),
        (0xDF, 1),
        (0xE0, 2),
        (0xEF, 2),
        (0xF0, 3),
        (0xF7, 3),
        (0x80, -1),
        (0xFF, -1),
    ],
)
def test_utf8_continuations(byte: int, expected: int) -> None:
    assert utf8_continuations(byte) == expected


@pytest.mark.parametrize(
    ("codepoint", "expected"),
    [
        (0x00, "<NUL>"),
        (0x03, "<CTL-C=ETX>"),
        (0x0D, "<CTL-M=CR>"),
        (0x1B, "<ESC>"),
        (0x20, "<SP>"),
        (0x7F, "<DEL>"),
        (0x41, "A"),
        (0x7A, "z"),
        (0xE085, "\\ue085"),
        (0x1F600, "\\U0001f600"),
    ],
)
def test_visualize_char(codepoint: int, expected: str) -> None:
    assert visualize_char(codepoint) == expected


@pytest.mark.parametrize(
    ("byte", "expected"),
    [
        (0x00, "<NUL>"),
        (0x03, "<CTL-C=ETX>"),
        (0x1B, "<ESC>"),
        (0x20, "<SP>"),
        (0x7F, "<DEL>"),
        (0x41, "A"),
        # High bit set: treated as ALT, and no extra "<" is emitted.
        (0x82, "<ALT-CTL-B=STX>"),
        (0xEE, "<ALT-n>"),
    ],
)
def test_visualize_byte(byte: int, expected: str) -> None:
    assert visualize_byte(byte) == expected


def test_visualize_byte_alt_control_has_single_opening_bracket() -> None:
    """Regression: a byte with both ALT and control bits must not emit '<<'."""
    result = visualize_byte(0x82)
    assert result.startswith("<ALT-")
    assert "<" in result
    assert result.count("<") == 1
