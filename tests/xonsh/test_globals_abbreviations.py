import re
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
from wes_globals_abbreviations import (  # noqa: E402
    EMOJI_ABBREVIATIONS,
    register_globals_abbreviations,
)


def context(token, *, command_position=True):
    return AbbreviationContext(
        buffer=token,
        cursor=len(token),
        token_start=0,
        token_end=len(token),
        token=token,
        command_position=command_position,
    )


def registry():
    result = reset_registry()
    register_globals_abbreviations()
    return result


def test_all_fish_abbreviations_are_migrated():
    source = ROOT / "fish/load_last_interactive_only/globals-specific.fish"
    fish_count = sum(
        bool(re.match(r"^\s*abbr(?:\s|$)", line))
        for line in source.read_text().splitlines()
    )

    assert len(registry().abbreviations) == fish_count
    assert len(EMOJI_ABBREVIATIONS) == 18


def test_pipe_abbreviations_expand_inside_a_command():
    abbreviations = registry()

    result, _ = abbreviations.expand(context("pgr", command_position=False))
    assert result.text == "| rg_grep -i"

    result, _ = abbreviations.expand(context("errout", command_position=False))
    assert result.text == "2>&1"


def test_numbered_head_and_tail_abbreviations_are_native():
    abbreviations = registry()

    result, _ = abbreviations.expand(context("ph12", command_position=False))
    assert result.text == "| head -12"

    result, _ = abbreviations.expand(context("h3"))
    assert result.text == "head -3"

    result, _ = abbreviations.expand(context("pt7", command_position=False))
    assert result.text == "| tail -7"


def test_xargs_abbreviations_preserve_cursor_position():
    abbreviations = registry()

    result, _ = abbreviations.expand(context("px", command_position=False))
    assert result.text == "| xargs --verbose -I_ --  _"
    assert result.cursor == len("| xargs --verbose -I_ -- ")

    result, _ = abbreviations.expand(context("xargs"))
    assert result.text == "gxargs"
