"""Searchable terminal and pipeline views of the Xonsh abbreviation registry."""

from __future__ import annotations

from dataclasses import dataclass
import inspect
import sys
from typing import TextIO

from rich.console import Console
from rich.table import Table

from wes_abbreviations import Abbreviation, AbbreviationRegistry


@dataclass(frozen=True)
class AbbreviationListing:
    trigger: str
    expansion: str
    scope: str
    search_text: str


def _trigger_text(abbreviation: Abbreviation) -> str:
    if isinstance(abbreviation.trigger, str):
        return abbreviation.trigger
    return f"/{abbreviation.trigger.pattern}/"


def _replacement_text(abbreviation: Abbreviation) -> str:
    replacement = abbreviation.replacement
    if isinstance(replacement, str):
        return replacement
    return getattr(replacement, "__qualname__", type(replacement).__name__)


def _callback_source(abbreviation: Abbreviation) -> str:
    if not callable(abbreviation.replacement):
        return ""
    try:
        return inspect.getsource(abbreviation.replacement)
    except (OSError, TypeError):
        return ""


def abbreviation_listings(
    registry: AbbreviationRegistry,
) -> list[AbbreviationListing]:
    listings = []
    for abbreviation in registry.abbreviations:
        # Submit-only entries are internal resolvers, not user abbreviations.
        if abbreviation.submit_only:
            continue
        trigger = _trigger_text(abbreviation)
        expansion = _replacement_text(abbreviation)
        scope = " ".join(abbreviation.commands) or abbreviation.position
        search_text = "\n".join(
            (trigger, expansion, scope, _callback_source(abbreviation))
        ).casefold()
        listings.append(AbbreviationListing(trigger, expansion, scope, search_text))
    return listings


def search_abbreviations(
    registry: AbbreviationRegistry, query="", *, prefix=False
) -> list[AbbreviationListing]:
    query = query.casefold()
    listings = abbreviation_listings(registry)
    if not query:
        return listings
    if prefix:
        return [item for item in listings if item.trigger.casefold().startswith(query)]
    return [item for item in listings if query in item.search_text]


def render_abbreviation_list(
    listings: list[AbbreviationListing],
    *,
    stream: TextIO | None = None,
    plain: bool | None = None,
):
    stream = stream or sys.stdout
    if plain is None:
        plain = not bool(getattr(stream, "isatty", lambda: False)())
    if plain:
        for item in listings:
            print(f"{item.trigger}\t{item.expansion}\t{item.scope}", file=stream)
        return

    table = Table(show_header=True, header_style="bold cyan", box=None)
    table.add_column("Trigger", style="bold")
    table.add_column("Expansion")
    table.add_column("Scope", style="dim")
    for item in listings:
        table.add_row(item.trigger, item.expansion, item.scope)
    Console(file=stream).print(table)


def abbreviation_list_alias(registry: AbbreviationRegistry, args, stdout=None, **_):
    values = list(args)
    plain = False
    mode = "any"
    query_parts = []
    for value in values:
        if value == "--plain":
            plain = True
        elif value == "--any":
            mode = "any"
        elif value == "--prefix":
            mode = "prefix"
        elif value in ("-h", "--help"):
            print(
                "usage: _abbr_list [--any | --prefix] [--plain] [QUERY]",
                file=stdout or sys.stdout,
            )
            return
        elif value.startswith("-"):
            raise ValueError(f"unknown _abbr_list option: {value}")
        else:
            query_parts.append(value)

    query = " ".join(query_parts)
    listings = search_abbreviations(registry, query, prefix=mode == "prefix")
    render_abbreviation_list(
        listings,
        stream=stdout,
        plain=True if plain else None,
    )
