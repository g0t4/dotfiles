import json
import os
import threading
from uuid import uuid4

import pytest
from langchain_core.messages import AIMessage

from clanker_mode import clank, make_shell_tool, run_agent
from trace_test_helpers import message_bodies, read_records


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
    (path,) = tmp_path.glob("*.jsonl")
    records = read_records(path)
    messages = message_bodies(records)
    assert records[0]["type"] == "version"
    assert records[0]["version"] == 1
    assert records[1]["trace_type"] == "clanker_mode"
    assert [m["role"] for m in messages] == [
        "system",
        "user",
        "assistant",
        "tool",
        "assistant",
    ]
    assert (
        messages[2]["tool_calls"][0]["function"]["name"] == "execute_in_current_xonsh"
    )
    assert path.stat().st_mode & 0o777 == 0o600
    assert clank.__xonsh_threadable__ is False


def test_interruption_trace(shell, tmp_path):
    class Model:
        def bind_tools(self, tools):
            raise KeyboardInterrupt()

    with pytest.raises(KeyboardInterrupt):
        run_agent("help", shell, model=Model(), trace_dir=tmp_path)
    records = read_records(next(tmp_path.glob("*.jsonl")))
    error = next(record for record in records if record["type"] == "error")
    assert error["error"] == {"class": "KeyboardInterrupt", "message": ""}
    assert records[-1]["status"] == "interrupted"


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
    messages = message_bodies(read_records(next(tmp_path.glob("*.jsonl"))))
    assert any(
        message["role"] == "tool" and hidden in message["content"]
        for message in messages
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
                if len(requests) == 2:
                    assert request["messages"][-1]["content"].strip() == hidden
                else:
                    previous = requests[1]["messages"]
                    assert request["messages"][: len(previous)] == previous
                    assert request["messages"][-2]["content"] == hidden
                    assert request["messages"][-1]["content"] == "follow-up"
                    assert all(
                        "metadata" not in m and "response_metadata" not in m
                        for m in request["messages"]
                    )
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
        assert (
            run_agent("follow-up", shell, model=get_model(shell), trace_dir=tmp_path)
            == hidden
        )
        assert len(requests) == 3
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


def test_agent_queues_command_without_running_it(shell, tmp_path):
    command = "clanker_suggestion_was_executed = True"

    class Model:
        def bind_tools(self, tools):
            assert len(tools) == 1  # Helper uses the existing execution tool.
            return self

        def invoke(self, messages):
            assert "from clanker_mode import replace_commandline" in messages[0].content
            if messages[-1].type == "human":
                return AIMessage(
                    content="",
                    tool_calls=[
                        {
                            "name": "execute_in_current_xonsh",
                            "args": {
                                "code": f"from clanker_mode import replace_commandline\nprint(replace_commandline({command!r}))"
                            },
                            "id": "suggest",
                            "type": "tool_call",
                        }
                    ],
                )
            assert "not executed" in messages[-1].content
            return AIMessage(content="Ready to edit.")

    assert (
        run_agent("Suggest a command", shell, model=Model(), trace_dir=tmp_path)
        == "Ready to edit."
    )
    assert shell.env["XONSH_PROMPT_NEXT_CMD"] == command
    assert "clanker_suggestion_was_executed" not in shell.ctx


@pytest.mark.parametrize(
    "command, expected, cursor",
    [
        ("suggestion_ran = True", "suggestion_ran = True", 21),
        ('print(<cursor>"hello")', 'print("hello")', 6),
        ("x = 1\nprint(x)", "x = 1\nprint(x)", 14),
    ],
)
def test_next_prompt_contains_editable_suggestion(shell, command, expected, cursor):
    from prompt_toolkit.input import create_pipe_input
    from prompt_toolkit.output import DummyOutput
    from prompt_toolkit.shortcuts import PromptSession
    from xonsh.shells.ptk_shell import PromptToolkitShell

    from clanker_mode import replace_commandline

    shell.env["ENABLE_ASYNC_PROMPT"] = False
    ptk_shell = PromptToolkitShell(execer=shell.execer, ctx=shell.ctx)
    with create_pipe_input() as pipe:
        ptk_shell.prompter = PromptSession(input=pipe, output=DummyOutput())
        replace_commandline("old suggestion")
        replace_commandline(command)
        # Interrupt the real input prompt instead of submitting the suggestion.
        pipe.send_text("\x03")
        with pytest.raises(KeyboardInterrupt):
            ptk_shell.singleline()
        buffer = ptk_shell.prompter.default_buffer
        assert buffer.text == expected
        assert buffer.cursor_position == cursor
        assert not shell.env["XONSH_PROMPT_NEXT_CMD"]
        assert "suggestion_ran" not in shell.ctx
        # Xonsh consumed the setting once; subsequent prompts start empty.
        pipe.send_text("\r")
        assert ptk_shell.singleline() == ""


@pytest.mark.parametrize(
    "value, error", [("", ValueError), ("  ", ValueError), (None, TypeError)]
)
def test_invalid_suggestion_preserves_queued_command(shell, value, error):
    from clanker_mode import replace_commandline

    replace_commandline("echo original")
    with pytest.raises(error):
        replace_commandline(value)
    assert shell.env["XONSH_PROMPT_NEXT_CMD"] == "echo original"


def test_alias_suppresses_only_known_import_warning_and_restores_filters(
    shell, monkeypatch
):
    import sys
    import warnings
    from pathlib import Path
    from types import ModuleType

    root = Path(__file__).resolve().parents[2]
    monkeypatch.syspath_prepend(str(root / ".config/xonsh/lib"))
    shell.ctx.update(
        XONSH_LIB=root / ".config/xonsh/lib", sys=sys, aliases=shell.aliases
    )
    shell.execer.exec(
        (root / ".config/xonsh/rc.d/clanker-mode.xsh").read_text(), glbs=shell.ctx
    )
    message = "'asyncio.iscoroutinefunction' is deprecated and slated for removal in Python 3.16; use inspect.iscoroutinefunction() instead"
    module = "langsmith._internal._beta_decorator"
    fake = ModuleType("clanker_mode")

    def get_attribute(name):
        if name != "clank":
            raise AttributeError(name)
        warnings.warn_explicit(
            message, DeprecationWarning, "probe.py", 1, module=module
        )
        warnings.warn_explicit(
            "unrelated deprecation", DeprecationWarning, "probe.py", 2, module=module
        )
        warnings.warn_explicit(
            message, DeprecationWarning, "probe.py", 3, module="another_module"
        )
        warnings.warn_explicit(message, UserWarning, "probe.py", 4, module=module)
        return lambda *args, **kwargs: 0

    fake.__getattr__ = get_attribute
    monkeypatch.setitem(sys.modules, "clanker_mode", fake)
    with warnings.catch_warnings(record=True) as observed:
        warnings.simplefilter("always")
        original_filters = list(warnings.filters)
        assert shell.aliases["clank"](["--help"]) == 0
        assert warnings.filters == original_filters
        assert len(observed) == 3
        assert str(observed[0].message) == "unrelated deprecation"
        assert observed[1].category is DeprecationWarning
        assert observed[2].category is UserWarning
        # The identical warning is visible again after the import scope ends.
        warnings.warn_explicit(
            message, DeprecationWarning, "probe.py", 5, module=module
        )
        assert len(observed) == 4


def test_agent_cat_bypasses_interactive_alias_and_restores_it(shell, tmp_path):
    calls = []

    def interactive_cat(args, stdout=None):
        calls.append(args)
        print("\x1b[31minteractive override\x1b[0m", file=stdout)

    shell.aliases["cat"] = {"alias": interactive_cat, "doc": "My interactive cat"}
    original = shell.aliases["cat"]
    path = tmp_path / "plain.txt"
    path.write_text("plain agent input\n")
    shell.ctx["cat_test_path"] = str(path)
    tool = make_shell_tool(shell)
    result = tool.invoke({"code": "print($(cat @(cat_test_path)))"})
    assert "plain agent input" in result
    assert "\x1b" not in result
    assert calls == []
    assert shell.aliases["cat"] is original
    assert shell.aliases.get_doc("cat") == "My interactive cat"
    error_output = tool.invoke(
        {
            "code": 'from xonsh.built_ins import XSH\nassert "cat" not in XSH.aliases\n1 / 0'
        }
    )
    assert "ZeroDivisionError" in error_output
    assert shell.aliases["cat"] is original
    with pytest.raises(KeyboardInterrupt):
        tool.invoke({"code": "raise KeyboardInterrupt()"})
    assert shell.aliases["cat"] is original
    # A real command after the tool still uses the user's original alias.
    shell.execer.exec("cat ignored\n", glbs=shell.ctx)
    assert calls == [["ignored"]]


@pytest.mark.parametrize("failure", [ValueError, KeyboardInterrupt])
def test_alias_scope_restores_after_failure_and_keeps_unrelated_changes(shell, failure):
    from clanker_mode import alias_scope

    shell.aliases["cat"] = ["bat", "--color=always"]
    original = shell.aliases["cat"]
    with (
        pytest.raises(failure),
        alias_scope(shell.aliases, {"cat": None, "scoped_new": ["echo", "temporary"]}),
    ):
        assert "cat" not in shell.aliases
        shell.aliases["unrelated_new"] = ["echo", "persistent"]
        raise failure("probe")
    assert shell.aliases["cat"] is original
    assert "scoped_new" not in shell.aliases
    assert shell.aliases["unrelated_new"] == ["echo", "persistent"]


def test_alias_scope_restores_missing_cat_and_supports_nested_scopes(shell):
    from clanker_mode import alias_scope

    if "cat" in shell.aliases:
        del shell.aliases["cat"]
    with alias_scope(shell.aliases, {"cat": None}):
        with alias_scope(shell.aliases, {"cat": ["echo", "nested"]}):
            assert shell.aliases["cat"] == ["echo", "nested"]
        assert "cat" not in shell.aliases
        shell.aliases["cat"] = ["echo", "temporary mutation"]
    assert "cat" not in shell.aliases
