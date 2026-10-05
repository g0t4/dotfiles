"""Pure helpers for Vim/nvim-surround style operations on a single-line buffer.

Kept free of prompt_toolkit state so the pairing/wrapping logic can be unit
tested directly. The keybindings in ``rc.d/keybindings.xsh`` are thin wrappers
over these functions.
"""

from __future__ import annotations

# Opening -> closing delimiter map. Symmetric delimiters map to themselves.
_OPEN_TO_CLOSE = {
    "(": ")",
    "[": "]",
    "{": "}",
    "<": ">",
    '"': '"',
    "'": "'",
    "`": "`",
}


def normalize_pair(delim: str) -> tuple[str, str]:
    """Return the ``(left, right)`` delimiters for a user-supplied surround char.

    Both the opening char (``(``) and the closing char (``)``) are accepted so
    that ``ds)`` and ``ds(`` behave identically. Unknown chars are treated as a
    symmetric pair.
    """
    if delim in _OPEN_TO_CLOSE:
        return (delim, _OPEN_TO_CLOSE[delim])
    for left, right in _OPEN_TO_CLOSE.items():
        if right == delim:
            return (left, right)
    return (delim, delim)


def find_surround(text: str, pos: int, delim: str) -> tuple[int, int] | None:
    """Find the innermost matching pair enclosing ``pos``.

    Returns ``(left_index, right_index)`` where ``left < pos <= right``, or
    ``None`` when the cursor is not inside a matching pair. Openers are scanned
    from nearest to furthest, so nested pairs resolve to the innermost one the
    cursor actually sits inside.
    """
    if not text:
        return None
    left, right = normalize_pair(delim)

    # Gather opener indices from nearest to furthest before the cursor.
    openers = []
    index = text.rfind(left, 0, pos)
    while index != -1:
        openers.append(index)
        if index == 0:
            break
        index = text.rfind(left, 0, index)

    for opener in openers:
        closer = _matching_close(text, opener, left, right)
        if closer is not None and closer >= pos:
            return (opener, closer)
    return None


def _matching_close(text: str, opener: int, left: str, right: str) -> int | None:
    """Return the index of the closer that balances ``opener``, or ``None``."""
    if left == right:
        # Symmetric delimiter (e.g. quotes): the pair is the next occurrence.
        closer = text.find(left, opener + 1)
        return closer if closer != -1 else None

    depth = 0
    for index in range(opener, len(text)):
        char = text[index]
        if char == left:
            depth += 1
        elif char == right:
            depth -= 1
            if depth == 0:
                return index
    return None


def delete_surround(text: str, pos: int, delim: str) -> tuple[str, int, bool]:
    """Remove the surrounding pair. Returns ``(new_text, new_pos, changed)``."""
    pair = find_surround(text, pos, delim)
    if pair is None:
        return text, pos, False
    left_index, right_index = pair
    new_text = text[:left_index] + text[left_index + 1 : right_index] + text[right_index + 1 :]
    # Removing the left delimiter (which sits before the cursor) shifts the
    # cursor one place to the left.
    new_pos = max(left_index, pos - 1)
    return new_text, new_pos, True


def change_surround(
    text: str, pos: int, old_delim: str, new_delim: str
) -> tuple[str, int, bool]:
    """Swap the enclosing pair. Returns ``(new_text, new_pos, changed)``."""
    pair = find_surround(text, pos, old_delim)
    if pair is None:
        return text, pos, False
    left_index, right_index = pair
    new_left, new_right = normalize_pair(new_delim)
    new_text = (
        text[:left_index]
        + new_left
        + text[left_index + 1 : right_index]
        + new_right
        + text[right_index + 1 :]
    )
    new_pos = pos - 1 + len(new_left)
    return new_text, new_pos, True


def wrap_region(text: str, start: int, end: int, delim: str) -> str:
    """Wrap ``text[start:end]`` with the normalized pair."""
    left, right = normalize_pair(delim)
    return text[:start] + left + text[start:end] + right + text[end:]


def _is_small_word_char(ch: str) -> bool:
    return ch.isalnum() or ch == "_"


def _is_big_word_char(ch: str) -> bool:
    return not ch.isspace()


def _word_span(text: str, pos: int, is_char) -> tuple[int, int] | None:
    """Return ``(start, end)`` of the word at/after ``pos``, or ``None``."""
    if not text:
        return None
    length = len(text)

    start = None
    for index in range(pos, length):
        if is_char(text[index]):
            start = index
            break
    if start is None:
        for index in range(pos - 1, -1, -1):
            if is_char(text[index]):
                start = index
                break
    if start is None:
        return None

    end = start
    while end < length and is_char(text[end]):
        end += 1
    while start > 0 and is_char(text[start - 1]):
        start -= 1
    return (start, end)


def wrap_word(text: str, pos: int, delim: str, *, big: bool = False) -> tuple[str, int, bool]:
    """Wrap the word at/after the cursor. Returns ``(new_text, new_pos, changed)``."""
    is_char = _is_big_word_char if big else _is_small_word_char
    span = _word_span(text, pos, is_char)
    if span is None:
        return text, pos, False
    start, end = span
    new_text = wrap_region(text, start, end, delim)
    # Keep the cursor on the same character it was on (shifted by the inserted
    # opening delimiter). When the cursor was outside the word, land just after
    # the opening delimiter.
    new_pos = pos + 1 if start <= pos < end else start + 1
    return new_text, new_pos, True


def wrap_to_end(text: str, pos: int, delim: str) -> tuple[str, int, bool]:
    """Wrap everything from the cursor to the end of the buffer."""
    left, right = normalize_pair(delim)
    new_text = text[:pos] + left + text[pos:] + right
    return new_text, pos + 1, True
