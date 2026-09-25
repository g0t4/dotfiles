import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

# TODO fix tests for using shared generate_from_fish.py now

from wes_abbreviations import AbbreviationContext, reset_registry # noqa: E402
from wes_docker import register_wes_docker


def context(token):
    return AbbreviationContext(
        buffer=token,
        cursor=len(token),
        token_start=0,
        token_end=len(token),
        token=token,
        command_position=True,
    )


def registry():
    result = reset_registry()
    register_wes_docker()
    return result


def test_generated_module_is_in_sync_with_docker_fish_source():
    assert TARGET.read_text() == generate()


def test_inventory_and_all_static_cursor_markers():
    entries = registry().abbreviations

    assert len(entries) == 193
    for entry in entries:
        assert isinstance(entry.replacement, str)
        if entry.cursor_marker:
            assert entry.replacement.count(entry.cursor_marker) == 1, entry.trigger


def test_cursor_abbreviation_positions_inside_quotes():
    result, _ = registry().expand(context("ddc"))

    assert result.text == "docker debug --command ''"
    assert result.cursor == len("docker debug --command '")


def test_hub_tool_abbreviations_remain_available():
    result, _ = registry().expand(context("dhtj"))

    assert result.text == "hub-tool tag ls --format json  | jq"
    assert result.cursor == len("hub-tool tag ls --format json ")
