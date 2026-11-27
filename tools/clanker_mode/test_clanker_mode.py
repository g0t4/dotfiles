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
            assert {tool["function"]["name"] for tool in tools} == {
                "execute_in_current_xonsh",
                "apply_patch",
                "rollback_turn",
            }
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
def test_live_model_reads_shell_inventory(shell, tmp_path):
    count = str(10000 + uuid4().int % 90000)
    shell.env["CLANKER_TEST_APPLE_COUNT"] = count
    answer = run_agent(
        'How many apples are in the test inventory? Use your shell tool to read XSH.env["CLANKER_TEST_APPLE_COUNT"]. Reply with the count as digits.',
        shell,
        trace_dir=tmp_path,
    )
    assert count in answer.replace(",", "")
    messages = message_bodies(read_records(next(tmp_path.glob("*.jsonl"))))
    assert any(
        message["role"] == "tool" and count in message["content"]
        for message in messages
    )


@pytest.mark.parametrize("asynchronous", [False, True])
@pytest.mark.parametrize("streaming", [False, True])
def test_provider_requests_streaming_usage(shell, asynchronous, streaming):
    import asyncio

    import httpx

    from clanker_mode import get_model

    shell.env["CLANKER_PROFILE"] = "deepseek"
    shell.env["CLANKER_MODEL"] = "test"
    shell.env["CLANKER_BASE_URL"] = "http://backend.invalid/v1"
    requests = []
    diagnostics = {
        "metrics": {
            "time_to_first_token_ms": 123.5,
            "speculative_decoding": {"mean_acceptance_length": 4.2},
        },
        "timings": {"choices": [{"decode_time": 0.25}]},
        "sglext": {"spec_tokens_details": {"spec_accept_rate": 0.8}},
    }

    def respond(request):
        requests.append(json.loads(request.content))
        chunks = [
            {
                "id": "test",
                "object": "chat.completion.chunk",
                "created": 1,
                "model": "test",
                "choices": [
                    {
                        "index": 0,
                        "delta": {"role": "assistant", "content": "hello"},
                        "finish_reason": "stop",
                    }
                ],
            },
            {
                "id": "test",
                "object": "chat.completion.chunk",
                "created": 1,
                "model": "test",
                "choices": [],
                "usage": {
                    "prompt_tokens": 10,
                    "completion_tokens": 2,
                    "total_tokens": 12,
                },
            },
        ]
        chunks[-1].update(diagnostics)
        if not streaming:
            return httpx.Response(
                200,
                json={
                    **chunks[0],
                    **diagnostics,
                    "object": "chat.completion",
                    "choices": [
                        {
                            "index": 0,
                            "message": {"role": "assistant", "content": "hello"},
                            "finish_reason": "stop",
                        }
                    ],
                    "usage": chunks[-1]["usage"],
                },
            )
        content = "".join(f"data: {json.dumps(chunk)}\n\n" for chunk in chunks)
        return httpx.Response(
            200,
            headers={"Content-Type": "text/event-stream"},
            content=content + "data: [DONE]\n\n",
        )

    model = get_model(shell)
    transport = httpx.MockTransport(respond)
    if asynchronous:

        async def collect():
            async with httpx.AsyncClient(transport=transport) as client:
                model.root_async_client = model.root_async_client.with_options(
                    http_client=client
                )
                model.async_client = model.root_async_client.chat.completions
                if streaming:
                    return [chunk async for chunk in model.astream("hello")]
                return [await model.ainvoke("hello")]

        chunks = asyncio.run(collect())
    else:
        with httpx.Client(transport=transport) as client:
            model.root_client = model.root_client.with_options(http_client=client)
            model.client = model.root_client.chat.completions
            chunks = (
                list(model.stream("hello")) if streaming else [model.invoke("hello")]
            )
    assert len(requests) == 1
    assert requests[0].get("stream", False) is streaming
    if streaming:
        assert requests[0]["stream_options"]["include_usage"] is True
    assert requests[0]["return_timings"] is True
    usage = next(chunk.usage_metadata for chunk in chunks if chunk.usage_metadata)
    assert {
        key: usage[key] for key in ("input_tokens", "output_tokens", "total_tokens")
    } == {
        "input_tokens": 10,
        "output_tokens": 2,
        "total_tokens": 12,
    }
    from langchain_core.messages import message_chunk_to_message

    from clanker_session import serialize_message

    answer = chunks[0]
    for chunk in chunks[1:]:
        answer += chunk
    if streaming:
        answer = message_chunk_to_message(answer)
    body, metadata = serialize_message(answer)
    for field, value in diagnostics.items():
        raw = metadata["response"]
        payload = raw["raw_chunks"][-1] if streaming else raw["raw_response"]
        assert payload[field] == value
        assert field not in body


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
            assert request["return_timings"] is True
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
            assert request["stream"] is True
            if calls := message.get("tool_calls"):
                calls[0]["index"] = 0
            deltas = [{"reasoning_content": "checking"}, message, {}]
            frames = [
                {
                    "id": "test",
                    "object": "chat.completion.chunk",
                    "created": 1,
                    "model": "test",
                    "choices": [
                        {
                            "index": 0,
                            "delta": delta,
                            "finish_reason": reason if not delta else None,
                        }
                    ],
                }
                for delta in deltas
            ]
            body = (
                "".join(f"data: {json.dumps(frame)}\n\n" for frame in frames)
                + "data: [DONE]\n\n"
            ).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever)
    thread.start()
    try:
        shell.env["CLANKER_PROFILE"] = "deepseek"
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
        from langchain_openai_compatible import AccumulatedCompletion

        records = read_records(next(tmp_path.glob("*.jsonl")))
        rounds = [r for r in records if r["type"] == "model_round"]
        assert [(r["turn_id"], r["round"]) for r in rounds] == [(1, 1), (1, 2), (2, 1)]
        for record in rounds:
            completion = AccumulatedCompletion.model_validate(record["completion"])
            assert len(completion.raw_chunks) == len(completion.client_timing.event_offsets_ms) == 3
        assert "raw_chunks" not in json.dumps(requests)
        tool_records = [
            record
            for path in tmp_path.glob("*.jsonl")
            for record in read_records(path)
            if record["type"] == "tools"
        ]
        assert len(tool_records) == 1
        assert all(request["tools"] == tool_records[0]["tools"] for request in requests)
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
        (root / ".config/xonsh/rc.d/clanker-mode.py").read_text(), glbs=shell.ctx
    )
    caller = threading.get_ident()

    def agent(prompt, xsh, **kwargs):
        assert xsh is shell
        assert threading.get_ident() == caller
        assert prompt == "inspect shell and explain $PATH | cat > out"
        xsh.ctx["alias_was_here"] = True
        return "alias worked"

    monkeypatch.setattr(clanker_mode, "run_agent", agent)
    shell.execer.exec("clank! inspect shell and explain $PATH | cat > out\n", glbs=shell.ctx)
    assert shell.ctx["alias_was_here"] is True
    assert "alias worked" in capsys.readouterr().out
    assert shell.aliases["clank"].__xonsh_threadable__ is False
    assert "clanker" in shell.completers
    assert any(
        ab.trigger == "c" and ab.replacement == "clank!"
        for ab in XONSH_ABBREVIATIONS.abbreviations
    )
    assert any(
        ab.trigger == "cm" and ab.replacement == "clank manage"
        for ab in XONSH_ABBREVIATIONS.abbreviations
    )


