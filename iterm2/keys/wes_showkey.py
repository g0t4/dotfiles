"""A Python clone of ESR's ``showkey`` keystroke visualizer.

Reads raw keystrokes from the terminal and prints each byte in a printable
form, e.g. ``<CTL-C=ETX>``, ``<DEL>``, ``<ALT-a>``.

This is a starting point so it can later be augmented with custom mappings.
"""

from __future__ import annotations

import os
import sys
import termios

ALT = 0x80

# Names for the ASCII control characters (index 0..32).
LOWCHARS = [
    "NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL", "BS", "HT", "LF",
    "VT", "FF", "CR", "SO", "SI", "DLE", "DC1", "DC2", "DC3", "DC4", "NAK",
    "SYN", "ETB", "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS", "US", "SP",
]


def visualize(byte: int) -> str:
    """Render a single byte the way ``showkey`` does."""
    buf: list[str] = []
    cookie = False

    if byte & ALT:
        cookie = True
        byte &= ~ALT
        buf.append("<ALT-")

    if byte <= 0x20:
        cookie = True
        if not buf or buf[0] != "<":
            buf.insert(0, "<")
        if 0 < byte < 27:
            buf.append(f"CTL-{chr(byte + 0x40)}=")
        buf.append(LOWCHARS[byte])
    elif byte == 0x7F:
        cookie = True
        if not buf or buf[0] != "<":
            buf.insert(0, "<")
        buf.append("DEL")
    else:
        buf.append(chr(byte))

    if cookie:
        buf.append(">")

    return "".join(buf)


def main() -> int:
    if not sys.stdin.isatty():
        print("stdin is not a tty", file=sys.stderr)
        return 1

    fd = sys.stdin.fileno()
    cooked = termios.tcgetattr(fd)
    raw = list(cooked)
    # Turn off echo and canonical (line-buffered) mode, but keep signal keys.
    raw[3] &= ~(termios.ICANON | termios.ECHO)
    termios.tcsetattr(fd, termios.TCSANOW, raw)

    try:
        print("Type any key to see the sequence it sends.")
        print("Terminate with your shell interrupt character.")
        try:
            while True:
                byte = os.read(fd, 1)
                if not byte:
                    break
                sys.stdout.write(visualize(byte[0]))
                sys.stdout.flush()
        except KeyboardInterrupt:
            pass
    finally:
        termios.tcsetattr(fd, termios.TCSANOW, cooked)

    print("\nBye...")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
