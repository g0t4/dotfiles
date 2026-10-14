#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pygments>=2.19,<3", "rich>=13.9,<15"]
# ///
"""Use our theme for Python/Lua/Markdown views; delegate other requests to bat."""

import os
from pathlib import Path
import shutil
import sys

from pygments import highlight
from pygments.formatters import TerminalTrueColorFormatter
from pygments.lexers import get_lexer_by_name

from highlight import ROOT, load_style, style_for_lexer

LANGUAGES = {"py": "python", "python": "python", "python3": "python", "lua": "lua", "md": "markdown", "markdown": "markdown"}


def parse(args):
    """Return supported options, or None without reading input for fallback."""
    language, color, numbers, grayscale = None, "auto", False, False
    files = []
    iterator = iter(args)
    for arg in iterator:
        if arg == "--":
            files.extend(iterator)
            break
        if arg in ("-l", "-pl", "-ppl", "--language", "--color", "--paging", "--style", "--theme"):
            value = next(iterator, None)
            if value is None:
                return None
            option = "-l" if arg in ("-pl", "-ppl") else arg
        elif any(arg.startswith(option + "=") for option in ("--language", "--color", "--paging", "--style", "--theme")):
            option, value = arg.split("=", 1)
        elif arg.startswith("-l") and len(arg) > 2:
            option, value = "-l", arg[2:]
        elif arg in ("-p", "-pp", "--plain"):
            numbers = False
            continue
        elif arg in ("-n", "--number"):
            numbers = True
            continue
        elif arg.startswith("-") and arg != "-":
            return None
        else:
            files.append(arg)
            continue
        if option in ("-l", "--language"):
            language = LANGUAGES.get(value.lower())
            if language is None:
                return None
        elif option == "--color":
            if value not in ("auto", "always", "never"):
                return None
            color = value
        elif option == "--paging":
            if value != "never":
                return None
        elif option == "--style":
            if value not in ("plain", "numbers"):
                return None
            numbers = value == "numbers"
        elif option == "--theme":
            if value not in ("wes-gray", "wes-dark"):
                return None
            grayscale = value == "wes-gray"
    files = files or ["-"]
    languages = [language or {".py": "python", ".pyi": "python", ".lua": "lua", ".md": "markdown", ".markdown": "markdown"}.get(Path(file).suffix.lower()) for file in files]
    if not all(languages):
        return None
    return files, languages, color, numbers, grayscale


def stock(args):
    executable = shutil.which("bat") or shutil.which("batcat")
    if executable:
        os.execv(executable, [executable, *args])
    print("bat: stock bat/batcat is required for this language or these options", file=sys.stderr)
    return 127


def main(args=None):
    args = sys.argv[1:] if args is None else args
    options = parse(args)
    if options is None:
        return stock(args)
    files, languages, color, numbers, grayscale = options
    colored = color == "always" or (color == "auto" and sys.stdout.isatty() and "NO_COLOR" not in os.environ)
    try:
        colors, style = load_style(ROOT / "palette.json", grayscale=grayscale)
    except (OSError, ValueError):
        # Fall back before consuming any stdin if the theme is unavailable.
        return stock(args)
    status = 0
    for file, language in zip(files, languages):
        try:
            code = sys.stdin.read() if file == "-" else Path(file).read_text()
            if colored:
                lexer = get_lexer_by_name(language)
                sys.stdout.write(highlight(code, lexer, TerminalTrueColorFormatter(style=style_for_lexer(lexer, colors, style), linenos=numbers)))
            elif numbers:
                sys.stdout.writelines(f"{index:6}  {line}" for index, line in enumerate(code.splitlines(keepends=True), 1))
            else:
                sys.stdout.write(code)
        except (OSError, UnicodeError) as error:
            print(f"bat: {file}: {error}", file=sys.stderr)
            status = 1
    return status


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        os._exit(0)
