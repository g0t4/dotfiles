import io
import os
import re
import subprocess
import sys
from pathlib import Path

from rich.console import Console


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_abbreviation_list import (  # noqa: E402
    abbreviation_list_alias,
    abbreviation_listings,
    search_abbreviations,
)
from wes_abbreviations import abbr, reset_registry  # noqa: E402


def registry():
    registry = reset_registry()
    abbr("pb", "pbpaste")
    abbr("pcp", "| pbcopy", position="anywhere")
    abbr("codex", "--author codex", commands=("git",))
    abbr(re.compile(r"ph(\d+)"), lambda *_: "| head")
    abbr(re.compile(r".+?\?{1,2}"), lambda *_: None, internal=True)
    return registry


def test_any_search_covers_trigger_expansion_and_scope():
    abbreviations = registry()

    assert [item.trigger for item in search_abbreviations("pb")] == [
        "pb",
        "pcp",
    ]
    assert [
        item.trigger for item in search_abbreviations("pbpaste")
    ] == ["pb"]
    assert [item.trigger for item in search_abbreviations("git")] == [
        "codex"
    ]


def test_prefix_search_only_uses_displayed_trigger():
    abbreviations = registry()

    assert [
        item.trigger
        for item in search_abbreviations("p", prefix=True)
    ] == ["pb", "pcp"]
    assert search_abbreviations("pbpaste", prefix=True) == []


def test_regexes_are_displayed_and_internal_resolvers_are_hidden():
    registry()

    listings = abbreviation_listings()

    assert "/ph(\\d+)/" in [item.trigger for item in listings]
    assert all("?{1,2}" not in item.trigger for item in listings)


def test_rich_output_visibly_separates_trigger_expansion_and_scope():
    registry()
    output = io.StringIO()

    abbreviation_list_alias(
        ["--prefix", "pb"], Console(file=output)
    )

    rendered = output.getvalue()
    print('rendered', rendered)
    assert "Trigger" in rendered
    assert re.search(r"pb\s+pbpaste\s+command", rendered)


def test_alias_supports_any_prefix_and_help():
    registry()
    output = io.StringIO()
    abbreviation_list_alias(
        ["--any", "pbpaste"], Console(file=output)
    )
    assert re.search(r"pb\s*|\s*pbpaste", output.getvalue())

    output = io.StringIO()
    abbreviation_list_alias(
        ["--prefix", "pc"], Console(file=output)
    )
    assert re.search(r"pcp\s*|\s*pbcopy\s*|\s*anywhere\n", output.getvalue())

    output = io.StringIO()
    abbreviation_list_alias(["--help"], Console(file=output))
    assert output.getvalue().startswith("usage: _abbr_list")
