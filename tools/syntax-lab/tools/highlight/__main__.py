"""Preview source with Wes's syntax palette without running it."""

# PYTHON_ARGCOMPLETE_OK

from __future__ import annotations

import argparse
from collections.abc import Iterable, Sequence
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LANGUAGE_COMPLETIONS = ("bash", "lua", "markdown", "python", "xonsh", "yaml")


def complete_languages(**kwargs: object) -> Iterable[str]:
    """Suggest the curated palette languages without restricting the parser."""
    prefix = str(kwargs.get("prefix") or "")
    xonsh_completer = kwargs.get("completer")
    if not prefix and xonsh_completer is not None:
        prefix = str(xonsh_completer.command.prefix)
    yield from (
        language for language in LANGUAGE_COMPLETIONS if language.startswith(prefix)
    )


def add_explorer_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--sweep",
        choices=("background", "background-tint", "hue-shuffle", "vision", "blur"),
    )
    parser.add_argument(
        "--steps",
        type=int,
        default=7,
        help="variants for background/hue/blur sweeps (includes original for hue)",
    )
    parser.add_argument(
        "--columns",
        type=int,
        help="grid columns; default fits sample width to terminal columns",
    )
    parser.add_argument(
        "--sample-lines",
        type=int,
        default=0,
        help="excerpt length for sweeps; 0 uses entire file",
    )
    parser.add_argument(
        "--blur",
        type=float,
        nargs="?",
        const=2.0,
        help="Gaussian radius in image pixels; saves PNG (default 2)",
    )
    parser.add_argument(
        "--vision",
        choices=("protan", "deutan", "tritan"),
        help="protan: red, deutan: green, tritan: blue/yellow discrimination simulation",
    )
    parser.add_argument(
        "--severity",
        type=float,
        default=100,
        help="Machado simulation severity, 0..100",
    )
    parser.add_argument("--hue-shuffle", action="store_true")
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--background", help="one-off #RRGGBB background")
    parser.add_argument(
        "--bg-span",
        type=float,
        default=0.21,
        help="total OKLab lightness span, centered on current background",
    )
    parser.add_argument("--output", type=Path, help="PNG output; implies image view")
    parser.add_argument("--font-size", type=int, default=16)
    parser.add_argument("--font", type=Path, help="monospace TTF/TTC for image views")
    parser.add_argument(
        "--export-dir",
        type=Path,
        help="save numbered palette JSON variants for later testing",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="highlight", description=__doc__)
    parser.add_argument(
        "file", nargs="?", help="source file, or - for stdin; defaults to Python demo"
    )
    language = parser.add_argument(
        "--language", "-l", help="Pygments lexer, e.g. python, lua, or yaml"
    )
    language.completer = complete_languages  # type: ignore[attr-defined]
    parser.add_argument("--palette", type=Path, default=ROOT / "palette.json")
    parser.add_argument(
        "--grayscale",
        action="store_true",
        help="remove chroma, preserving relative luminance",
    )
    parser.add_argument(
        "--swatches",
        action="store_true",
        help="show palette and contrast against configured background",
    )
    parser.add_argument(
        "--tokens",
        action="store_true",
        help="inspect lexer token assignments instead of coloring",
    )
    parser.add_argument("--renderer", choices=("pygments", "rich"), default="pygments")
    parser.add_argument("--pad-tables", action="store_true", help="align Markdown pipe tables in the output")
    parser.add_argument("--width", type=int, help="maximum padded table width in terminal columns")
    parser.add_argument("--line-numbers", action="store_true")
    parser.add_argument(
        "--force-color",
        action="store_true",
        help="preserve ANSI when piping to less -R",
    )
    add_explorer_arguments(parser)
    return parser


def enable_argcomplete(parser: argparse.ArgumentParser) -> None:
    try:
        import argcomplete
    except ImportError:
        return
    argcomplete.autocomplete(parser)


def contrast(foreground: str, background: str) -> float:
    def luminance(color: str) -> float:
        channels = [int(color[index : index + 2], 16) / 255 for index in (1, 3, 5)]
        linear = [
            channel / 12.92
            if channel <= 0.04045
            else ((channel + 0.055) / 1.055) ** 2.4
            for channel in channels
        ]
        return sum(
            channel * weight
            for channel, weight in zip(linear, (0.2126, 0.7152, 0.0722), strict=True)
        )

    light, dark = sorted((luminance(foreground), luminance(background)))
    return (dark + 0.05) / (light + 0.05)


def run(args: argparse.Namespace) -> int:
    import os
    import sys

    from pygments import highlight as pygments_highlight
    from pygments import lex
    from pygments.formatters import TerminalTrueColorFormatter
    from rich.console import Console
    from rich.syntax import PygmentsSyntaxTheme, Syntax

    from wes_syntax import load_style, source_lexer, style_for_lexer

    colors, style = load_style(args.palette, grayscale=args.grayscale)
    colored = args.force_color or (sys.stdout.isatty() and "NO_COLOR" not in os.environ)
    console = Console(
        color_system="truecolor" if colored else None,
        force_terminal=colored,
        no_color=not colored,
        highlight=False,
    )
    if args.swatches:
        console.print(
            f"Palette: {args.palette}\n"
            f"Background reference: {colors['background']} "
            "(terminal background is preserved)"
        )
        for role, color in colors.items():
            if role != "background":
                ratio = contrast(color, colors["background"])
                console.print(
                    f"{role:12} {color}  {ratio:4.1f}:1  AaBb 0123 # sample",
                    style=color,
                )
        return 0

    examples = {
        "lua": "sample.lua",
        "md": "sample.md",
        "markdown": "sample.md",
        "xonsh": "sample.xsh",
        "xsh": "sample.xsh",
        "yaml": "sample.yaml",
        "yml": "sample.yaml",
    }
    example = examples.get(args.language, "sample.py")
    path = (
        Path(args.file)
        if args.file and args.file != "-"
        else ROOT / "examples" / example
    )
    code = sys.stdin.read() if args.file == "-" else path.read_text()
    lexer = source_lexer(args.language, filename=path)
    if args.pad_tables and lexer.name == "Markdown":
        from wes_syntax.markdown_tables import pad_tables

        max_width = args.width
        if max_width is None and sys.stdout.isatty():
            max_width = console.width
        code = pad_tables(code, max_width=max_width)
    if (
        args.sweep
        or args.blur is not None
        or args.vision
        or args.hue_shuffle
        or args.background
        or args.output
        or args.export_dir
    ):
        from explorer import explore

        explore(args, code, lexer, colors, console)
        return 0

    style = style_for_lexer(lexer, colors, style)
    if args.tokens:
        for token, value in lex(code, lexer):
            if value.strip():
                print(f"{str(token):32} {value!r}")
    elif not colored:
        sys.stdout.write(code)
    elif args.renderer == "rich":
        console.print(
            Syntax(
                code,
                lexer,
                theme=PygmentsSyntaxTheme(style),
                background_color="default",
                line_numbers=args.line_numbers,
                word_wrap=False,
                padding=0,
            )
        )
    else:
        sys.stdout.write(
            pygments_highlight(
                code,
                lexer,
                TerminalTrueColorFormatter(style=style, linenos=args.line_numbers),
            )
        )
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    enable_argcomplete(parser)
    args = parser.parse_args(argv)
    try:
        return run(args)
    except (OSError, ValueError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        raise SystemExit(0) from None
