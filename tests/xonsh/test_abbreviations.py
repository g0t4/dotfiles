from dataclasses import replace
import os
import re
import subprocess
import sys
from pathlib import Path

import pytest
from prompt_toolkit.buffer import Buffer
from rich.console import Console


XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))

import wes_fish_bridge  # noqa: E402
import wes_abbreviation_help  # noqa: E402
from wes_abbreviation_help import (  # noqa: E402
    abbreviation_help_alias,
    register_abbreviation_help,
    render_abbreviation_help,
)
from wes_abbreviations import (  # noqa: E402
    Abbreviation,
    AbbreviationContext,
    AbbreviationRegistry,
    AbbreviationResult,
    abbr,
    reset_registry,
)
from wes_xonsh_abbreviations import (  # noqa: E402
    XonshAbbreviationExpander,
    abbreviation_completion_candidates,
    abbreviation_picker_rows,
    apply_abbreviation_selection,
    expand_abbreviation_on_space,
    command_path_from_args,
    context_from_completion,
)
from wes_fish_bridge import (  # noqa: E402
    FishFunctionError,
    fish_function,
    fish_function_command,
)


def context(text, *, command_path=(), quoted=False):
    token = text.rsplit(maxsplit=1)[-1] if text else ""
    return AbbreviationContext(
        buffer=text,
        cursor=len(text),
        token_start=len(text) - len(token),
        token_end=len(text),
        token=token,
        command_path=command_path,
        command_position=len(text) == len(token),
        quoted=quoted,
    )


def test_exact_command_abbreviation_expands():
    registry = AbbreviationRegistry(
        [Abbreviation("gst", "git status", position="command")]
    )
    assert registry.expand(context("gst", command_path=("gst",))) == (
        AbbreviationResult("git status"),
        registry.abbreviations[0],
    )


def test_abbr_helper_registers_and_returns_dot_accessible_entry():
    registry = reset_registry()
    entry = abbr("gst", "git status")

    assert entry.trigger == "gst"
    assert entry.replacement == "git status"
    assert registry.abbreviations == [entry]
    assert entry.source_file == __file__
    assert entry.source_line is not None


def test_question_suffix_warns_because_it_shadows_help():
    registry = reset_registry()

    with pytest.warns(UserWarning, match="shadows abbreviation help"):
        abbr("why?", "because")


def test_abbreviation_help_resolves_then_native_help_can_fall_through():
    registry = reset_registry()
    abbr("gst", "git status")
    register_abbreviation_help()

    short, _ = registry.expand(context("gst?", command_path=("gst?",)))
    full, _ = registry.expand(context("gst??", command_path=("gst??",)))

    assert short.text == "_abbr_help gst"
    assert full.text == "_abbr_help --full gst"
    assert short.replace_buffer
    assert full.replace_buffer
    assert registry.expand(context("str??", command_path=("str??",))) is None


def test_abbreviation_help_expands_on_space_as_a_reminder_command():
    registry = reset_registry()
    abbr("gst", "git status")
    register_abbreviation_help()
    expander = XonshAbbreviationExpander.__new__(XonshAbbreviationExpander)
    expander.registry = registry
    expander.context = lambda _buffer: context("gst??", command_path=("gst??",))
    buffer = Buffer()
    buffer.text = "gst??"
    buffer.cursor_position = len(buffer.text)

    expand_abbreviation_on_space(buffer, expander)

    assert buffer.text == "_abbr_help --full gst "


def test_abbreviation_help_uses_command_context():
    registry = reset_registry()
    abbr("codex", "--author codex", commands=("git",))
    register_abbreviation_help()

    result, _ = registry.expand(
        context("git codex??", command_path=("git",))
    )

    assert result.text == "_abbr_help --full git codex"
    assert result.replace_buffer
    assert (
        registry.expand(context("ls codex??", command_path=("ls",))) is None
    )

    expander = XonshAbbreviationExpander.__new__(XonshAbbreviationExpander)
    expander.registry = registry
    expander.context = lambda _buffer, cursor=None: context(
        "git codex??", command_path=("git",)
    )
    buffer = Buffer()
    buffer.text = "git codex??"
    buffer.cursor_position = len(buffer.text)
    expander.expand(buffer)

    assert buffer.text == "_abbr_help --full git codex"


