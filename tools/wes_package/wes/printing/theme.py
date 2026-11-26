"""Build a Rich theme from the wes_package palette.

The palette lives in the ``wes_syntax`` package
(``tools/wes_package/wes_syntax/palette.json``) and is the single source of
truth for Wes's colors -- the same one ``highlight`` uses. This module maps
it onto Rich's theme names, so anything rendered through a themed console
(``print(some_dict)``, JSON, Markdown, tracebacks) picks up the palette.
"""

from rich.style import Style, StyleType
from rich.theme import Theme

from wes_syntax import load_style

#: Palette roles exposed verbatim as theme names, usable in markup:
#: print("[keyword]def[/keyword] [function]greet[/function]([string]name[/string])")
PALETTE_ROLES = (
    "background",
    "text",
    "comment",
    "keyword",
    "function",
    "type",
    "string",
    "number",
    "builtin",
    "decorator",
    "operator",
    "punctuation",
    "escape",
    "error",
)


def _rich_styles(colors: dict[str, str]) -> dict[str, StyleType]:
    """Map Rich's internal style names onto palette roles.

    Rich looks these up when rendering reprs (what ``print(some_dict)``
    uses), JSON, Markdown, log lines, and tracebacks.
    """
    return {
        # repr / pretty-printing
        "repr.str": colors["string"],
        "repr.number": Style(color=colors["number"], bold=True),
        "repr.number_complex": Style(color=colors["number"], bold=True),
        "repr.bool_true": Style(color=colors["builtin"], italic=True),
        "repr.bool_false": Style(color=colors["builtin"], italic=True),
        "repr.none": Style(color=colors["keyword"], italic=True),
        "repr.ellipsis": colors["punctuation"],
        "repr.uuid": colors["number"],
        "repr.call": Style(color=colors["function"], bold=True),
        "repr.path": colors["string"],
        "repr.filename": colors["function"],
        "repr.url": Style(color=colors["function"], underline=True),
        "repr.tag_start": Style(color=colors["punctuation"], bold=True),
        "repr.tag_name": Style(color=colors["type"], bold=True),
        "repr.tag_contents": colors["text"],
        "repr.tag_end": Style(color=colors["punctuation"], bold=True),
        "repr.attrib_name": colors["type"],
        "repr.attrib_equal": Style(color=colors["operator"], bold=True),
        "repr.attrib_value": colors["string"],
        "repr.brace": Style(color=colors["punctuation"], bold=True),
        "repr.indent": colors["text"],
        "repr.error": colors["error"],
        # rich.json
        "json.str": colors["string"],
        "json.number": Style(color=colors["number"], bold=True),
        "json.bool_true": Style(color=colors["builtin"], italic=True),
        "json.bool_false": Style(color=colors["builtin"], italic=True),
        "json.null": Style(color=colors["keyword"], italic=True),
        "json.key": Style(color=colors["function"], bold=True),
        "json.brace": Style(color=colors["punctuation"], bold=True),
        # rich.markdown
        "markdown.h1": Style(color=colors["keyword"], bold=True, underline=True),
        "markdown.h2": Style(color=colors["function"], underline=True),
        "markdown.h3": Style(color=colors["function"], bold=True),
        "markdown.h4": Style(color=colors["function"], italic=True),
        "markdown.strong": Style(color=colors["type"], bold=True),
        "markdown.em": Style(color=colors["builtin"], italic=True),
        "markdown.code": Style(color=colors["number"], bold=True),
        "markdown.code_block": colors["number"],
        "markdown.block_quote": colors["comment"],
        "markdown.list": colors["function"],
        "markdown.item.number": colors["number"],
        "markdown.link": Style(color=colors["function"], underline=True),
        "markdown.link_url": colors["function"],
        "markdown.table.border": colors["punctuation"],
        "markdown.table.header": colors["function"],
        # rich.logging
        "logging.keyword": Style(color=colors["keyword"], bold=True),
        "logging.level.debug": colors["builtin"],
        "logging.level.info": colors["function"],
        "logging.level.warning": colors["number"],
        "logging.level.error": colors["error"],
        "logging.level.critical": Style(color=colors["error"], bold=True),
        # rich.traceback
        "traceback.error": colors["error"],
        "traceback.border": colors["error"],
        "traceback.title": Style(color=colors["error"], bold=True),
        "traceback.exc_type": Style(color=colors["error"], bold=True),
        "traceback.note": colors["string"],
        # iso8601 timestamps
        "iso8601.date": colors["number"],
        "iso8601.time": colors["number"],
        "iso8601.timezone": colors["comment"],
    }


def wes_theme(palette=None, *, grayscale: bool = False) -> Theme:
    """Build a Rich theme from the wes_package palette.

    Args:
        palette: Path to a palette JSON; defaults to wes_syntax's palette.
        grayscale: Strip chroma while preserving luminance, like
            ``highlight --grayscale``.

    Palette edits apply on every call, the same way they do for
    ``highlight``.
    """
    colors, _ = load_style(palette, grayscale=grayscale)
    styles = {role: colors[role] for role in PALETTE_ROLES}
    styles.update(_rich_styles(colors))
    return Theme(styles)
