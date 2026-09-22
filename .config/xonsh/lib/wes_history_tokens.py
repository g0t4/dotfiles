"""Fish-style, reversible token navigation through shell history."""

from __future__ import annotations

import shlex
from dataclasses import dataclass
from weakref import WeakKeyDictionary

from prompt_toolkit.buffer import Buffer


_SHELL_OPERATORS = {"|", "||", "&", "&&", ";", "(", ")", "<", ">", ">>"}


def _history_tokens(buffer: Buffer) -> list[str]:
    tokens: list[str] = []
    for line in reversed(buffer.history.get_strings()):
        try:
            words = shlex.split(line, posix=False)
        except ValueError:
            words = line.split()
        tokens.extend(word for word in reversed(words) if word not in _SHELL_OPERATORS)
    return tokens


@dataclass
class _TokenSearch:
    before: str
    after: str
    original: str
    tokens: list[str]
    index: int = -1

    def matches(self, buffer: Buffer) -> bool:
        inserted = self.original if self.index < 0 else self.tokens[self.index]
        return (
            buffer.text == self.before + inserted + self.after
            and buffer.cursor_position == len(self.before) + len(inserted)
        )

    def render(self, buffer: Buffer) -> None:
        inserted = self.original if self.index < 0 else self.tokens[self.index]
        buffer.text = self.before + inserted + self.after
        buffer.cursor_position = len(self.before) + len(inserted)


_SEARCHES: WeakKeyDictionary[Buffer, _TokenSearch] = WeakKeyDictionary()


def _new_search(buffer: Buffer) -> _TokenSearch:
    document = buffer.document
    original = document.get_word_before_cursor(WORD=True)
    before = document.text_before_cursor[: -len(original)] if original else document.text_before_cursor
    return _TokenSearch(
        before=before,
        after=document.text_after_cursor,
        original=original,
        tokens=_history_tokens(buffer),
    )


def history_token_search(buffer: Buffer, *, forward: bool) -> None:
    """Replace the current token with the next older/newer history token."""

    search = _SEARCHES.get(buffer)
    if not isinstance(search, _TokenSearch) or not search.matches(buffer):
        if forward:
            return
        search = _new_search(buffer)
        _SEARCHES[buffer] = search

    if forward:
        search.index = max(-1, search.index - 1)
    elif search.tokens:
        search.index = min(len(search.tokens) - 1, search.index + 1)
    search.render(buffer)
