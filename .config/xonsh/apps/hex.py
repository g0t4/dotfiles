"""A hex dump viewer that doesn't suck.

Reads bytes from STDIN and renders them hexdump-style: hex bytes on the left,
printable characters on the right. Each byte is colored by its position within
a group of 8 so the left hex column and right character column correspond
without having to count.

ANSI escape sequences (CSI, OSC, and simple ESC sequences) are recognized ahead
of time, grouped apart from the surrounding text, and annotated with a
plain-English explanation of what they do.
"""

from __future__ import annotations

import argparse
import base64
import sys
from dataclasses import dataclass

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

ESC = 0x1B
CSI_8BIT = 0x9B  # 8-bit CSI introducer
OSC_8BIT = 0x9D  # 8-bit OSC introducer

# Readable names for ASCII control characters, so they don't all collapse into
# a single placeholder and the char column actually tells you what each byte is.
CONTROL_NAMES: dict[int, str] = {
    0x00: "NUL",
    0x01: "SOH",
    0x02: "STX",
    0x03: "ETX",
    0x04: "EOT",
    0x05: "ENQ",
    0x06: "ACK",
    0x07: "BEL",
    0x08: "BS",
    0x09: "TAB",
    0x0A: "LF",
    0x0B: "VT",
    0x0C: "FF",
    0x0D: "CR",
    0x0E: "SO",
    0x0F: "SI",
    0x10: "DLE",
    0x11: "DC1",
    0x12: "DC2",
    0x13: "DC3",
    0x14: "DC4",
    0x15: "NAK",
    0x16: "SYN",
    0x17: "ETB",
    0x18: "CAN",
    0x19: "EM",
    0x1A: "SUB",
    0x1B: "ESC",
    0x1C: "FS",
    0x1D: "GS",
    0x1E: "RS",
    0x1F: "US",
    0x7F: "DEL",
}


@dataclass(frozen=True)
class Segment:
    """A chunk of the input: either plain text or a single ANSI escape."""

    kind: str  # "text" or "escape"
    data: bytes
    explanation: str = ""


# ---- ANSI parsing ----------------------------------------------------------


def parse_csi(data: bytes, idx: int) -> int | None:
    """Return the end index (exclusive) of a CSI sequence starting at idx, or None."""
    n = len(data)
    while idx < n and 0x30 <= data[idx] <= 0x3F:
        idx += 1
    while idx < n and 0x20 <= data[idx] <= 0x2F:
        idx += 1
    if idx < n and 0x40 <= data[idx] <= 0x7E:
        return idx + 1
    return None


def parse_osc(data: bytes, idx: int) -> int | None:
    """Return the end index (exclusive) of an OSC sequence starting at idx, or None."""
    n = len(data)
    while idx < n:
        b = data[idx]
        if b == 0x07:  # BEL terminates OSC
            return idx + 1
        if b == ESC and idx + 1 < n and data[idx + 1] == 0x5C:  # ST
            return idx + 2
        idx += 1
    return None


def parse_escape(data: bytes, start: int) -> int | None:
    """Return the end index (exclusive) of an escape sequence, or None."""
    b = data[start]
    if b == ESC:
        if start + 1 >= len(data):
            return None
        nxt = data[start + 1]
        if nxt == 0x5B:  # '['
            return parse_csi(data, start + 2)
        if nxt == 0x5D:  # ']'
            return parse_osc(data, start + 2)
        return start + 2  # simple ESC sequence: ESC + one byte
    if b == CSI_8BIT:
        return parse_csi(data, start + 1)
    if b == OSC_8BIT:
        return parse_osc(data, start + 1)
    return None


def parse_ansi(data: bytes) -> list[Segment]:
    """Split raw bytes into text and escape segments."""
    segments: list[Segment] = []
    n = len(data)
    i = 0
    text_start = 0
    while i < n:
        b = data[i]
        if b in (ESC, CSI_8BIT, OSC_8BIT):
            end = parse_escape(data, i)
            if end is not None:
                if text_start < i:
                    segments.append(Segment("text", data[text_start:i]))
                esc = data[i:end]
                segments.append(Segment("escape", esc, explain_escape(esc)))
                i = end
                text_start = i
                continue
        i += 1
    if text_start < n:
        segments.append(Segment("text", data[text_start:]))
    return segments


# ---- Escape decoding -------------------------------------------------------


