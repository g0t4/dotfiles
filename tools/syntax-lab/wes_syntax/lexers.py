"""Small source-view corrections around Xonsh's native Pygments lexer."""

import os

from pygments.lexer import inherit
from pygments.token import Whitespace
from xonsh.built_ins import XSH
from xonsh.environ import LsColors
from xonsh.pyghooks import XonshLexer


class SourceXonshLexer(XonshLexer):
    def __init__(self, **options):
        super().__init__(**options)
        # XonshLexer mocks XSH.env with {} outside a shell, but its file
        # argument callback still requires a typed LS_COLORS value.
        if isinstance(XSH.env, dict) and "LS_COLORS" not in XSH.env:
            XSH.env["LS_COLORS"] = LsColors.fromstring(os.environ.get("LS_COLORS", ""))

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
