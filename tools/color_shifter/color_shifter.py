#!/usr/bin/env python3
"""
Interactive color shifter for a list of colors.

Add or remove entries in COLORS to change which colors you can shift.

Usage:
    color_shifter.py [HEX ...]

Each positional argument is a hex color (3 or 6 digits, '#' optional)
appended to the list, e.g. `color_shifter.py 61AFEF`.

Controls:
    Up        +step lightness
    Down      -step lightness
    Right     +step saturation
    Left      -step saturation
    Tab / t   cycle to next color
    1-9       select the Nth color
    s         toggle step (10% <-> 5%)
    [         step -1   (min 1)
    ]         step +1   (max 100)
    r         reset selected color to its default
    q         quit (prints final hex values)
"""

import sys
import termios
import tty
import colorsys
import shutil
import re


# (name, default hex) pairs; add or remove entries to taste.
COLORS = [
    ("IN_HUE", "#acadcf"),
    ("OUT_HUE", "#cfacb4"),
]
STEP = 10

HEX_RE = re.compile(r"^#?([0-9a-f]{3}|[0-9a-f]{6})$", re.IGNORECASE)


def parse_cli_colors(argv):
    """Turn CLI hex args like `61AFEF` into (name, default) pairs."""
    cli_colors = []
    for index, arg in enumerate(argv, start=1):
        match = HEX_RE.match(arg)
        if match is None:
            print("Invalid hex color: {!r} (expected e.g. 61AFEF)".format(arg))
            sys.exit(1)
        digits = match.group(1)
        if len(digits) == 3:
            digits = "".join(ch * 2 for ch in digits)
        cli_colors.append(("ARG_{}".format(index), "#" + digits.lower()))
    return cli_colors


def hex_to_hsl(hex_code):
    hex_code = hex_code.lstrip("#")
    r, g, b = (int(hex_code[i : i + 2], 16) / 255.0 for i in (0, 2, 4))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return h * 360, s * 100, l * 100


def hsl_to_rgb(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h / 360.0, l / 100.0, s / 100.0)
    return int(round(r * 255)), int(round(g * 255)), int(round(b * 255))


def hsl_to_hex(h, s, l):
    r, g, b = hsl_to_rgb(h, s, l)
    return "#{:02x}{:02x}{:02x}".format(r, g, b)


def clamp(v):
    return max(0, min(100, int(round(v))))


class Color:
    def __init__(self, name, default):
        self.name = name
        self.h, self.s, self.l = hex_to_hsl(default)
        self.default = default

    def hex(self):
        return hsl_to_hex(self.h, self.s, self.l)

    def rgb(self):
        return hsl_to_rgb(self.h, self.s, self.l)

    def reset(self):
        self.h, self.s, self.l = hex_to_hsl(self.default)


reset = "\x1b[0m"
bold = "\x1b[1m"
clear = "\x1b[2J\x1b[H"

def fg(r, g, b):
    return "\x1b[38;2;{};{};{}m".format(r, g, b)


def term_cols():
    return max(10, shutil.get_terminal_size((80, 24)).columns)


def trunc(s, cols):
    """Truncate a plain string to `cols` so it never wraps."""
    return s[:cols]


def emit(s=""):
    """Write a line, always returning the cursor to column 0 (raw-mode safe)."""
    sys.stdout.write(s + "\r\n")
    sys.stdout.flush()


def read_key():
    """Blocking read of a single key press. Returns a name or a character."""
    ch = sys.stdin.read(1)
    if ch == "\x1b":
        seq = sys.stdin.read(2)
        return {"[A": "up", "[B": "down", "[C": "right", "[D": "left"}.get(seq)
    return ch


def draw(colors, active, step):
    print(clear, end="")
    cols = term_cols()
    title = trunc("Color Shifter  —  {} colors  (foreground color only)".format(len(colors)).strip(), cols - 1)
    emit(bold + " " + title + reset)
    help_ = trunc(" ↑/↓ lightness ±{}%   ←/→ saturation ±{}%   Tab/t cycle   s 5/10   [ ] +/-1 step:{}   r reset   q quit".format(step, step, step), cols - 1)
    emit(help_)
    emit()

    for index, color in enumerate(colors):
        marker = ">" if index == active else " "
        r, g, b = color.rgb()
        # Foreground color only; strip leading/trailing whitespace from the label.
        plain = "{} {}  {}  H{} S{} L{}".format(
            marker, color.name, color.hex(), int(color.h), clamp(color.s), clamp(color.l)
        ).strip() + reset
        label = fg(r, g, b) + trunc(plain, cols - 1)
        emit(label)
    emit()


def main():
    argv = sys.argv[1:]
    if argv:
        all_colors = parse_cli_colors(argv) + COLORS
    else:
        all_colors = COLORS
    if not all_colors:
        print("No colors defined in COLORS.")
        return

    colors = [Color(name, default) for name, default in all_colors]
    active = 0
    step = STEP

    if not sys.stdin.isatty():
        print("Run this in an interactive terminal for arrow-key controls.")
        return

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        draw(colors, active, step)
        while True:
            key = read_key()
            selected = colors[active]
            change = False
            if key == "up":
                selected.l = clamp(selected.l + step)
                change = True
            elif key == "down":
                selected.l = clamp(selected.l - step)
                change = True
            elif key == "right":
                selected.s = clamp(selected.s + step)
                change = True
            elif key == "left":
                selected.s = clamp(selected.s - step)
                change = True
            elif key in ("\t", "t", "T"):
                active = (active + 1) % len(colors)
                change = True
            elif key in ("1", "2", "3", "4", "5", "6", "7", "8", "9"):
                index = int(key) - 1
                if index < len(colors):
                    active = index
                    change = True
            elif key in ("s", "S"):
                step = 5 if step == 10 else 10
                change = True
            elif key == "[":
                step = max(1, step - 1)
                change = True
            elif key == "]":
                step = min(100, step + 1)
                change = True
            elif key in ("r", "R"):
                selected.reset()
                change = True
            elif key in ("q", "Q", "\x03"):
                break
            if change:
                draw(colors, active, step)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

    emit(reset)
    for color in colors:
        emit("{} = {}".format(color.name, color.hex()))


if __name__ == "__main__":
    main()
