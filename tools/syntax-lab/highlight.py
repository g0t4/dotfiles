#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pygments>=2.19,<3", "rich>=13.9,<15", "pillow>=11,<13", "colorspacious>=1.1.2,<2", "xonsh>=0.24,<0.25"]
# ///
"""Editable Pygments theme; preview code without running it."""

import argparse
import os
from pathlib import Path
import sys

from pygments import highlight, lex
from pygments.formatters import TerminalTrueColorFormatter
from rich.console import Console
from rich.syntax import PygmentsSyntaxTheme, Syntax

from wes_syntax import grayscale_color, load_style, make_style, style_for_lexer, source_lexer

ROOT = Path(__file__).resolve().parent


def contrast(foreground, background):
    def luminance(color):
        channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
        linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
        return sum(c * weight for c, weight in zip(linear, (0.2126, 0.7152, 0.0722)))
    light, dark = sorted((luminance(foreground), luminance(background)))
    return (dark + 0.05) / (light + 0.05)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", nargs="?", help="source file, or - for stdin; defaults to Python demo")
    parser.add_argument("--language", "-l", help="Pygments lexer, e.g. python or lua")
    parser.add_argument("--palette", type=Path, default=ROOT / "palette.json")
    parser.add_argument("--grayscale", action="store_true", help="remove chroma, preserving relative luminance")
    parser.add_argument("--swatches", action="store_true", help="show palette and contrast against configured background")
    parser.add_argument("--tokens", action="store_true", help="inspect lexer token assignments instead of coloring")
    parser.add_argument("--renderer", choices=("pygments", "rich"), default="pygments")
    parser.add_argument("--line-numbers", action="store_true")
    parser.add_argument("--force-color", action="store_true", help="preserve ANSI when piping to less -R")
    from explorer import add_arguments, explore
    add_arguments(parser)
    args = parser.parse_args()
    try:
        colors, style = load_style(args.palette, grayscale=args.grayscale)
        colored = args.force_color or (sys.stdout.isatty() and "NO_COLOR" not in os.environ)
        console = Console(color_system="truecolor" if colored else None, force_terminal=colored, no_color=not colored, highlight=False)
        if args.swatches:
            console.print(f"Palette: {args.palette}\nBackground reference: {colors['background']} (terminal background is preserved)")
            for role, color in colors.items():
                if role != "background":
                    console.print(f"{role:12} {color}  {contrast(color, colors['background']):4.1f}:1  AaBb 0123 # sample", style=color)
            return
        example = {"lua": "sample.lua", "md": "sample.md", "markdown": "sample.md", "xonsh": "sample.xsh", "xsh": "sample.xsh"}.get(args.language, "sample.py")
        path = Path(args.file) if args.file and args.file != "-" else ROOT / "examples" / example
        code = sys.stdin.read() if args.file == "-" else path.read_text()
        lexer = source_lexer(args.language, filename=path)
        if args.sweep or args.blur is not None or args.vision or args.hue_shuffle or args.background or args.output or args.export_dir:
            explore(args, code, lexer, colors, console)
            return
        style = style_for_lexer(lexer, colors, style)
        if args.tokens:
            for token, value in lex(code, lexer):
                if value.strip():
                    print(f"{str(token):32} {value!r}")
        elif not colored:
            sys.stdout.write(code)
        elif args.renderer == "rich":
            console.print(Syntax(code, lexer, theme=PygmentsSyntaxTheme(style), background_color="default", line_numbers=args.line_numbers, word_wrap=False, padding=0))
        else:
            sys.stdout.write(highlight(code, lexer, TerminalTrueColorFormatter(style=style, linenos=args.line_numbers)))
    except (OSError, ValueError) as exc:
        parser.error(str(exc))


if __name__ == "__main__":
    main()
