"""Print a legible ASCII table: character, hex, decimal, and escape values.

Rather than one long list, the values are laid out in a rich table so the
character, hex, decimal, and escape representations are easy to compare.

Control characters show their abbreviation in CHAR (NUL, LF, ...) in a
distinct style; printable characters show their glyph. Escape shorthand
(\\n, \\t, \\r, ...) is shown for control characters where one exists.

By default contiguous letter/digit runs are collapsed to a single row
(e.g. "a-z (lowercase)") to fit more on screen; pass --expand-ranges to list
every character. Pass --descriptions to add a column explaining each control
character.
"""

from __future__ import annotations

import argparse

import argcomplete
from rich.console import Console
from rich.table import Table
from rich.text import Text


# Abbreviations shown in the CHAR column for non-printable control codes.
ABBREVIATIONS: dict[int, str] = {
    0: "NUL",
    1: "SOH",
    2: "STX",
    3: "ETX",
    4: "EOT",
    5: "ENQ",
    6: "ACK",
    7: "BEL",
    8: "BS",
    9: "TAB",
    10: "LF",
    11: "VT",
    12: "FF",
    13: "CR",
    14: "SO",
    15: "SI",
    16: "DLE",
    17: "DC1",
    18: "DC2",
    19: "DC3",
    20: "DC4",
    21: "NAK",
    22: "SYN",
    23: "ETB",
    24: "CAN",
    25: "EM",
    26: "SUB",
    27: "ESC",
    28: "FS",
    29: "GS",
    30: "RS",
    31: "US",
    127: "DEL",
}

# Full descriptions for non-printable ASCII control characters, used in the
# DESCRIPTION column so it does not merely repeat the CHAR column.
CONTROL_DESCRIPTIONS: dict[int, str] = {
    0: "Null",
    1: "Start of Heading",
    2: "Start of Text",
    3: "End of Text",
    4: "End of Transmission",
    5: "Enquiry",
    6: "Acknowledge",
    7: "Bell",
    8: "Backspace",
    9: "Horizontal Tab",
    10: "Line Feed",
    11: "Vertical Tab",
    12: "Form Feed",
    13: "Carriage Return",
    14: "Shift Out",
    15: "Shift In",
    16: "Data Link Escape",
    17: "Device Control 1",
    18: "Device Control 2",
    19: "Device Control 3",
    20: "Device Control 4",
    21: "Negative Acknowledge",
    22: "Synchronous Idle",
    23: "End of Transmission Block",
    24: "Cancel",
    25: "End of Medium",
    26: "Substitute",
    27: "Escape",
    28: "File Separator",
    29: "Group Separator",
    30: "Record Separator",
    31: "Unit Separator",
    32: "Space",
    127: "Delete",
}

# Standard C/Python escape shorthand for control characters that have one.
# Others without a named escape fall back to \\xHH in the ESCAPE column.
ESCAPES: dict[int, str] = {
    0: r"\0",
    7: r"\a",
    8: r"\b",
    9: r"\t",
    10: r"\n",
    11: r"\v",
    12: r"\f",
    13: r"\r",
    27: r"\e",
}

# Contiguous printable runs collapsed by default into a single row.
# (start, end, CHAR label, range description)
COLLAPSED_RANGES: list[tuple[int, int, str, str]] = [
    (48, 57, "0-9 (numbers)", "digits"),
    (65, 90, "A-Z (uppercase)", "uppercase letters"),
    (97, 122, "a-z (lowercase)", "lowercase letters"),
]


def is_nonprintable(code: int) -> bool:
    """Return True for control codes that have no printable glyph."""
    return code in ABBREVIATIONS


def ascii_char(code: int) -> str:
    """Return the glyph or abbreviation for a single ASCII code."""
    if code in ABBREVIATIONS:
        return ABBREVIATIONS[code]
    if code == 32:
        return "\u2423"  # visible space marker (␣)
    return chr(code)


def escape_for(code: int) -> str:
    """Return escape shorthand, or \\xHH for unnamed control codes."""
    if code in ESCAPES:
        return ESCAPES[code]
    if is_nonprintable(code):
        return f"\\x{code:02X}"
    return ""


def build_rows(expand_ranges: bool) -> list[tuple]:
    """Build rows in natural order, collapsing runs unless expanded.

    Each row is either a single code ``(code, None, None, None)`` or a
    collapsed range ``(start, end, char_label, range_description)``.
    """
    rows: list[tuple] = []
    ranges = [] if expand_ranges else COLLAPSED_RANGES
    code = 0
    while code < 128:
        collapsed = next((r for r in ranges if r[0] == code), None)
        if collapsed:
            start, end, char_label, range_description = collapsed
            rows.append((start, end, char_label, range_description))
            code = end + 1
        else:
            rows.append((code, None, None, None))
            code += 1
    return rows


def build_table(show_descriptions: bool, expand_ranges: bool) -> Table:
    """Build the ASCII table, optionally expanding ranges and descriptions."""
    table = Table(title="ASCII Table")
    table.add_column("DEC", justify="right", style="cyan")
    table.add_column("CHAR", justify="center", style="green")
    table.add_column("HEX", justify="right", style="magenta")
    table.add_column("ESCAPE", justify="left", style="blue")
    if show_descriptions:
        table.add_column("DESCRIPTION", style="yellow")

    for start, end, char_label, range_description in build_rows(expand_ranges):
        if char_label is not None:
            # Collapsed range row: show start/end values and the run label.
            dec = f"{start}-{end}"
            hex_value = f"{start:02X}-{end:02X}"
            char_cell = char_label
            escape = ""
            description = range_description
        else:
            code = start
            dec = str(code)
            hex_value = f"{code:02X}"
            escape = escape_for(code)
            description = CONTROL_DESCRIPTIONS.get(code, "")
            if is_nonprintable(code):
                # Distinguish non-printable control codes in the CHAR column.
                char_cell = Text(ascii_char(code), style="italic #808080")
            else:
                char_cell = Text(ascii_char(code), style="green")

        row = [dec, char_cell, hex_value, escape]
        if show_descriptions:
            row.append(description)
        table.add_row(*row)
    return table


def build_parser() -> argparse.ArgumentParser:
    """Build the argument parser (exposed for argcomplete)."""
    parser = argparse.ArgumentParser(
        prog="ascii_table",
        description="Print a legible ASCII table of character, hex, and decimal values.",
    )
    parser.add_argument(
        "-d",
        "--descriptions",
        action="store_true",
        help="show a DESCRIPTION column explaining each control character",
    )
    parser.add_argument(
        "--expand-ranges",
        action="store_true",
        help="list every character instead of collapsing letter/digit runs",
    )
    return parser


def main() -> None:
    """Render the ASCII table to the console."""
    parser = build_parser()
    argcomplete.autocomplete(parser)
    args = parser.parse_args()

    console = Console()
    console.print(build_table(args.descriptions, args.expand_ranges))


if __name__ == "__main__":
    main()
