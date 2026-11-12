import json
import os
import threading
from uuid import uuid4

import pytest
from langchain_core.messages import AIMessage

from clanker_mode import clank, make_shell_tool, run_agent


def test_live_namespace_and_xonsh_syntax(shell):
    shell.env["CLANKER_TEST_VALUE"] = uuid4().hex
    shell.ctx["hidden_python_value"] = uuid4().hex
    tool = make_shell_tool(shell)
    result = tool.invoke(
        {
            "code": 'from xonsh.built_ins import XSH\nprint(XSH.env["CLANKER_TEST_VALUE"])\nprint(hidden_python_value)\n$CLANKER_CHANGED = "yes"\nclanker_pid = __import__("os").getpid()'
        }
    )
    assert shell.env["CLANKER_TEST_VALUE"] in result
    assert shell.ctx["hidden_python_value"] in result
    assert shell.env["CLANKER_CHANGED"] == "yes"
    assert shell.ctx["clanker_pid"] == os.getpid()
    assert "ZeroDivisionError" in tool.invoke({"code": "1/0"})
    assert "recovered" in tool.invoke({"code": 'print("recovered")'})


def test_agent_tool_roundtrip_and_trace(shell, tmp_path):
    from xonsh.history.dummy import DummyHistory

    shell.history = DummyHistory()
    caller = threading.get_ident()

    class Model:
        calls = 0

        def bind_tools(self, tools):
            assert len(tools) == 1
            return self

        def invoke(self, messages):
            assert threading.get_ident() == caller
            assert (
                "history backend is xonsh.history.dummy.DummyHistory"
                in messages[0].content
            )
            self.calls += 1
            if self.calls == 1:
                return AIMessage(
                    content="",
                    tool_calls=[
                        {
                            "name": "execute_in_current_xonsh",
                            "args": {
                                "code": 'clanker_thread = __import__("threading").get_ident()\nprint("tool success")'
                            },
                            "id": "call1",
                            "type": "tool_call",
                        }
                    ],
                )
            assert messages[-1].content == "tool success\n"
            return AIMessage(content="done")

    assert run_agent("help", shell, model=Model(), trace_dir=tmp_path) == "done"
    assert shell.ctx["clanker_thread"] == caller
    (path,) = tmp_path.glob("*-trace.json")
    trace = json.loads(path.read_text())
    assert trace["trace_type"] == "clanker_mode"
    assert [m["role"] for m in trace["messages"]] == [
        "system",
        "user",
        "assistant",
        "tool",
        "assistant",
    ]
    assert (
        trace["messages"][2]["tool_calls"][0]["function"]["name"]
        == "execute_in_current_xonsh"
    )
    assert path.stat().st_mode & 0o777 == 0o600
    assert clank.__xonsh_threadable__ is False


def test_interruption_trace(shell, tmp_path):
    class Model:
        def bind_tools(self, tools):
            raise KeyboardInterrupt()

    with pytest.raises(KeyboardInterrupt):
        run_agent("help", shell, model=Model(), trace_dir=tmp_path)
    trace = json.loads(next(tmp_path.glob("*.json")).read_text())
    assert trace["error"] == "KeyboardInterrupt: "


@pytest.mark.live
@pytest.mark.skipif(
    os.environ.get("CLANKER_LIVE_TEST") != "1", reason="opt-in live model"
)
def test_live_model_discovers_hidden_shell_value(shell, tmp_path):
    hidden = uuid4().hex
    shell.env["CLANKER_INTEGRATION_HIDDEN"] = hidden
    answer = run_agent(
        'Use your tool to read XSH.env["CLANKER_INTEGRATION_HIDDEN"]. Reply with its exact value.',
        shell,
        trace_dir=tmp_path,
    )
    assert hidden in answer
    trace = json.loads(next(tmp_path.glob("*.json")).read_text())
    assert any(
        message["role"] == "tool" and hidden in message["content"]
        for message in trace["messages"]
    )


