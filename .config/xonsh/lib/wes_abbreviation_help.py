"""Fish-style abbreviation inspection using Xonsh's ``?`` spelling."""

from __future__ import annotations

from dataclasses import replace
import inspect
import re
import textwrap

from rich.console import Console, Group
from rich.panel import Panel
from rich.syntax import Syntax
from rich.text import Text

from wes_abbreviations import (
    Abbreviation,
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


def register_abbreviation_help(registry: AbbreviationRegistry):
    def resolve(context, _match):
        target, full = _target_context(context)
        matches = registry.applicable(target)
        if not matches:
            return None
        index = registry.abbreviations.index(matches[0])
        detail = " --full" if full else ""
        return AbbreviationResult(
            f"_abbr_help{detail} {index}", replace_buffer=True
        )

    return abbr(
        registry,
        _HELP_TRIGGER,
        resolve,
        position="anywhere",
        submit_only=True,
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
    if len(values) != 1 or not values[0].isdigit():
        raise ValueError("usage: _abbr_help [--full] INDEX")
    index = int(values[0])
    try:
        abbreviation = registry.abbreviations[index]
    except IndexError as error:
        raise ValueError(f"unknown abbreviation index: {index}") from error
    render_abbreviation_help(abbreviation, full=full)
