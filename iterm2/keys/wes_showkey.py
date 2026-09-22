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


def utf8_continuations(byte: int) -> int:
    """Return how many continuation bytes follow the given UTF-8 lead byte."""
    if byte < 0x80:
        return 0
    if 0xC0 <= byte <= 0xDF:
        return 1
    if 0xE0 <= byte <= 0xEF:
        return 2
    if 0xF0 <= byte <= 0xF7:
        return 3
    return -1


def visualize_char(codepoint: int) -> str:
    """Render a decoded character the way ``showkey`` does."""
    if codepoint <= 0x20:
        if 0 < codepoint < 27:
            return f"<CTL-{chr(codepoint + 0x40)}={LOWCHARS[codepoint]}>"
        return f"<{LOWCHARS[codepoint]}>"
    if codepoint == 0x7F:
        return "<DEL>"
    if codepoint > 0x7F:
        if codepoint <= 0xFFFF:
            return f"\\u{codepoint:04x}"
        return f"\\U{codepoint:08x}"
    return chr(codepoint)


def visualize_byte(byte: int) -> str:
    """Render a raw byte (fallback for invalid UTF-8, e.g. old Alt keys)."""
    buf: list[str] = []
    opened = False

    if byte & ALT:
        opened = True
        byte &= ~ALT
        buf.append("<ALT-")

    if byte <= 0x20:
        if not opened:
            opened = True
            buf.append("<")
        if 0 < byte < 27:
            buf.append(f"CTL-{chr(byte + 0x40)}=")
        buf.append(LOWCHARS[byte])
    elif byte == 0x7F:
        if not opened:
            opened = True
            buf.append("<")
        buf.append("DEL")
    else:
        buf.append(chr(byte))

    if opened:
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
                first = os.read(fd, 1)
                if not first:
                    break
                seq = first
                for _ in range(utf8_continuations(first[0])):
                    chunk = os.read(fd, 1)
                    if not chunk:
                        break
                    seq += chunk

                try:
                    text = seq.decode("utf-8")
                except UnicodeDecodeError:
                    text = None

                if text is not None and len(text) == 1:
                    sys.stdout.write(visualize_char(ord(text)))
                else:
                    for byte in seq:
                        sys.stdout.write(visualize_byte(byte))
                sys.stdout.write("\n")
                sys.stdout.flush()
        except KeyboardInterrupt:
            pass
    finally:
        termios.tcsetattr(fd, termios.TCSANOW, cooked)

    print("\nBye...")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