def test_provider_http_tool_roundtrip(shell, tmp_path):
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    from clanker_mode import get_model

    hidden = uuid4().hex
    shell.env["CLANKER_INTEGRATION_HIDDEN"] = hidden
    requests = []

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def do_GET(self):
            body = json.dumps({"data": [{"id": "test", "owned_by": "vllm"}]}).encode()
            assert self.path == "/v1/models"
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            request = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            requests.append(request)
            assert request["model"] == "test"
            if len(requests) == 1:
                assert (
                    request["tools"][0]["function"]["name"]
                    == "execute_in_current_xonsh"
                )
                message = {
                    "role": "assistant",
                    "content": None,
                    "tool_calls": [
                        {
                            "id": "http-call",
                            "type": "function",
                            "function": {
                                "name": "execute_in_current_xonsh",
                                "arguments": json.dumps(
                                    {
                                        "code": 'from xonsh.built_ins import XSH\nprint(XSH.env["CLANKER_INTEGRATION_HIDDEN"])'
                                    }
                                ),
                            },
                        }
                    ],
                }
                reason = "tool_calls"
            else:
                assert request["messages"][-1]["content"].strip() == hidden
                message = {"role": "assistant", "content": hidden}
                reason = "stop"
            body = json.dumps(
                {
                    "id": "test",
                    "object": "chat.completion",
                    "created": 1,
                    "model": "test",
                    "choices": [
                        {"index": 0, "message": message, "finish_reason": reason}
                    ],
                }
            ).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever)
    thread.start()
    try:
        shell.env["CLANKER_BASE_URL"] = f"http://127.0.0.1:{server.server_port}/v1"
        shell.env.pop("CLANKER_MODEL", None)
        assert (
            run_agent(
                "find hidden value", shell, model=get_model(shell), trace_dir=tmp_path
            )
            == hidden
        )
        assert len(requests) == 2
    finally:
        server.shutdown()
        thread.join()
        server.server_close()


def test_registered_alias_dispatches_inside_shell(shell, monkeypatch, capsys):
    import sys
    from pathlib import Path

    import clanker_mode

    root = Path(__file__).resolve().parents[2]
    monkeypatch.syspath_prepend(str(root / ".config/xonsh/lib"))
    from wes_abbreviations import XONSH_ABBREVIATIONS

    shell.ctx.update(
        XONSH_LIB=root / ".config/xonsh/lib", sys=sys, aliases=shell.aliases
    )
    shell.execer.exec(
        (root / ".config/xonsh/rc.d/clanker-mode.xsh").read_text(), glbs=shell.ctx
    )
    caller = threading.get_ident()

    def agent(prompt, xsh):
        assert xsh is shell
        assert threading.get_ident() == caller
        assert prompt == "inspect shell"
        xsh.ctx["alias_was_here"] = True
        return "alias worked"

    monkeypatch.setattr(clanker_mode, "run_agent", agent)
    shell.execer.exec('clank "inspect shell"\n', glbs=shell.ctx)
    assert shell.ctx["alias_was_here"] is True
    assert "alias worked" in capsys.readouterr().out
    assert shell.aliases["clank"].__xonsh_threadable__ is False
    assert any(
        ab.trigger == "c" and ab.replacement == "clank"
        for ab in XONSH_ABBREVIATIONS.abbreviations
    )


def test_terminal_answer_uses_markdown_palette(monkeypatch):
    import io

    import rich.console

    import clanker_mode

    real_console = rich.console.Console
    monkeypatch.setattr(
        rich.console,
        "Console",
        lambda **kwargs: real_console(
            **kwargs,
            force_terminal=True,
            color_system="truecolor",
            no_color=False,
            width=100,
        ),
    )
    monkeypatch.setattr(
        clanker_mode,
        "run_agent",
        lambda *args: "# Shell state\n\n`XSH.env` contains **typed values**.",
    )
    output = io.StringIO()
    assert clanker_mode.clank(["help"], stdout=output) == 0
    rendered = output.getvalue()
    assert "\x1b[" in rendered
    assert "# " in rendered
    assert "XSH.env" in rendered
    assert "**" in rendered


def test_redirected_answer_preserves_source(monkeypatch):
    import io

    import clanker_mode

    answer = "# Output\n\n```python\n" + 'x = "' + "long value " * 30 + '"\n```'
    monkeypatch.setattr(clanker_mode, "run_agent", lambda *args: answer)
    output = io.StringIO()
    assert clanker_mode.clank(["help"], stdout=output) == 0
    assert output.getvalue() == answer + "\n"


@pytest.mark.parametrize(
    "models, expected",
    [
        ([{"id": "deepseek-v4.1-flash", "owned_by": "vllm"}], "deepseek-v4.1-flash"),
        (
            [
                {"id": "other", "status": {"value": "unloaded"}},
                {"id": "deepseek", "status": {"value": "loaded"}},
            ],
            "deepseek",
        ),
    ],
)
def test_model_discovery_selection(models, expected):
    from clanker_mode import select_model

    assert select_model(models) == expected


@pytest.mark.parametrize(
    "models",
    [
        [],
        [{"id": "a"}, {"id": "b"}],
        [
            {"id": "a", "status": {"value": "loaded"}},
            {"id": "b", "status": {"value": "loaded"}},
        ],
    ],
)
def test_ambiguous_model_requires_override(models):
    from clanker_mode import select_model

    with pytest.raises(ValueError, match="CLANKER_MODEL"):
        select_model(models)
