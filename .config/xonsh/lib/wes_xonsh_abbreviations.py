"""Xonsh parser and Prompt Toolkit adapters for ``wes_abbreviations``."""

from __future__ import annotations

import re
from typing import Any, Iterable

from wes_abbreviations import (
    AbbreviationContext,
    AbbreviationRegistry,
    AbbreviationResult,
)


_ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=.*", re.DOTALL)


def command_path_from_args(args: Iterable[Any]) -> tuple[str, ...]:
    """Normalize completed Xonsh command args into an executable/path tuple."""
    values = [arg.value for arg in args if not getattr(arg, "is_io_redir", False)]
    while values and _ASSIGNMENT.fullmatch(values[0]):
        values.pop(0)
    if values and values[0] == "env":
        values.pop(0)
        while values:
            value = values[0]
            if value in ("-u", "--unset", "-C", "--chdir", "-S", "--split-string"):
                values.pop(0)
                if values:
                    values.pop(0)
            elif value.startswith(("--unset=", "--chdir=", "--split-string=")):
                values.pop(0)
            elif value.startswith("-") or _ASSIGNMENT.fullmatch(value):
                values.pop(0)
            else:
                break
    return tuple(values)


def context_from_completion(buffer_text: str, cursor: int, command: Any):
    token = command.prefix + command.suffix
    token_start = cursor - len(command.prefix)
    return AbbreviationContext(
        buffer=buffer_text,
        cursor=cursor,
        token_start=token_start,
        token_end=cursor + len(command.suffix),
        token=token,
        command_path=command_path_from_args(command.args),
        command_position=command.arg_index == 0,
        quoted=bool(command.opening_quote or command.closing_quote),
    )


class XonshAbbreviationExpander:
    def __init__(self, registry: AbbreviationRegistry):
        from xonsh.parsers.completion_context import CompletionContextParser

        self.registry = registry
        self.parser = CompletionContextParser()

    def context(self, buffer, cursor=None):
        document = buffer.document
        cursor = document.cursor_position if cursor is None else cursor
        completion = self.parser.parse(
            document.text, cursor, ctx={}
        )
        if completion is None or completion.command is None:
            return None
        return context_from_completion(
            document.text, cursor, completion.command
        )

    def expand(self, buffer, *, include_submit_only=True) -> AbbreviationResult | None:
        context = self.context(buffer)
        if context is None:
            return None
        expansion = self.registry.expand(
            context, include_submit_only=include_submit_only
        )
        # A trailing space still leaves ``name??`` as the sole submitted
        # command, just as it does for Xonsh's native help syntax. The active
        # completion token is empty in that state, so retry at the last
        # non-whitespace character, accepting only a submit-only resolver.
        if expansion is None and include_submit_only:
            trimmed_cursor = len(buffer.text.rstrip())
            if trimmed_cursor < buffer.cursor_position:
                prior_context = self.context(buffer, cursor=trimmed_cursor)
                if prior_context is not None:
                    candidate = self.registry.expand(prior_context)
                    if candidate is not None and candidate[1].submit_only:
                        context = prior_context
                        expansion = candidate
        if expansion is None:
            return None
        result, _abbreviation = expansion
        if result.replace_buffer:
            buffer.text = result.text
            buffer.cursor_position = len(result.text)
        else:
            buffer.cursor_position = context.token_end
            buffer.delete_before_cursor(count=context.token_end - context.token_start)
            buffer.insert_text(result.text)
        if result.cursor is not None:
            buffer.cursor_position = (
                result.cursor
                if result.replace_buffer
                else context.token_start + result.cursor
            )
        return result


def expand_abbreviation_on_space(buffer, expander) -> None:
    """Expand and insert the triggering space unless it would move the cursor."""
    result = expander.expand(buffer, include_submit_only=False)
    if result is None or result.cursor is None:
        buffer.insert_text(" ")
