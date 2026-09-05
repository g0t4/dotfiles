"""Matching core for Fish-style Xonsh abbreviations.

This module deliberately has no Xonsh or Prompt Toolkit dependency.  Xonsh's
completion parser supplies :class:`AbbreviationContext` at runtime; keeping the
matcher independent makes its edge cases cheap to exercise with pytest.
"""

from __future__ import annotations

from dataclasses import dataclass
import inspect
from re import Pattern
from typing import Callable, Literal, Match, TypeAlias
import warnings


@dataclass(frozen=True)
class AbbreviationContext:
    buffer: str
    cursor: int
    token_start: int
    token_end: int
    token: str
    command_path: tuple[str, ...] = ()
    command_position: bool = False
    quoted: bool = False

    @property
    def is_command_position(self) -> bool:
        return self.command_position


@dataclass(frozen=True)
class AbbreviationResult:
    text: str
    cursor: int | None = None
    replace_buffer: bool = False


ExpansionValue: TypeAlias = str | AbbreviationResult
ExpansionCallback: TypeAlias = Callable[
    [AbbreviationContext, Match[str] | None], ExpansionValue | None
]


@dataclass(frozen=True)
class Abbreviation:
    trigger: str | Pattern[str]
    replacement: ExpansionValue | ExpansionCallback
    position: Literal["command", "anywhere"] = "command"
    commands: tuple[str, ...] = ()
    cursor_marker: str | None = None
    expand_quoted: bool = False
    internal: bool = False
    source_file: str | None = None
    source_line: int | None = None

    @property
    def is_regex(self) -> bool:
        return not isinstance(self.trigger, str)

    def match(self, context: AbbreviationContext) -> Match[str] | bool | None:
        if context.quoted and not self.expand_quoted:
            return None
        # A command scope necessarily targets an argument.  Unscoped Fish
        # abbreviations remain command-position-only unless marked anywhere.
        if (
            self.position == "command"
            and not self.commands
            and not context.is_command_position
        ):
            return None
        if self.commands and context.command_path[: len(self.commands)] != self.commands:
            return None
        if self.is_regex:
            return self.trigger.fullmatch(context.token)
        return self.trigger == context.token

    def expand(
        self, context: AbbreviationContext, match: Match[str] | bool
    ) -> AbbreviationResult | None:
        regex_match = match if not isinstance(match, bool) else None
        value = (
            self.replacement(context, regex_match)
            if callable(self.replacement)
            else self.replacement
        )
        if value is None:
            return None
        result = value if isinstance(value, AbbreviationResult) else AbbreviationResult(value)
        if self.cursor_marker is None:
            return result
        if result.text.count(self.cursor_marker) != 1:
            raise ValueError(
                f"abbreviation {self.trigger!r} must contain exactly one "
                f"cursor marker {self.cursor_marker!r}"
            )
        marker_at = result.text.index(self.cursor_marker)
        return AbbreviationResult(
            result.text[:marker_at] + result.text[marker_at + len(self.cursor_marker) :],
            cursor=marker_at,
            replace_buffer=result.replace_buffer,
        )


class AbbreviationRegistry:
    def __init__(self, abbreviations: list[Abbreviation] | None = None):
        self.abbreviations = list(abbreviations or ())

    def add(self, abbreviation: Abbreviation) -> Abbreviation:
        self.abbreviations.append(abbreviation)
        return abbreviation

    @staticmethod
    def _priority(abbreviation: Abbreviation) -> tuple[int, int, int]:
        return (
            not abbreviation.is_regex,
            bool(abbreviation.commands),
            abbreviation.position == "command",
        )

    def applicable(self, context: AbbreviationContext) -> list[Abbreviation]:
        """Return matches in expansion order.

        This is intentionally the one applicability entry point for both the
        keybinding and any future abbreviation suggestions/completions.
        """
        matches = [a for a in self.abbreviations if a.match(context)]
        return sorted(matches, key=self._priority, reverse=True)

    def expand(
        self, context: AbbreviationContext
    ) -> tuple[AbbreviationResult, Abbreviation] | None:
        for abbreviation in self.applicable(context):
            match = abbreviation.match(context)
            assert match is not None
            result = abbreviation.expand(context, match)
            if result is not None:
                return result, abbreviation
        return None


def abbreviation_replacement_text(abbreviation: Abbreviation) -> str:
    """Describe a replacement without executing a dynamic callback."""
    replacement = abbreviation.replacement
    if isinstance(replacement, str):
        return replacement
    return getattr(replacement, "__qualname__", type(replacement).__name__)

# TODO move away from consumers using global XONSH_ABBREVIATIONS and instead just pass None for the registry
#  OR have them import it at least so it is clean where it comes from
#  even if XONSH has one global NS for all modules... I can still insist on only module imports to get globals
XONSH_ABBREVIATIONS = AbbreviationRegistry()

def abbr(*args, **options):

    # TODO! change abbr signature to abbr(trigger, replacement, registry=None) once registry is no longer passed as a positional arg
    #  just make it into an optional kwarg!
    # FYI this is for a temporary exploration of getting rid of registry parameter but not doing it all at once
    # Determine registry, trigger, and replacement from positional args.
    if args and isinstance(args[0], AbbreviationRegistry):
        # * first arg is registry
        registry = args[0]
        if len(args) < 3:
            raise TypeError("abbr() missing trigger and replacement")
        trigger = args[1]
        replacement = args[2]
    else:
        # * no registry arg (ideally the final destination of my refactoring)
        registry = XONSH_ABBREVIATIONS
        if len(args) < 2:
            raise TypeError("abbr() missing trigger and replacement")
        trigger = args[0]
        replacement = args[1]
    # Original function body continues here, using registry, trigger, replacement, and options.

    """Register an abbreviation with declaration syntax close to Fish's."""
    if isinstance(trigger, str) and trigger.endswith("?"):
        warnings.warn(
            f"abbreviation {trigger!r} ends in '?' and shadows abbreviation help",
            UserWarning,
            stacklevel=2,
        )
    caller = inspect.currentframe()
    try:
        caller = caller.f_back if caller is not None else None
        options.setdefault("source_file", caller.f_code.co_filename if caller else None)
        options.setdefault("source_line", caller.f_lineno if caller else None)
    finally:
        del caller
    return registry.add(Abbreviation(trigger, replacement, **options))
