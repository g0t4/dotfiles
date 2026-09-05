import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from generate_git_abbreviations import TARGET, generate  # noqa: E402
from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
import wes_git_abbreviations  # noqa: E402
from wes_git_functions import format_line_numbers  # noqa: E402


def context(text, *, command_path=(), command_position=None):
    token = text.rsplit(maxsplit=1)[-1]
    if command_position is None:
        command_position = len(text) == len(token)
    return AbbreviationContext(
        buffer=text,
        cursor=len(text),
        token_start=len(text) - len(token),
        token_end=len(text),
        token=token,
        command_path=command_path,
        command_position=command_position,
    )


def registry():
    result = reset_registry()
    wes_git_abbreviations.register_git_abbreviations()
    return result


def test_generated_git_module_is_in_sync_with_fish_source():
    assert TARGET.read_text() == generate()


def test_git_only_inventory_count_and_cursor_markers():
    entries = registry().abbreviations

    assert len(entries) == 214
    for entry in entries:
        if entry.cursor_marker and isinstance(entry.replacement, str):
            assert entry.replacement.count(entry.cursor_marker) == 1, entry.trigger


def test_static_git_abbreviation_and_cursor_marker():
    git_abbreviations = registry()

    result, _ = git_abbreviations.expand(context("gsts", command_path=("gsts",)))
    assert result.text == "git status -s"

    result, _ = git_abbreviations.expand(context("gcmsg", command_path=("gcmsg",)))
    assert result.text == 'git commit -m ""'
    assert result.cursor == 15

    result, _ = git_abbreviations.expand(context("grstr", command_path=("grstr",)))
    assert result.text == "git restore --staged $(_repo_root)"


def test_git_diff_scoped_option_does_not_leak_to_git_show():
    git_abbreviations = registry()

    assert git_abbreviations.expand(
        context("git diff -W", command_path=("git", "diff"))
    )
    assert git_abbreviations.expand(
        context("git show -W", command_path=("git", "show"))
    ) is None


def test_git_author_is_command_scoped():
    git_abbreviations = registry()

    assert git_abbreviations.expand(
        context("git codex", command_path=("git",), command_position=False)
    )
    assert git_abbreviations.expand(
        context("ls codex", command_path=("ls",), command_position=False)
    ) is None


def test_regex_abbreviation_delegates_to_named_fish_function(monkeypatch):
    calls = []

    def fake_fish(function_name, token):
        calls.append((function_name, token))
        return "@{12}"

    monkeypatch.setattr(wes_git_abbreviations, "fish_function", fake_fish)
    result, _ = registry().expand(
        context("git show reflog12", command_path=("git", "show"))
    )

    assert result.text == "@{12}"
    assert calls == [("_abbr_expand_reflog_d", "reflog12")]


def test_generic_nl_abbreviations_are_deferred():
    assert registry().expand(
        context("nl -b", command_path=("nl",), command_position=False)
    ) is None


def test_native_line_numbers_matches_fish_shape():
    assert format_line_numbers("first\nsecond\n") == (
        "\x1b[33m   1\x1b[0m first\n\x1b[33m   2\x1b[0m second\n"
    )
