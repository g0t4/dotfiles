import test_setup

import io
import os
import re
import subprocess

from rich.console import Console

from wes_abbreviation_list import (  # noqa: E402
    abbreviation_list_alias,
    abbreviation_listings,
    search_abbreviations,
)
from wes_abbreviations import (  # noqa: E402
    Abbreviation,
    abbr,
    abbreviation_replacement_text,
    abbreviation_replacement_texts,
    reset_registry,
)
import wes_abbreviations  # noqa: E402


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


def test_replacement_text_preserves_string_and_qualname():
    abbr_string = Abbreviation("pb", "pbpaste")
    abbr_callable = Abbreviation("foo", lambda *_: "bar")

    assert abbreviation_replacement_text(abbr_string) == "pbpaste"
    assert "lambda" in abbreviation_replacement_text(abbr_callable)


def test_replacement_texts_batch_matches_single():
    registry()
    abbreviations = wes_abbreviations.XONSH_ABBREVIATIONS.abbreviations

    singles = [
        abbreviation_replacement_text(abbr, show_fish_functions=False)
        for abbr in abbreviations
    ]
    batch = abbreviation_replacement_texts(abbreviations, show_fish_functions=False)
    assert singles == batch


def test_fish_source_uses_shared_fetch_and_palette(monkeypatch):
    from rich.syntax import Syntax
    from wes_fish_bridge import abbr_from_fish_function
    import wes_abbreviation_list as listing

    reset_registry()
    wes_abbreviations._FISH_SOURCE_CACHE.clear()
    abbr('helper', abbr_from_fish_function('fish_helper'))
    calls = []

    def capture(*args):
        calls.append(args)
        return 'function fish_helper\n    echo hello\nend'

    monkeypatch.setattr('wes_fish_bridge.fish_function_capture_stdout', capture)
    theme = Syntax('echo', 'fish')._theme
    monkeypatch.setattr(listing, 'syntax_theme', lambda: theme)
    rendered = []
    monkeypatch.setattr(listing, 'Syntax', lambda *args, **kwargs: rendered.append((args, kwargs)) or Syntax(*args, **kwargs))
    output = io.StringIO()
    abbreviation_list_alias(['--fish-functions', 'helper'], Console(file=output, force_terminal=True))
    assert calls == [('functions', '--color', 'never', 'fish_helper')]
    assert rendered[0][0] == ('function fish_helper\n    echo hello\nend', 'fish')
    assert rendered[0][1]['theme'] is theme
    assert '\x1b[' in output.getvalue()
    assert search_abbreviations('hello', show_fish_functions=True)[0].trigger == 'helper'
    wes_abbreviations._FISH_SOURCE_CACHE.clear()
