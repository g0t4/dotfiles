#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pygments>=2.19,<3", "rich>=13.9,<15"]
# ///
"""Editable Pygments theme; preview code without running it."""

import argparse
import json
import os
from pathlib import Path
import re
import sys

from pygments import highlight, lex
from pygments.formatters import TerminalTrueColorFormatter
from pygments.lexers import get_lexer_by_name, get_lexer_for_filename
from pygments.style import Style
from pygments.token import Comment, Error, Keyword, Name, Number, Operator, Punctuation, String, Token
from rich.console import Console
from rich.syntax import PygmentsSyntaxTheme, Syntax

ROOT = Path(__file__).resolve().parent


def load_style(path):
    colors = json.loads(path.read_text())
    required = json.loads((ROOT / "palette.json").read_text()).keys()
    for key in required:
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", colors.get(key, "")):
            raise ValueError(f"{key}: expected a #RRGGBB color in {path}")

    class WesDark(Style):
        background_color = colors["background"]
        styles = {
            Token: colors["text"],
            Comment: colors["comment"],
            Comment.Preproc: colors["decorator"],
            Keyword: colors["keyword"],
            Keyword.Type: colors["type"],
            Name: colors["text"],
            Name.Function: colors["function"],
            Name.Class: colors["type"],
            Name.Builtin: colors["builtin"],
            Name.Builtin.Pseudo: colors["text"],
            Name.Decorator: colors["decorator"],
            Name.Exception: colors["type"],
            Number: colors["number"],
            String: colors["string"],
            String.Doc: colors["comment"],
            String.Escape: colors["escape"],
            String.Interpol: colors["escape"],
            Operator: colors["operator"],
            Operator.Word: colors["keyword"],
            Punctuation: colors["punctuation"],
            Error: colors["error"],
            Token.Generic: colors["text"],
        }

    return colors, WesDark


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
    parser.add_argument("--swatches", action="store_true", help="show palette and contrast against configured background")
    parser.add_argument("--tokens", action="store_true", help="inspect lexer token assignments instead of coloring")
    parser.add_argument("--renderer", choices=("pygments", "rich"), default="pygments")
    parser.add_argument("--line-numbers", action="store_true")
    parser.add_argument("--force-color", action="store_true", help="preserve ANSI when piping to less -R")
    args = parser.parse_args()
    try:
        colors, style = load_style(args.palette)
        colored = args.force_color or (sys.stdout.isatty() and "NO_COLOR" not in os.environ)
        console = Console(color_system="truecolor" if colored else None, force_terminal=colored, no_color=not colored, highlight=False)
        if args.swatches:
            console.print(f"Palette: {args.palette}\nBackground reference: {colors['background']} (terminal background is preserved)")
            for role, color in colors.items():
                if role != "background":
                    console.print(f"{role:12} {color}  {contrast(color, colors['background']):4.1f}:1  AaBb 0123 # sample", style=color)
            return
        path = Path(args.file) if args.file and args.file != "-" else ROOT / "examples" / ("sample.lua" if args.language == "lua" else "sample.py")
        code = sys.stdin.read() if args.file == "-" else path.read_text()
        lexer = get_lexer_by_name(args.language) if args.language else get_lexer_for_filename(str(path))
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