def test_abbreviation_help_alias_looks_up_readable_context_after_submit(monkeypatch):
    registry = reset_registry()
    target = abbr("codex", "--author codex", commands=("git",))
    rendered = []
    monkeypatch.setattr(
        wes_abbreviation_help,
        "render_abbreviation_help",
        lambda abbreviation, **options: rendered.append((abbreviation, options)),
    )

    abbreviation_help_alias(registry, ["--full", "git", "codex"])

    assert rendered == [(target, {"full": True})]


def test_full_abbreviation_help_renders_metadata_and_callback_source():
    def dynamic(_context, _match):
        return "git status"

    registry = reset_registry()
    target = abbr("gst", dynamic, cursor_marker="%")
    console = Console(record=True, width=120, color_system=None)

    render_abbreviation_help(target, full=True, console=console)
    rendered = console.export_text()

    assert "abbreviation gst" in rendered
    assert "Expansion: dynamic" in rendered
    assert "Position:  command" in rendered
    assert "Cursor:    '%'" in rendered
    assert f"Source:    {__file__}:" in rendered
    assert "def dynamic" in rendered


def test_command_scoped_abbreviation_uses_shared_applicability():
    abbreviation = Abbreviation(
        "codex", "Wes McKinney <wes@example.test>", commands=("git",)
    )
    registry = AbbreviationRegistry([abbreviation])

    assert registry.applicable(context("git codex", command_path=("git",))) == [
        abbreviation
    ]
    assert registry.applicable(context("ls codex", command_path=("ls",))) == []


def test_command_path_is_ready_for_subcommand_scoping():
    abbreviation = Abbreviation("-W", "--function-context", commands=("git", "diff"))
    registry = AbbreviationRegistry([abbreviation])

    assert registry.expand(context("git diff -W", command_path=("git", "diff")))
    assert registry.expand(context("git show -W", command_path=("git", "show"))) is None


def test_regex_callback_receives_match_and_context():
    def expand_reflog(ctx, match):
        assert ctx.command_path == ("git", "show")
        return f"@{{{match.group(1)}}}"

    registry = AbbreviationRegistry(
        [
            Abbreviation(
                re.compile(r"reflog(\d+)"),
                expand_reflog,
                position="anywhere",
            )
        ]
    )

    result, _ = registry.expand(
        context("git show reflog12", command_path=("git", "show"))
    )
    assert result == AbbreviationResult("@{12}")


def test_cursor_marker_is_removed_and_sets_cursor():
    registry = AbbreviationRegistry(
        [Abbreviation("gcmsg", 'git commit -m "%"', cursor_marker="%")]
    )

    result, _ = registry.expand(context("gcmsg", command_path=("gcmsg",)))
    assert result == AbbreviationResult('git commit -m ""', cursor=15)


@pytest.mark.parametrize(
    ("replacement", "cursor", "expected_text", "expected_cursor"),
    (
        ('git commit -m ""', 15, 'git commit -m ""', 15),
        ("git status", None, "git status ", 11),
    ),
)
def test_space_trigger_is_consumed_only_for_internal_cursor_expansions(
    replacement, cursor, expected_text, expected_cursor
):
    buffer = Buffer()
    buffer.text = "abbr"

    class StubExpander:
        def expand(self, target_buffer, **_):
            target_buffer.text = replacement
            target_buffer.cursor_position = len(replacement) if cursor is None else cursor
            return AbbreviationResult(replacement, cursor=cursor)

    expand_abbreviation_on_space(buffer, StubExpander())

    assert buffer.text == expected_text
    assert buffer.cursor_position == expected_cursor


def test_space_after_non_abbreviation_is_inserted_normally():
    buffer = Buffer()
    buffer.text = "z"
    buffer.cursor_position = 1
    expander = XonshAbbreviationExpander.__new__(XonshAbbreviationExpander)
    expander.registry = AbbreviationRegistry()
    expander.context = lambda _buffer: context("z", command_path=("z",))

    expand_abbreviation_on_space(buffer, expander)

    assert buffer.text == "z "
    assert buffer.cursor_position == 2


