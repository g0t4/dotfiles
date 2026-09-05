"""Fish-style abbreviation inspection using Xonsh's ``?`` spelling."""

from __future__ import annotations

from dataclasses import replace
import inspect
import re
import shlex
import textwrap

from rich.console import Console, Group
from rich.panel import Panel
from rich.syntax import Syntax
from rich.text import Text

import wes_abbreviations
from wes_abbreviations import (
    Abbreviation,
    AbbreviationContext,
    AbbreviationRegistry,
    AbbreviationResult,
    abbr,
)


_HELP_TRIGGER = re.compile(r".+?\?{1,2}")


def _target_context(context):
    full = context.token.endswith("??")
    suffix_length = 2 if full else 1
    token = context.token[:-suffix_length]
    command_path = context.command_path
    if context.command_position and command_path:
        command_path = (token, *command_path[1:])
    return replace(context, token=token, command_path=command_path), full


def register_abbreviation_help():
    def resolve(context, _match):
        target, full = _target_context(context)
        registry = wes_abbreviations.XONSH_ABBREVIATIONS
        matches = registry.applicable(target)
        if not matches:
            return None
        detail = " --full" if full else ""
        words = (
            [target.token]
            if target.command_position
            else [*target.command_path, target.token]
        )
        invocation = " ".join(shlex.quote(word) for word in words)
        return AbbreviationResult(
            f"_abbr_help{detail} {invocation}", replace_buffer=True
        )

    return abbr(
        _HELP_TRIGGER,
        resolve,
        position="anywhere",
        internal=True,
    )


def _trigger_text(abbreviation: Abbreviation) -> str:
    if isinstance(abbreviation.trigger, str):
        return abbreviation.trigger
    return f"/{abbreviation.trigger.pattern}/"


def _replacement_text(abbreviation: Abbreviation) -> str:
    replacement = abbreviation.replacement
    if isinstance(replacement, str):
        return replacement
    return getattr(replacement, "__name__", type(replacement).__name__)


def render_abbreviation_help(
    abbreviation: Abbreviation, *, full=False, console: Console | None = None
):
    console = console or Console()
    lines = Text()
    lines.append("Expansion: ", style="bold cyan")
    lines.append(_replacement_text(abbreviation))
    if full:
        lines.append("\nPosition:  ", style="bold cyan")
        lines.append(abbreviation.position)
        if abbreviation.commands:
            lines.append("\nCommands:  ", style="bold cyan")
            lines.append(" ".join(abbreviation.commands))
        if abbreviation.cursor_marker:
            lines.append("\nCursor:    ", style="bold cyan")
            lines.append(repr(abbreviation.cursor_marker))
        if abbreviation.source_file:
            lines.append("\nSource:    ", style="bold cyan")
            lines.append(
                f"{abbreviation.source_file}:{abbreviation.source_line or 1}"
            )

    renderables = [lines]
    if full and callable(abbreviation.replacement):
        try:
            source = textwrap.dedent(inspect.getsource(abbreviation.replacement))
        except (OSError, TypeError):
            source = None
        if source:
            renderables.append(Syntax(source.rstrip(), "python", theme="ansi_dark"))

    console.print(
        Panel(
            Group(*renderables),
            title=f"abbreviation {_trigger_text(abbreviation)}",
            border_style="cyan",
        )
    )


def abbreviation_help_alias(registry: AbbreviationRegistry, args, **_):
    full = False
    values = list(args)
    if values and values[0] == "--full":
        full = True
        values.pop(0)
    if not values:
        raise ValueError("usage: _abbr_help [--full] [COMMAND ...] ABBREVIATION")
    token = values[-1]
    command_position = len(values) == 1
    command_path = (token,) if command_position else tuple(values[:-1])
    context = AbbreviationContext(
        buffer=" ".join(values),
        cursor=len(" ".join(values)),
        token_start=sum(len(value) + 1 for value in values[:-1]),
        token_end=len(" ".join(values)),
        token=token,
        command_path=command_path,
        command_position=command_position,
    )
    matches = registry.applicable(context)
    if not matches:
        raise ValueError(f"no abbreviation matches: {' '.join(values)}")
    abbreviation = matches[0]
    render_abbreviation_help(abbreviation, full=full)
