import sys
from pathlib import Path

import pytest
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
        (root / ".config/xonsh/rc.d/clanker-mode.xsh").read_text(), glbs=shell.ctx
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