def test_exact_beats_regex_and_scoped_beats_global():
    global_regex = Abbreviation(re.compile(r"g.*"), "regex")
    global_exact = Abbreviation("gst", "global")
    scoped_exact = Abbreviation("gst", "scoped", commands=("gst",))
    registry = AbbreviationRegistry([global_regex, global_exact, scoped_exact])

    result, abbreviation = registry.expand(context("gst", command_path=("gst",)))
    assert result.text == "scoped"
    assert abbreviation is scoped_exact


def test_command_position_definition_beats_same_anywhere_regex():
    command_only = Abbreviation(re.compile(r"\.\.+"), "cd ../")
    anywhere = Abbreviation(
        re.compile(r"\.\.+"), "../", position="anywhere"
    )
    registry = AbbreviationRegistry([anywhere, command_only])

    result, abbreviation = registry.expand(context("...", command_path=("...",)))

    assert result.text == "cd ../"
    assert abbreviation is command_only


def test_quoted_tokens_are_not_expanded_by_default():
    registry = AbbreviationRegistry([Abbreviation("codex", "an author")])

    assert registry.expand(context('git commit -m "codex', quoted=True)) is None


def test_callback_can_decline_expansion_or_raise_a_useful_error():
    def decline(_ctx, _match):
        return None

    def needs_review(_ctx, _match):
        raise RuntimeError("port of _dangerous_helper requires review")

    assert AbbreviationRegistry([Abbreviation("x", decline)]).expand(
        context("x", command_path=("x",))
    ) is None

    with pytest.raises(RuntimeError, match="_dangerous_helper requires review"):
        AbbreviationRegistry([Abbreviation("x", needs_review)]).expand(
            context("x", command_path=("x",))
        )


class FakeArg:
    def __init__(self, value, *, is_io_redir=False):
        self.value = value
        self.is_io_redir = is_io_redir


class FakeCommand:
    args = (FakeArg("git"), FakeArg("diff"))
    arg_index = 2
    prefix = "-W"
    suffix = "ord"
    opening_quote = ""
    closing_quote = ""


def test_xonsh_completion_context_is_adapted_without_relexing():
    adapted = context_from_completion("echo x | git diff -Word", 21, FakeCommand())

    assert adapted.token == "-Word"
    assert adapted.token_start == 19
    assert adapted.token_end == 24
    assert adapted.command_path == ("git", "diff")
    assert not adapted.command_position


def test_abbreviation_completion_matches_literal_prefix_and_scope():
    registry = AbbreviationRegistry(
        [
            Abbreviation("pbsse", "pbpaste | sed"),
            Abbreviation("pbsse_verbose", "pbpaste | verbose"),
            Abbreviation("private", "hidden", internal=True),
            Abbreviation("codex", "--author codex", commands=("git",)),
            Abbreviation(re.compile(r"p[0-9]+"), "dynamic"),
        ]
    )

    assert abbreviation_completion_candidates(registry, context("pbs")) == [
        ("pbsse", "pbpaste | sed"),
        ("pbsse_verbose", "pbpaste | verbose"),
    ]
    assert abbreviation_completion_candidates(
        registry, context("git co", command_path=("git",))
    ) == [("codex", "--author codex")]
    assert abbreviation_completion_candidates(
        registry, context("ls co", command_path=("ls",))
    ) == []


def test_empty_argument_completion_hides_global_anywhere_abbreviations():
    registry = AbbreviationRegistry(
        [
            Abbreviation("pjq", "| jq", position="anywhere"),
            Abbreviation("codex", "--author codex", commands=("git",)),
        ]
    )
    empty_argument = AbbreviationContext(
        buffer="git ",
        cursor=4,
        token_start=4,
        token_end=4,
        token="",
        command_path=("git",),
        command_position=False,
    )

    assert abbreviation_completion_candidates(registry, empty_argument) == [
        ("codex", "--author codex")
    ]
    assert abbreviation_completion_candidates(
        registry,
        replace(empty_argument, buffer="git p", cursor=5, token_end=5, token="p"),
    ) == [("pjq", "| jq")]


def test_picker_still_lists_anywhere_abbreviations_for_an_empty_argument():
    registry = AbbreviationRegistry(
        [Abbreviation("pjq", "| jq", position="anywhere")]
    )
    empty_argument = AbbreviationContext(
        buffer="echo ",
        cursor=5,
        token_start=5,
        token_end=5,
        token="",
        command_path=("echo",),
        command_position=False,
    )

    assert abbreviation_picker_rows(registry, empty_argument) == ["pjq\t| jq"]


