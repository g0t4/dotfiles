import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
from wes_macos_abbreviations import register_macos_abbreviations  # noqa: E402


def context(token):
    return AbbreviationContext(
        buffer=token,
        cursor=len(token),
        token_start=0,
        token_end=len(token),
        token=token,
        command_position=True,
    )


def test_security_abbreviations_preserve_fish_commands_and_cursor():
    registry = reset_registry()
    register_macos_abbreviations()

    expected = {
        "securityf": "security find-generic-password -w -s % -a ",
        "securityrm": "security delete-generic-password -s % -a ",
        "securitya": "security add-generic-password -U -X $(pbpaste | xxd -p | tr -d '\\n') -s % -a ",
    }

    assert {entry.trigger for entry in registry.abbreviations} == set(expected)
    for trigger, replacement in expected.items():
        result, _ = registry.expand(context(trigger))
        assert result.text == replacement.replace("%", "")
        assert result.cursor == replacement.index("%")
