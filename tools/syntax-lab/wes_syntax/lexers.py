"""Source-view corrections around Pygments' shell lexers."""

import os
import re

from pygments.lexer import inherit
from pygments.lexers.shell import BashLexer
from pygments.token import Comment, Keyword, Name, Number, Operator, Punctuation, Text, Whitespace
from xonsh.built_ins import XSH
from xonsh.environ import LsColors
from xonsh.pyghooks import XonshLexer


class SourceBashLexer(BashLexer):
    """Color command words without changing Bash's argument tokenization."""

    def get_tokens_unprocessed(self, text):
        command_start = True
        assignment_value = False
        for index, token, value in super().get_tokens_unprocessed(text):
            if token in Whitespace:
                if "\n" in value or assignment_value:
                    command_start = True
                    assignment_value = False
            elif token in Comment:
                if "\n" in value:
                    command_start = True
            elif assignment_value:
                pass
            elif token in Keyword:
                if value in ("if", "then", "do", "else", "elif", "while", "until", "$("):
                    command_start = True
                else:
                    command_start = False
            elif token in (Punctuation, Operator):
                if value in (";", "&", "|", "&&", "||", "{"):
                    command_start = True
                elif value not in ("(", "=", "<"):
                    command_start = False
            elif (
                command_start
                and token in Name.Variable
                and re.fullmatch(r"[A-Za-z_]\w*", value)
                and re.match(r"\+?=", text[index + len(value):])
            ):
                assignment_value = True
            elif command_start and token in Number and text[index + len(value):].startswith(("<", ">")):
                pass  # redirection descriptor, e.g. 2>/dev/null
            elif command_start and token is Text and value.startswith(("<", ">")):
                pass  # redirection before a command
            elif command_start and token is Text and value and not value.startswith("-"):
                token = Name.Function
                command_start = False
            elif command_start:
                command_start = False
            yield index, token, value


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
