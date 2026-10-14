"""Small source-view corrections around Xonsh's native Pygments lexer."""

from pygments.lexer import inherit
from pygments.token import Whitespace
from xonsh.pyghooks import XonshLexer


class SourceXonshLexer(XonshLexer):
    # Native import-state whitespace includes newlines, allowing the next
    # statement to be consumed as module names. Keep explicit continuations,
    # but finish an import at an ordinary newline (including trailing spaces).
    tokens = {
        state: [
            (r"\\\r?\n", Whitespace),
            (r"\r?\n", Whitespace, "#pop"),
            (r"[^\S\r\n]+", Whitespace),
            inherit,
        ]
        for state in ("import", "fromimport")
    }
