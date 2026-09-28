"""A hex dump viewer that doesn't suck.

Reads bytes from STDIN and renders them hexdump-style: hex bytes on the left,
printable characters on the right. Each byte is colored by its position within
a group of 8 so the left hex column and right character column correspond
without having to count.
"""

from __future__ import annotations

import sys
from pathlib import Path

from rich.console import Console
from rich.text import Text


# One color per byte position within a group of 8; the cycle repeats each group
# so a given column always has the same color.
BYTE_COLORS: tuple[str, ...] = (
    "red",
    "green",
    "yellow",
    "blue",
    "magenta",
    "cyan",
    "bright_red",
    "bright_green",
)

GROUP_SIZE = 8
BYTES_PER_LINE = 16


def printable_char(byte: int) -> str:
    """Return a printable representation of a byte, or a placeholder."""
    if 32 <= byte < 127:
        return chr(byte)
    return "·"


def color_for_index(index: int) -> str:
    """Return the color for a byte at a 0-based index within its group."""
    return BYTE_COLORS[index % GROUP_SIZE]


def format_line(offset: int, data: bytes) -> Text:
    """Render a single line of the hex dump with per-byte color coding."""
    line = Text()
    line.append(f"{offset:08X}  ", style="dim")

    # Left side: hex bytes grouped in 8s with a divider.
    for group_start in range(0, BYTES_PER_LINE, GROUP_SIZE):
        for i, byte in enumerate(data[group_start : group_start + GROUP_SIZE]):
            color = color_for_index(group_start + i)
            line.append(f"{byte:02X}", style=color)
            if i != GROUP_SIZE - 1:
                line.append(" ")
        if group_start + GROUP_SIZE < BYTES_PER_LINE:
            line.append(" │ ", style="dim")

    # Pad the hex column so the character column lines up on short lines.
    hex_columns = (BYTES_PER_LINE * 3 - 1) + 2  # two extra for the divider
    hex_width = len(data) * 3 - 1
    if hex_width < hex_columns:
        line.append(" " * (hex_columns - hex_width))

    line.append("  ", style="dim")

    # Right side: printable characters, same per-byte color.
    for i, byte in enumerate(data):
        color = color_for_index(i)
        line.append(printable_char(byte), style=color)

    return line


def hexdump(data: bytes) -> Text:
    """Build the full hex dump for the given bytes."""
    output = Text()
    for offset in range(0, len(data), BYTES_PER_LINE):
        chunk = data[offset : offset + BYTES_PER_LINE]
        output.append(format_line(offset, chunk))
        output.append("\n")
    return output


def main() -> None:
    """Read STDIN and print a colored hex dump."""
    console = Console()
    data = sys.stdin.buffer.read()
    if not data:
        console.print("No input received on STDIN.", style="yellow")
        return
    console.print(hexdump(data))


if __name__ == "__main__":
    main()
