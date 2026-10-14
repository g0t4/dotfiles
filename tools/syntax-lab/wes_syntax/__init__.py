"""Personal Pygments palette and Rich source rendering, shared with syntax-lab."""

import json
from pathlib import Path
import re

from pygments.style import Style
from pygments.token import Comment, Error, Generic, Keyword, Name, Number, Operator, Punctuation, String, Token

DEFAULT_PALETTE = Path(__file__).with_name("palette.json")


def source_lexer(language=None, *, filename=None):
    if language in ("apply-patch", "apply_patch"):
        from .patch import ApplyPatchLexer
        return ApplyPatchLexer()
    from pygments.lexers import get_lexer_by_name, get_lexer_for_filename
    lexer = get_lexer_by_name(language) if language is not None else get_lexer_for_filename(str(filename))
    if "xonsh" in lexer.aliases:
        from .lexers import SourceXonshLexer
        return SourceXonshLexer()
    return lexer

def grayscale_color(color):
    """Remove chroma while preserving linear sRGB relative luminance."""
    channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    luminance = sum(c * weight for c, weight in zip(linear, (0.2126, 0.7152, 0.0722)))
    gray = 12.92 * luminance if luminance <= 0.0031308 else 1.055 * luminance ** (1 / 2.4) - 0.055
    channel = round(gray * 255)
    return f"#{channel:02x}{channel:02x}{channel:02x}"


def load_style(path=None, *, grayscale=False):
    path = Path(path) if path is not None else DEFAULT_PALETTE
    colors = json.loads(path.read_text())
    required = json.loads(DEFAULT_PALETTE.read_text()).keys()
    for key in required:
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", colors.get(key, "")):
            raise ValueError(f"{key}: expected a #RRGGBB color in {path}")
    if grayscale:
        colors = {role: grayscale_color(color) for role, color in colors.items()}

    return colors, make_style(colors)


def make_style(colors):

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
            Generic.Inserted: colors["string"],
            Generic.Deleted: colors["error"],
            Generic.Heading: colors["function"],
            Generic.Subheading: colors["builtin"],
        }

    return WesDark


def style_for_lexer(lexer, colors, base_style):
    if lexer.name != "Markdown":
        return base_style

    class WesMarkdown(base_style):
        styles = {
            **base_style.styles,
            Generic.Heading: colors["keyword"],
            Generic.Subheading: colors["keyword"],
            Generic.Strong: colors["type"],
            Generic.Emph: colors["builtin"],
            Generic.Deleted: colors["comment"],
            String.Backtick: colors["builtin"],
            Name.Tag: colors["function"],
            Name.Attribute: colors["comment"],
            Name.Label: colors["function"],
            Name.Entity: colors["function"],
        }

    return WesMarkdown



def syntax(source, language="python", *, palette=None, grayscale=False, **options):
    """Return a Rich Syntax renderable using the current palette.

    Palette edits apply at each call. Options are forwarded to Rich Syntax.
    """
    from rich.syntax import PygmentsSyntaxTheme, Syntax

    colors, base = load_style(palette, grayscale=grayscale)
    lexer = source_lexer(language) if isinstance(language, str) else language
    style = style_for_lexer(lexer, colors, base)
    options.setdefault("background_color", "default")
    return Syntax(source, lexer, theme=PygmentsSyntaxTheme(style), **options)