def test_terminal_answer_uses_markdown_palette(monkeypatch):
    import io

    import clanker_display
    import clanker_mode

    real_console = clanker_display.TerminalConsole
    monkeypatch.setattr(
        clanker_display,
        "TerminalConsole",
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
        lambda *args, **kwargs: "# Shell state\n\n`XSH.env` contains **typed values**.",
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
    monkeypatch.setattr(clanker_mode, "run_agent", lambda *args, **kwargs: answer)
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
            assert {tool["function"]["name"] for tool in tools} == {
                "execute_in_current_xonsh",
                "apply_patch",
                "rollback_turn",
            }
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
        (root / ".config/xonsh/rc.d/clanker-mode.py").read_text(), glbs=shell.ctx
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


@pytest.mark.parametrize("capture_always", [False, True])
@pytest.mark.parametrize("threaded", [False, True])
@pytest.mark.parametrize("kind", ["external", "python-child", "raw-fd", "alias"])
def test_tool_captures_output_paths(
    shell, tmp_path, capfd, threaded, kind, capture_always
):
    import sys

    shell.env["THREAD_SUBPROCS"] = threaded
    shell.env["XONSH_CAPTURE_ALWAYS"] = capture_always
    script = tmp_path / "emit.py"
    script.write_text(
        "import os\nos.write(1, b'child-out\\n')\nos.write(2, b'child-err\\n')\n"
    )
    if kind == "external":
        code = f"clanker_cmd = {[sys.executable, str(script)]!r}\n@(clanker_cmd)"
    elif kind == "python-child":
        code = (
            f"import subprocess\nsubprocess.run([{sys.executable!r}, {str(script)!r}])"
        )
    elif kind == "raw-fd":
        code = "import os\nos.write(1, b'child-out\\n')\nos.write(2, b'child-err\\n')"
    else:

        def emit(args, stdout=None, stderr=None):
            print("child-out", file=stdout)
            print("child-err", file=stderr)

        shell.aliases["clanker-emit"] = emit
        code = "clanker-emit"
    result = make_shell_tool(shell).invoke({"code": code})
    assert "child-out" in result
    assert "child-err" in result
    leaked = capfd.readouterr()
    assert "child-out" not in leaked.out
    assert "child-err" not in leaked.err


@pytest.mark.parametrize("failure", ["ValueError", "KeyboardInterrupt"])
def test_capture_restores_streams_after_failure(shell, capfd, failure):
    import sys

    original_title = shell.env["TITLE"]
    original_streams = (sys.stdout, sys.stderr)
    original_fds = [os.fstat(fd) for fd in (1, 2)]
    tool = make_shell_tool(shell)
    code = f"print('before failure')\nraise {failure}('test failure')"
    if failure == "KeyboardInterrupt":
        with pytest.raises(KeyboardInterrupt):
            tool.invoke({"code": code})
    else:
        result = tool.invoke({"code": code})
        assert "before failure" in result
        assert "ValueError: test failure" in result
    assert shell.env["TITLE"] == original_title
    assert (sys.stdout, sys.stderr) == original_streams
    for fd, original in zip((1, 2), original_fds):
        restored = os.fstat(fd)
        assert (restored.st_dev, restored.st_ino) == (original.st_dev, original.st_ino)
        os.write(fd, b"outside capture\n")
    leaked = capfd.readouterr()
    assert "outside capture" in leaked.out
    assert "outside capture" in leaked.err
    assert "before failure" not in leaked.out
    assert tool.invoke({"code": "print('next call')"}) == "next call\n"


def test_capture_large_output_and_mixed_write_order(shell, tmp_path):
    path = tmp_path / "large.txt"
    path.write_text("x" * (2 * 1024 * 1024))
    result = make_shell_tool(shell).invoke({"code": f"cat {str(path)!r}"})
    assert result == path.read_text()
    result = make_shell_tool(shell).invoke(
        {
            "code": (
                "import os, sys\n"
                "print('first', end='')\n"
                "os.write(1, b'-second')\n"
                "print('-third', file=sys.stderr)"
            )
        }
    )
    assert result == "first-second-third\n"


def test_apply_patch_tool_updates_and_adds_files(tmp_path):
    """apply_patch tool scoped to repo root: update and add work."""
    import subprocess

    from clanker_mode import apply_patch

    # Build a temp git repo so apply_patch is scoped to a real root.
    repo = tmp_path / "repo"
    repo.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.email", "t@t"], cwd=repo, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=repo, check=True, capture_output=True)
    (repo / "hello.txt").write_text("old line\n")

    # Patch: update hello.txt and add new.py
    patch = (
        "*** Begin Patch\n"
        "*** Update File: hello.txt\n"
        "@@\n"
        "-old line\n"
        "+new line\n"
        "*** Add File: new.py\n"
        "+print('hi')\n"
        "*** End Patch\n"
    )
    old_cwd = os.getcwd()
    os.chdir(repo)
    result = apply_patch.invoke({"patch": patch})
    os.chdir(old_cwd)

    assert (repo / "hello.txt").read_text() == "new line\n"
    assert (repo / "new.py").exists()
    assert "Success" in result or "Updated" in result


def test_patch_validates_all_destinations_before_changing_files(tmp_path, monkeypatch):
    from clanker_mode import apply_patch

    repo = tmp_path / "repo"
    repo.mkdir()
    monkeypatch.chdir(repo)
    (repo / "linked").symlink_to(tmp_path, target_is_directory=True)
    for destination in ["../other", "linked/other", str(tmp_path / "other")]:
        result = apply_patch.invoke({"patch": (
            "*** Begin Patch\n*** Add File: one\n+first\n"
            f"*** Update File: two\n*** Move to: {destination}\n-old\n+new\n*** End Patch"
        )})
        assert "outside patch root" in result
        assert not (repo / "one").exists()


def test_shell_tool_contains_python_system_exit(shell):
    tool = make_shell_tool(shell)
    assert "SystemExit: 2" in tool.invoke({"code": "raise SystemExit(2)"})
    assert tool.invoke({"code": "print('still running')"}) == "still running\n"