def decode_csi(esc: bytes) -> tuple[str, str, str, str]:
    """Decode a CSI sequence into (private, params, intermediates, final)."""
    body = esc[2:] if esc.startswith(b"\x1b[") else esc[1:]
    if not body:
        return "", "", "", ""
    final = body[-1:]
    body = body[:-1]
    private = ""
    if body and 0x3C <= body[0] <= 0x3F:
        private = chr(body[0])
        body = body[1:]
    param_bytes = bytearray()
    inter_bytes = bytearray()
    for b in body:
        if 0x30 <= b <= 0x3F:
            param_bytes.append(b)
        elif 0x20 <= b <= 0x2F:
            inter_bytes.append(b)
    return private, param_bytes.decode(), inter_bytes.decode(), chr(final[0])


def extract_osc_body(esc: bytes) -> bytes:
    """Return the OSC payload, stripping the introducer and terminator."""
    body = esc[2:] if esc.startswith(b"\x1b]") else esc[1:]
    if body.endswith(b"\x07"):
        body = body[:-1]
    elif body.endswith(b"\x1b\\"):
        body = body[:-2]
    return body


def readable_csi(esc: bytes) -> str:
    """Return a human-readable form like ``ESC[?25l``."""
    private, params, inter, final = decode_csi(esc)
    return f"ESC[{private}{params}{inter}{final}"


def readable_osc(esc: bytes) -> str:
    """Return a human-readable form like ``OSC 7;file:///...``."""
    body = extract_osc_body(esc).decode("utf-8", errors="replace")
    return f"OSC {body}"


def parse_params(params_text: str) -> list[int | None]:
    """Split a CSI parameter string into ints; empty fields become None."""
    if not params_text:
        return []
    return [int(part) if part else None for part in params_text.split(";")]


# ---- Explanation maps ------------------------------------------------------


CSI_FINALS: dict[str, str] = {
    "@": "Insert Character (ICH)",
    "A": "Cursor Up (CUU)",
    "B": "Cursor Down (CUD)",
    "C": "Cursor Forward (CUF)",
    "D": "Cursor Back (CUB)",
    "E": "Cursor Next Line (CNL)",
    "F": "Cursor Previous Line (CPL)",
    "G": "Cursor Horizontal Absolute (CHA)",
    "H": "Cursor Position (CUP)",
    "I": "Cursor Forward Tabulation (CHT)",
    "J": "Erase in Display (ED)",
    "K": "Erase in Line (EL)",
    "L": "Insert Line (IL)",
    "M": "Delete Line (DL)",
    "P": "Delete Character (DCH)",
    "S": "Scroll Up (SU)",
    "T": "Scroll Down (SD)",
    "X": "Erase Character (ECH)",
    "Z": "Cursor Backward Tabulation (CBT)",
    "b": "Repeat Character (REP)",
    "c": "Device Attributes (DA)",
    "d": "Line Position Absolute (VPA)",
    "f": "Horizontal & Vertical Position (HVP)",
    "g": "Tab Clear (TBC)",
    "h": "Set Mode (SM)",
    "l": "Reset Mode (RM)",
    "m": "Select Graphic Rendition (SGR)",
    "n": "Device Status Report (DSR)",
    "q": "DECSCUSR: Set Cursor Style",
    "r": "Set Scrolling Region (DECSTBM)",
    "s": "Save Cursor Position (SCP)",
    "u": "Restore Cursor Position (RCP)",
    "t": "Window Manipulation",
}

CSI_PRIVATE_MODES: dict[int, str] = {
    1: "application cursor keys",
    3: "132-column mode",
    6: "origin mode",
    7: "auto-wrap",
    12: "cursor blink",
    25: "cursor visibility",
    47: "alternate screen buffer",
    1000: "mouse tracking",
    1002: "button-event mouse tracking",
    1003: "any-event mouse tracking",
    1004: "focus reporting",
    1006: "SGR mouse encoding",
    1049: "alternate screen buffer (save/restore)",
    2004: "bracketed paste",
}

FG_COLORS: tuple[str, ...] = (
    "black",
    "red",
    "green",
    "yellow",
    "blue",
    "magenta",
    "cyan",
    "white",
)
BG_COLORS: tuple[str, ...] = FG_COLORS

CURSOR_SHAPES: dict[int, str] = {
    0: "default (blinking block)",
    1: "blinking block",
    2: "steady block",
    3: "blinking underline",
    4: "steady underline",
    5: "blinking bar",
    6: "steady bar",
}

OSC_CODES: dict[str, str] = {
    "0": "Set window & icon title",
    "1": "Set icon name",
    "2": "Set window title",
    "3": "Set X property",
    "4": "Set color (palette)",
    "7": "Set working directory",
    "8": "Hyperlink (OSC 8)",
    "9": "Bell notification",
    "10": "Set foreground color",
    "11": "Set background color",
    "52": "Copy to clipboard (OSC 52)",
    "104": "Reset foreground color",
    "110": "Reset background color",
    "133": "Shell integration (OSC 133)",
    "1337": "iTerm2-specific (OSC 1337)",
}

