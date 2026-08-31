import io
import os
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_abbreviation_list import (  # noqa: E402
    abbreviation_list_alias,
    abbreviation_listings,
    render_abbreviation_list,
    search_abbreviations,
)
from wes_abbreviations import AbbreviationRegistry, abbr  # noqa: E402


def registry():
    result = AbbreviationRegistry()
    abbr(result, "pb", "pbpaste")
    abbr(result, "pcp", "| pbcopy", position="anywhere")
    abbr(result, "codex", "--author codex", commands=("git",))
    abbr(result, re.compile(r"ph(\d+)"), lambda *_: "| head")
    abbr(result, re.compile(r".+?\?{1,2}"), lambda *_: None, internal=True)
    return result


def test_any_search_covers_trigger_expansion_and_scope():
    abbreviations = registry()

    assert [item.trigger for item in search_abbreviations(abbreviations, "pb")] == [
        "pb",
        "pcp",
    ]
    assert [
        item.trigger for item in search_abbreviations(abbreviations, "pbpaste")
    ] == ["pb"]
    assert [item.trigger for item in search_abbreviations(abbreviations, "git")] == [
        "codex"
    ]


def test_prefix_search_only_uses_displayed_trigger():
    abbreviations = registry()

    assert [
        item.trigger
        for item in search_abbreviations(abbreviations, "p", prefix=True)
    ] == ["pb", "pcp"]
    assert search_abbreviations(abbreviations, "pbpaste", prefix=True) == []


def test_regexes_are_displayed_and_internal_resolvers_are_hidden():
    listings = abbreviation_listings(registry())

    assert "/ph(\\d+)/" in [item.trigger for item in listings]
    assert all("?{1,2}" not in item.trigger for item in listings)


def test_plain_output_is_stable_and_pipe_friendly():
    output = io.StringIO()

    render_abbreviation_list(search_abbreviations(registry(), "pb"), stream=output)

    assert output.getvalue() == "pb\tpbpaste\tcommand\npcp\t| pbcopy\tanywhere\n"


def test_rich_output_visibly_separates_trigger_expansion_and_scope():
    output = io.StringIO()

    render_abbreviation_list(
        search_abbreviations(registry(), "pb"), stream=output, plain=False
    )

    rendered = output.getvalue()
    assert "Trigger" in rendered
    assert re.search(r" pb\s+│ pbpaste", rendered)
    assert "│ command" in rendered


def test_alias_supports_any_prefix_and_help():
    output = io.StringIO()
    abbreviation_list_alias(
        registry(), ["--plain", "--any", "pbpaste"], stdout=output
    )
    assert output.getvalue() == "pb\tpbpaste\tcommand\n"

    output = io.StringIO()
    abbreviation_list_alias(
        registry(), ["--plain", "--prefix", "pc"], stdout=output
    )
    assert output.getvalue() == "pcp\t| pbcopy\tanywhere\n"

    output = io.StringIO()
    abbreviation_list_alias(registry(), ["--help"], stdout=output)
    assert output.getvalue().startswith("usage: _abbr_list")


def test_xonsh_pipeline_automatically_uses_plain_output(tmp_path):
    rc = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    command = (
        f"source {rc}; "
        "from wes_abbreviations import abbr; "
        "_ = abbr(XONSH_ABBREVIATIONS, 'zztest', 'echo yes'); "
        "_abbr_list --prefix zztest | head -1"
    )
    env = os.environ | {
        "XONSH_CONFIG_DIR": str(ROOT / ".config/xonsh"),
        "XDG_STATE_HOME": str(tmp_path),
    }

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout == "zztest\techo yes\tcommand\n"
    assert "\x1b[" not in completed.stdout
