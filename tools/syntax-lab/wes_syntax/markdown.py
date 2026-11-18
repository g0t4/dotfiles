"""Route Pygments Markdown fences through the shared source lexer."""

from pygments.lexers.markup import MarkdownLexer
from pygments.token import String, Text, Whitespace
from pygments.util import ClassNotFound

from . import source_lexer


def _codeblock(lexer, match):
    yield match.start("initial"), String.Backtick, match["initial"]
    yield match.start("lang"), String.Backtick, match["lang"]
    if match["afterlang"] is not None:
        yield match.start("whitespace"), Whitespace, match["whitespace"]
        yield match.start("extra"), Text, match["extra"]
    yield match.start("newline"), Whitespace, match["newline"]

    embedded = None
    if lexer.handlecodeblocks:
        try:
            embedded = source_lexer(match["lang"])
        except ClassNotFound:
            pass

    offset = match.start("code")
    if embedded is None:
        yield offset, String, match["code"]
    else:
        for index, token, value in embedded.get_tokens_unprocessed(match["code"]):
            yield offset + index, token, value

    yield match.start("terminator"), String.Backtick, match["terminator"]


class SourceMarkdownLexer(MarkdownLexer):
    # Keep the upstream fence pattern and rule order, swapping only the callback.
    tokens = {
        "root": [
            (rule[0], _codeblock, *rule[2:])
            if isinstance(rule, tuple) and rule[1] is MarkdownLexer._handle_codeblock
            else rule
            for rule in MarkdownLexer.tokens["root"]
        ],
    }