OSC_133: dict[str, str] = {
    "A": "prompt start",
    "B": "prompt end",
    "C": "command start",
    "D": "command end",
    "E": "command finished",
    "F": "command output finished",
}

OSC_1337: dict[str, str] = {
    "SetUserVar": "set iTerm2 user variable",
    "SetMark": "set iTerm2 mark",
    "SetProfile": "switch iTerm2 profile",
    "SetBadge": "set iTerm2 badge",
    "RequestAttention": "request iTerm2 attention",
    "Copy": "copy to iTerm2 clipboard",
    "ShellIntegrationVersion": "iTerm2 shell integration version",
}

SIMPLE_ESCAPES: dict[str, str] = {
    "7": "save cursor position (DECSC)",
    "8": "restore cursor position (DECRC)",
    "c": "reset terminal (RIS)",
    "=": "keypad application mode (DECKPAM)",
    ">": "keypad numeric mode (DECKPNM)",
    "D": "index (IND)",
    "E": "next line (NEL)",
    "M": "reverse index (RI)",
}


# ---- Explanation builders --------------------------------------------------


def explain_private_modes(params_text: str, final: str) -> str:
    """Explain a DEC private-mode set/reset, e.g. ``?25l``."""
    action = "enabled" if final == "h" else "disabled"
    if not params_text:
        return f"private mode {action}"
    names = [
        CSI_PRIVATE_MODES.get(int(part), f"mode {part}")
        for part in params_text.split(";")
    ]
    return f"private mode {action}: " + ", ".join(names)


def describe_extended_color(
    params: list[int | None], i: int, kind: str
) -> tuple[str, int]:
    """Describe an extended SGR color (``38;5;n`` or ``38;2;r;g;b``)."""
    nxt = params[i + 1] if i + 1 < len(params) else None
    if nxt == 5 and i + 2 < len(params):
        return f"{kind} color {params[i + 2]}", i + 2
    if nxt == 2 and i + 4 < len(params):
        r, g, b = params[i + 2], params[i + 3], params[i + 4]
        return f"{kind} rgb({r},{g},{b})", i + 4
    return f"{kind} extended color", i


def explain_sgr(params_text: str) -> str:
    """Break an SGR parameter string into human-readable attributes."""
    params = parse_params(params_text)
    if not params:
        return "reset all attributes"
    descriptions: list[str] = []
    i = 0
    while i < len(params):
        p = params[i] if params[i] is not None else 0
        if p == 0:
            descriptions.append("reset")
        elif p == 1:
            descriptions.append("bold")
        elif p == 2:
            descriptions.append("dim")
        elif p == 3:
            descriptions.append("italic")
        elif p == 4:
            descriptions.append("underline")
        elif p == 5:
            descriptions.append("slow blink")
        elif p == 6:
            descriptions.append("fast blink")
        elif p == 7:
            descriptions.append("reverse video")
        elif p == 8:
            descriptions.append("conceal")
        elif p == 9:
            descriptions.append("strikethrough")
        elif p == 21:
            descriptions.append("double underline")
        elif p == 22:
            descriptions.append("normal intensity")
        elif p == 23:
            descriptions.append("not italic")
        elif p == 24:
            descriptions.append("not underline")
        elif p == 27:
            descriptions.append("not reverse")
        elif 30 <= p <= 37:
            descriptions.append(f"fg {FG_COLORS[p - 30]}")
        elif p == 38:
            desc, i = describe_extended_color(params, i, "fg")
            descriptions.append(desc)
        elif p == 39:
            descriptions.append("default fg")
        elif 40 <= p <= 47:
            descriptions.append(f"bg {BG_COLORS[p - 40]}")
        elif p == 48:
            desc, i = describe_extended_color(params, i, "bg")
            descriptions.append(desc)
        elif p == 49:
            descriptions.append("default bg")
        elif 90 <= p <= 97:
            descriptions.append(f"bright fg {FG_COLORS[p - 90]}")
        elif 100 <= p <= 107:
            descriptions.append(f"bright bg {BG_COLORS[p - 100]}")
        else:
            descriptions.append(f"code {p}")
        i += 1
    return ", ".join(descriptions)


