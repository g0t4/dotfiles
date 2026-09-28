"""Print a legible ASCII table: character, hex, and decimal values.

Rather than one long list, the values are laid out in a rich table so the
character, hex, and decimal representations are easy to compare at a glance.
By default only DEC/CHAR/HEX are shown; pass --descriptions to add a column
explaining each control character.
"""

from __future__ import annotations

import argparse

import argcomplete
from rich.console import Console
from rich.table import Table


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


def ascii_char(code: int) -> str:
    """Return the printable character, or a placeholder for control codes."""
    if code in CONTROL_DESCRIPTIONS:
        return ""
    return chr(code)


def build_table(show_descriptions: bool) -> Table:
    """Build the ASCII table, optionally including a DESCRIPTION column."""
    table = Table(title="ASCII Table")
    table.add_column("DEC", justify="right", style="cyan")
    table.add_column("CHAR", justify="center", style="green")
    table.add_column("HEX", justify="right", style="magenta")
    if show_descriptions:
        table.add_column("DESCRIPTION", style="yellow")

    for code in range(128):
        row = [str(code), ascii_char(code), f"{code:02X}"]
        if show_descriptions:
            row.append(CONTROL_DESCRIPTIONS.get(code, ""))
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
    return parser


def main() -> None:
    """Render the ASCII table to the console."""
    parser = build_parser()
    argcomplete.autocomplete(parser)
    args = parser.parse_args()

    console = Console()
    console.print(build_table(args.descriptions))


if __name__ == "__main__":
    main()
