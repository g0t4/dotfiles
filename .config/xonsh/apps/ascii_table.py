"""Print a legible ASCII table: character, hex, and decimal values.

Rather than one long list, the values are laid out in a rich table so the
character, hex, and decimal representations are easy to compare at a glance.
"""

from __future__ import annotations

from rich.console import Console
from rich.table import Table


# Human-readable names for non-printable ASCII control characters.
CONTROL_NAMES: dict[int, str] = {
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
    32: "SPACE",
    127: "DEL",
}


def ascii_name(code: int) -> str:
    """Return the printable character or a descriptive name for `code`."""
    if code in CONTROL_NAMES:
        return CONTROL_NAMES[code]
    return chr(code)


def build_table() -> Table:
    """Build the ASCII table with DEC, HEX, CHAR, and NAME columns."""
    table = Table(title="ASCII Table")
    table.add_column("DEC", justify="right", style="cyan")
    table.add_column("HEX", justify="right", style="magenta")
    table.add_column("CHAR", justify="center", style="green")
    table.add_column("NAME", style="yellow")

    for code in range(128):
        table.add_row(
            str(code),
            f"{code:02X}",
            ascii_name(code),
            CONTROL_NAMES.get(code, ""),
        )
    return table


def main() -> None:
    """Render the ASCII table to the console."""
    console = Console()
    console.print(build_table())


if __name__ == "__main__":
    main()