def osc_detail(code: str, rest: str) -> str:
    """Return a detail string for an OSC payload, or empty if unknown."""
    if code == "7":
        return rest
    if code == "8":
        parts = rest.split(";", 1)
        if len(parts) == 2:
            params, uri = parts
            if params:
                return f"link to {uri or '(empty)'!r} (params: {params})"
            return f"link to {uri or '(empty)'!r}"
        return ""
    if code == "133":
        return OSC_133.get(rest.split(";")[0], "")
    if code == "1337":
        return OSC_1337.get(rest.split("=")[0], "")
    if code == "52":
        parts = rest.split(";", 1)
        selection = parts[0]
        b64data = parts[1] if len(parts) > 1 else ""
        selection_name = {
            "c": "clipboard",
            "p": "primary",
            "s": "secondary",
        }.get(selection, f"selection {selection!r}")
        try:
            decoded = base64.b64decode(b64data)
        except Exception:
            decoded = b""
        if decoded:
            preview = decoded[:40].decode("utf-8", errors="replace")
            if len(decoded) > 40:
                preview += "…"
            return f"copy {selection_name} ({len(decoded)} bytes): {preview!r}"
        return f"copy {selection_name} ({len(b64data)} b64 chars)"
    return ""


def describe_cursor_move(final: str, params_text: str) -> str:
    """Describe a cursor movement or position CSI sequence."""
    params = parse_params(params_text)
    if final in ("H", "f"):
        row = params[0] if params and params[0] is not None else 1
        col = params[1] if len(params) > 1 and params[1] is not None else 1
        return f"move to row {row}, column {col}"
    n = params[0] if params and params[0] is not None else 1
    moves = {
        "A": f"up {n} line(s)",
        "B": f"down {n} line(s)",
        "C": f"forward {n} column(s)",
        "D": f"back {n} column(s)",
        "E": f"next {n} line(s)",
        "F": f"previous {n} line(s)",
        "G": f"column {n}",
        "d": f"line {n}",
    }
    return moves[final]


def explain_csi(esc: bytes) -> str:
    """Explain a CSI sequence, breaking its args out into words."""
    private, params_text, inter, final = decode_csi(esc)
    name = CSI_FINALS.get(final, f"CSI (final byte {final!r})")
    readable = readable_csi(esc)
    detail = ""
    if final in ("h", "l"):
        if private == "?":
            detail = explain_private_modes(params_text, final)
        else:
            detail = f"mode {params_text or '0'} {'enabled' if final == 'h' else 'disabled'}"
    elif final == "m":
        detail = explain_sgr(params_text)
    elif final == "q" and " " in inter:
        param = parse_params(params_text)
        style = param[0] if param and param[0] is not None else 0
        detail = CURSOR_SHAPES.get(style, f"cursor style {style}")
    elif final == "n" and params_text == "6":
        detail = "report cursor position"
    elif final in ("A", "B", "C", "D", "E", "F", "G", "H", "f", "d"):
        detail = describe_cursor_move(final, params_text)
    else:
        detail = describe_params(params_text)
    if detail:
        return f"{readable} — {name}: {detail}"
    return f"{readable} — {name}"


def describe_params(params_text: str) -> str:
    """Describe CSI arguments generically."""
    if not params_text:
        return ""
    parts = params_text.split(";")
    return "args: " + ", ".join(p if p else "<default>" for p in parts)


def explain_osc(esc: bytes) -> str:
    """Explain an OSC sequence."""
    text = extract_osc_body(esc).decode("utf-8", errors="replace")
    parts = text.split(";", 1)
    code = parts[0]
    rest = parts[1] if len(parts) > 1 else ""
    name = OSC_CODES.get(code, f"OSC {code}")
    detail = osc_detail(code, rest)
    readable = readable_osc(esc)
    if detail:
        return f"{readable} — {name}: {detail}"
    return f"{readable} — {name}"


def explain_simple_esc(esc: bytes) -> str:
    """Explain a simple ESC + one byte sequence."""
    final = chr(esc[-1])
    name = SIMPLE_ESCAPES.get(final, "unknown ESC sequence")
    return f"ESC{final} — {name}"


def explain_escape(esc: bytes) -> str:
    """Produce a human-readable explanation for any recognized escape."""
    if esc.startswith(b"\x1b[") or esc.startswith(bytes([CSI_8BIT])):
        return explain_csi(esc)
    if esc.startswith(b"\x1b]") or esc.startswith(bytes([OSC_8BIT])):
        return explain_osc(esc)
    return explain_simple_esc(esc)


# ---- Rendering -------------------------------------------------------------


def printable_char(byte: int) -> str:
    """Return a readable representation of a byte for the char column."""
    if 32 <= byte < 127:
        return chr(byte)
    return CONTROL_NAMES.get(byte, "·")