def test_abbreviation_picker_lists_namespace_and_replaces_current_token():
    registry = AbbreviationRegistry(
        [
            Abbreviation("pbsse", "pbpaste | sed"),
            Abbreviation("pbsse_verbose", "pbpaste  |\n verbose"),
            Abbreviation("codex", "--author codex", commands=("git",)),
        ]
    )

    assert abbreviation_picker_rows(registry, context("pbs")) == [
        "pbsse\tpbpaste | sed",
        "pbsse_verbose\tpbpaste | verbose",
    ]
    assert apply_abbreviation_selection(
        "echo pbs tail", 5, 8, "pbsse_verbose"
    ) == ("echo pbsse_verbose tail", 18)
    assert apply_abbreviation_selection("echo pbs", 5, 8, None) == (
        "echo pbs",
        8,
    )


def test_xonsh_abbreviation_completer_is_non_exclusive(tmp_path):
    rc = Path(__file__).parents[2] / ".config/xonsh/rc.d/abbreviations.xsh"
    env = os.environ | {
        "XONSH_CONFIG_DIR": str(rc.parents[1]),
        "XDG_STATE_HOME": str(tmp_path),
    }
    command = (
        f"source {rc}; "
        "from xonsh.completers.tools import is_exclusive_completer; "
        "print(is_exclusive_completer(__xonsh__.completers['wes_abbreviations']))"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout == "False\n"


def test_command_path_skips_assignments_env_options_and_redirections():
    args = (
        FakeArg("env"),
        FakeArg("-u"),
        FakeArg("OLD"),
        FakeArg("MODE=test"),
        FakeArg("git"),
        FakeArg("diff"),
        FakeArg(">", is_io_redir=True),
    )

    assert command_path_from_args(args) == ("git", "diff")


def test_fish_bridge_passes_arguments_outside_command_string(monkeypatch):
    monkeypatch.setattr(wes_fish_bridge, "find_fish", lambda: "/test/fish")

    def fake_run(argv, **kwargs):
        assert argv == [
            "/test/fish",
            "-ic",
            "$argv[1] $argv[2..]",
            "--",
            "git_helper",
            "argument with spaces",
        ]
        assert kwargs["capture_output"] is True
        assert kwargs["input"] is None
        return subprocess.CompletedProcess(argv, 0, stdout="value\n", stderr="")

    monkeypatch.setattr(subprocess, "run", fake_run)
    assert fish_function("git_helper", "argument with spaces") == "value"


def test_fish_bridge_can_forward_pipeline_input(monkeypatch):
    def fake_run(_argv, **kwargs):
        assert kwargs["input"] == "one\ntwo\n"
        return subprocess.CompletedProcess([], 0, stdout="1 one\n2 two\n", stderr="")

    monkeypatch.setattr(subprocess, "run", fake_run)
    assert fish_function("line_numbers", input_text="one\ntwo\n") == "1 one\n2 two"


def test_fish_command_bridge_preserves_streams_and_exit_status(monkeypatch):
    monkeypatch.setattr(wes_fish_bridge, "find_fish", lambda: "/test/fish")
    streams = [object(), object(), object()]

    def fake_run(argv, **kwargs):
        assert argv == [
            "/test/fish",
            "-ic",
            "$argv[1] $argv[2..]",
            "--",
            "interactive_helper",
            "argument with spaces",
        ]
        assert kwargs == dict(zip(("stdin", "stdout", "stderr"), streams))
        return subprocess.CompletedProcess(argv, 7)

    monkeypatch.setattr(subprocess, "run", fake_run)
    assert (
        fish_function_command(
            "interactive_helper",
            "argument with spaces",
            stdin=streams[0],
            stdout=streams[1],
            stderr=streams[2],
        )
        == 7
    )


def test_fish_bridge_reports_function_and_stderr(monkeypatch):
    def fake_run(argv, **_kwargs):
        return subprocess.CompletedProcess(argv, 9, stdout="", stderr="bad state\n")

    monkeypatch.setattr(subprocess, "run", fake_run)
    with pytest.raises(FishFunctionError, match="git_helper.*bad state"):
        fish_function("git_helper")
