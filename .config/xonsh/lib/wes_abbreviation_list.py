"""Searchable terminal and pipeline views of the Xonsh abbreviation registry."""

from __future__ import annotations

from dataclasses import dataclass
import inspect
import sys
from typing import TextIO

from rich.console import Console
from rich.table import Table

from wes_abbreviations import (
    Abbreviation,
    abbreviation_replacement_text,
)
import wes_abbreviations


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


def _callback_source(abbreviation: Abbreviation) -> str:
    if not callable(abbreviation.replacement):
        return ""
    try:
        return inspect.getsource(abbreviation.replacement)
    except (OSError, TypeError):
        return ""


def abbreviation_listings() -> list[AbbreviationListing]:
    listings = []
    registry = wes_abbreviations.XONSH_ABBREVIATIONS
    for abbreviation in registry.abbreviations:
        if abbreviation.internal:
            continue
        trigger = _trigger_text(abbreviation)
        expansion = abbreviation_replacement_text(abbreviation)
        scope = " ".join(abbreviation.commands) or abbreviation.position
        search_text = "\n".join(
            (trigger, expansion, scope, _callback_source(abbreviation))
        ).casefold()
        listings.append(AbbreviationListing(trigger, expansion, scope, search_text))
    return listings


def search_abbreviations(
    query="", *, prefix=False
) -> list[AbbreviationListing]:
    query = query.casefold()
    listings = abbreviation_listings()
    if not query:
        return listings
    if prefix:
        return [item for item in listings if item.trigger.casefold().startswith(query)]
    return [item for item in listings if query in item.search_text]


def abbreviation_list_alias(
    args, console: Console, **_
):
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
            console.print(
                "usage: _abbr_list [--any | --prefix] [--plain] [QUERY]",
            )
            return
        elif value.startswith("-"):
            raise ValueError(f"unknown _abbr_list option: {value}")
        else:
            query_parts.append(value)

    query = " ".join(query_parts)
    listings = search_abbreviations(query, prefix=mode == "prefix")

    def render_abbreviation_list():
        table = Table(
            show_header=True,
            header_style="bold",
            box=None,
            collapse_padding=True,
            padding=(0, 1),
        )
        table.add_column("Trigger", style="cyan", header_style="cyan", no_wrap=True)
        table.add_column("Expansion", style="white", header_style="white")
        table.add_column("Scope", style="dim", header_style="dim")
        for item in listings:
            table.add_row(item.trigger, item.expansion, item.scope)
        console.print(table)

    render_abbreviation_list()