def utf8_seq_len(byte: int) -> int | None:
    """Return the length of a UTF-8 sequence starting with this byte, or None."""
    if byte < 0x80:
        return 1
    if 0xC2 <= byte <= 0xDF:
        return 2
    if 0xE0 <= byte <= 0xEF:
        return 3
    if 0xF0 <= byte <= 0xF4:
        return 4
    return None


def char_tokens(data: bytes) -> list[tuple[str, int]]:
    """Decode a line's bytes into (display_text, first_byte_index) tokens.

    Valid UTF-8 sequences are shown as their actual character; control bytes
    and invalid sequences fall back to the single-byte placeholder.
    """
    tokens: list[tuple[str, int]] = []
    n = len(data)
    i = 0
    while i < n:
        b = data[i]
        seq_len = utf8_seq_len(b)
        if seq_len and seq_len > 1 and i + seq_len <= n:
            try:
                char = data[i : i + seq_len].decode("utf-8")
                tokens.append((char, i))
                i += seq_len
                continue
            except UnicodeDecodeError:
                pass
        tokens.append((printable_char(b), i))
        i += 1
    return tokens


def color_for_index(index: int) -> str:
    """Return the color for a byte at a 0-based index within its group."""
    return BYTE_COLORS[index % GROUP_SIZE]


def format_line(
    offset: int, data: bytes, annotation: str = "", use_color: bool = True
) -> Text:
    """Render a single line of the hex dump with per-byte color coding."""
    dim = "dim" if use_color else ""
    line = Text()
    line.append(f"{offset:08X}  ", style=dim)

    # Left side: hex bytes grouped in 8s with a divider.
    for group_start in range(0, BYTES_PER_LINE, GROUP_SIZE):
        for i, byte in enumerate(data[group_start : group_start + GROUP_SIZE]):
            color = color_for_index(group_start + i)
            line.append(f"{byte:02X}", style=color if use_color else "")
            if i != GROUP_SIZE - 1:
                line.append(" ")
        if group_start + GROUP_SIZE < BYTES_PER_LINE:
            line.append(" │ ", style=dim)

    # Pad the hex column so the character column lines up on short lines.
    hex_columns = (BYTES_PER_LINE * 3 - 1) + 2  # two extra for the divider
    hex_width = len(data) * 3 - 1
    if hex_width < hex_columns:
        line.append(" " * (hex_columns - hex_width))

    line.append("  ", style=dim)

    # Right side: decoded characters, same per-byte color, with a gap where the
    # groups split so the separation is visible even without color.
    for text, idx in char_tokens(data):
        color = color_for_index(idx)
        line.append(text, style=color if use_color else "")
        if idx == GROUP_SIZE - 1:
            line.append(" ")
    if annotation:
        line.append("   ")
        line.append(annotation, style="italic" if use_color else "")

    return line


def hexdump(data: bytes, annotation: str = "", use_color: bool = True) -> Text:
    """Build the full hex dump for the given bytes."""
    output = Text()
    for offset in range(0, len(data), BYTES_PER_LINE):
        chunk = data[offset : offset + BYTES_PER_LINE]
        ann = annotation if offset == 0 else ""
        output.append(format_line(offset, chunk, ann, use_color))
        output.append("\n")
    return output


def render_escape(segment: Segment, use_color: bool = True) -> Text:
    """Render a single escape segment with a label and explanation."""
    text = Text()
    text.append("── ", style="dim" if use_color else "")
    text.append("ANSI ESCAPE", style="bold yellow" if use_color else "")
    text.append(" ──", style="dim" if use_color else "")
    text.append("\n")
    text.append(
        hexdump(segment.data, annotation=segment.explanation, use_color=use_color)
    )
    return text


def render_segments(segments: list[Segment], use_color: bool = True) -> Text:
    """Render all segments, separating each with a blank line."""
    output = Text()
    for i, segment in enumerate(segments):
        if i:
            output.append("\n")
        if segment.kind == "escape":
            output.append(render_escape(segment, use_color))
        elif segment.data:
            output.append(hexdump(segment.data, use_color=use_color))
    return output


def main() -> None:
    """Read STDIN and print a colored hex dump."""
    parser = argparse.ArgumentParser(description="Colorized hex dump with ANSI explanations")
    parser.add_argument(
        "--no-color",
        action="store_true",
        help="disable colors and styling (plain, agent-friendly output)",
    )
    args = parser.parse_args()
    use_color = not args.no_color
    console = Console(color_system="standard" if use_color else None)
    data = sys.stdin.buffer.read()
    if not data:
        console.print("No input received on STDIN.", style="yellow" if use_color else None)
        return
    console.print(render_segments(parse_ansi(data), use_color))


if __name__ == "__main__":
    main()
