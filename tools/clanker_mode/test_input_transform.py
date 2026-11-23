import sys
from pathlib import Path

import pytest
from xonsh.completer import Completer
from xonsh.events import events
from xonsh.shell import transform_command


@pytest.fixture
def clanker_input(shell, monkeypatch):
    root = Path(__file__).resolve().parents[2]
    monkeypatch.syspath_prepend(str(root / ".config/xonsh/lib"))
    shell.ctx.update(
        XONSH_LIB=root / ".config/xonsh/lib", sys=sys, aliases=shell.aliases
    )
    shell.execer.exec(
        (root / ".config/xonsh/rc.d/clanker-mode.py").read_text(), glbs=shell.ctx
    )
    handler = shell.ctx["_clanker_literal_syntax_fallback"]
    yield shell, handler
    events.on_transform_command.discard(handler)


@pytest.mark.parametrize(
    "prompt",
    [
        "what does {} mean in c#",
        "what does {} mean in c# $HOME $(touch /never-execute) | cat",
        'what does {} mean in c# "unterminated',
        "what does {} mean in c# it's confusing",
    ],
)
def test_invalid_submission_dispatches_literal_text(clanker_input, prompt):
    shell, handler = clanker_input
    original = f"clank {prompt}\n"
    with pytest.raises(SyntaxError):
        shell.execer.compile(original, mode="single", glbs=shell.ctx)
    calls = []
    shell.ctx["_clank_alias"] = lambda args: calls.append(args)
    transformed = transform_command(original, show_diff=False)
    assert handler(transformed) is None
    assert transform_command(transformed, show_diff=False) == transformed
    shell.execer.exec(transformed, glbs=shell.ctx)
    assert calls == [[prompt]]


@pytest.mark.parametrize(
    "source",
    [
        'clank "what does {} mean in c#"\n',
        "clank --help\n",
        "clank --clear\n",
        "clank hello > answer.txt\n",
        "clank hello | cat\n",
        "clank\n",
        "clanker what does {} mean in c#\n",
        "echo what does {} mean in c#\n",
        'print("clank what does {} mean in c#")\n',
    ],
)
def test_other_input_is_unchanged(clanker_input, source):
    _, handler = clanker_input
    assert handler(source) is None


def test_manage_completion_runs_through_real_xonsh_completer(clanker_input):
    shell, _ = clanker_input
    completions, _ = Completer().complete_line("clank manage ")
    values = {str(completion).strip() for completion in completions}
    assert {"list", "save", "restore", "compact"} <= values
    assert "clanker" in shell.completers


@pytest.mark.parametrize("prefix", ["Wes", "'Wes", '"Wes"'])
def test_restore_completion_replaces_user_quotes_with_one_xonsh_argument(
    clanker_input, tmp_path, monkeypatch, prefix
):
    from clanker_saved import SavedConversations

    shell, _ = clanker_input
    title = """Wes's "notes" on Python"""
    monkeypatch.setattr(SavedConversations, "list", lambda self: [{"title": title}])
    line = "clank manage restore " + prefix
    candidates, _ = Completer().complete_line(line)
    completion = next(item for item in candidates if getattr(item, "provider", "") == "clanker")
    source = line[:-completion.prefix_len] + str(completion)
    received = []
    shell.aliases["clank"] = lambda args: received.append(args)
    shell.execer.exec(source + "\n", glbs=shell.ctx)
    assert received == [["manage", "restore", title]]


def test_clanker_alias_deletes_by_restore_fragment(clanker_input, capsys):
    from langchain_core.messages import HumanMessage

    import clanker_mode
    from clanker_saved import SavedConversations
    from clanker_session import get_session

    shell, _ = clanker_input
    session = get_session(shell, clanker_mode.TRACE_DIR)
    session.add_message(HumanMessage("test message"))
    old_trace = session.path
    saved = SavedConversations(clanker_mode.SAVED_DIR)
    saved.save(session, "shell experiments")
    shell.execer.exec("clanker manage delete experiments\n", glbs=shell.ctx)
    assert "Deleted Clanker snapshot and trace" in capsys.readouterr().out
    assert not old_trace.exists() and not saved.list()
