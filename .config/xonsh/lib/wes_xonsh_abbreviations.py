"""Xonsh parser and Prompt Toolkit adapters for ``wes_abbreviations``."""

from __future__ import annotations

from dataclasses import replace
import re
from typing import Any, Iterable

from wes_abbreviations import (
    AbbreviationContext,
    AbbreviationRegistry,
    AbbreviationResult,
    abbreviation_replacement_text,
    completion_match_key,
)


_ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=.*", re.DOTALL)
MIN_ANYWHERE_COMPLETION_PREFIX_LENGTH = 1


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


def abbreviation_completion_candidates(
    registry: AbbreviationRegistry,
    context: AbbreviationContext,
    *,
    minimum_anywhere_prefix_length=MIN_ANYWHERE_COMPLETION_PREFIX_LENGTH,
) -> list[tuple[str, str]]:
    """Return applicable literal triggers in completion-score order."""
    candidates = []
    for abbreviation in registry.abbreviations:
        if abbreviation.internal or not isinstance(abbreviation.trigger, str):
            continue
        if (
            abbreviation.position == "anywhere"
            and not context.is_command_position
            and len(context.token) < minimum_anywhere_prefix_length
        ):
            continue
        key = abbreviation.completion_key(context)
        if key is not None:
            candidates.append(
                (
                    key,
                    abbreviation.trigger,
                    abbreviation_replacement_text(abbreviation),
                )
            )
    return [
        (trigger, expansion)
        for _, trigger, expansion in sorted(candidates, key=lambda row: row[0])
    ]


def install_abbreviation_completion_order():
    """Restore fuzzy abbreviation order after Xonsh sorts merged providers.

    Only swap abbreviation slots within the prefix/non-prefix groups. Other
    providers retain their order and positions, and all prefixes stay first.
    """
    from functools import wraps
    from xonsh.completer import Completer

    original = Completer.complete_from_context
    if getattr(original, "_wes_abbreviation_order", False):
        return

    @wraps(original)
    def complete_from_context(self, completion_context, old_completer_args=None):
        completions, prefix_len = original(self, completion_context, old_completer_args)
        if completion_context is None or completion_context.command is None:
            return completions, prefix_len
        query = completion_context.command.prefix
        ordered = list(completions)
        for prefix_group in (True, False):
            indices = [
                index
                for index, item in enumerate(ordered)
                if getattr(item, "provider", None) == "abbreviation"
                and str(item).lower().startswith(query.lower()) == prefix_group
            ]
            ranked = sorted(
                (ordered[index] for index in indices),
                key=lambda item: completion_match_key(str(item), query),
            )
            for index, item in zip(indices, ranked):
                ordered[index] = item
        return tuple(ordered), prefix_len

    complete_from_context._wes_abbreviation_order = True
    Completer.complete_from_context = complete_from_context


def abbreviation_picker_rows(
    registry: AbbreviationRegistry, context: AbbreviationContext
) -> list[str]:
    """Format applicable abbreviation triggers for a tab-delimited FZF view."""
    unfiltered = replace(context, token="")
    return [
        f"{trigger}\t{' '.join(expansion.split()).replace(chr(9), ' ')}"
        for trigger, expansion in abbreviation_completion_candidates(
            registry,
            unfiltered,
            minimum_anywhere_prefix_length=0,
        )
    ]


def apply_abbreviation_selection(
    buffer: str,
    token_start: int,
    token_end: int,
    selected: str | None,
) -> tuple[str, int]:
    """Replace the current token with an FZF-selected abbreviation trigger."""
    if not selected:
        return buffer, token_end
    updated = buffer[:token_start] + selected + buffer[token_end:]
    return updated, token_start + len(selected)


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

    def expand(self, buffer) -> AbbreviationResult | None:
        context = self.context(buffer)
        if context is None:
            return None
        expansion = self.registry.expand(context)
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
    result = expander.expand(buffer)
    if result is None or result.cursor is None:
        buffer.insert_text(" ")
