import io

import pytest
from langchain_core.messages import AIMessage, ToolMessage
from rich.console import Console

from clanker_display import TurnDisplay, assistant_panel, tool_panel, tool_result_panel
from clanker_mode import run_agent
from trace_test_helpers import message_bodies, read_records


def render(panel, width=100):
    stream = io.StringIO()
    Console(file=stream, width=width, color_system=None).print(panel)
    return stream.getvalue()


def test_panels_show_literal_arguments_and_results_with_viewer_style():
    call = {
        "name": "execute_in_current_xonsh",
        "args": {
            "code": 'print("[red]literal[/red]")\nvalue = 42',
            "other": {"key": 1},
        },
    }
    rendered = render(tool_panel(call, 1, 3, 100))
    assert "Tool call 2/3" in rendered
    assert "execute_in_current_xonsh" in rendered
    assert "[red]literal[/red]" in rendered
    assert "value = 42" in rendered
    assert "other:" in rendered
    assert "├" not in rendered  # Indentation, like TreeWrapper.
    result = render(
        tool_result_panel(
            ToolMessage(
                content="[green]literal output[/green]", name="test", tool_call_id="1"
            ),
            100,
        )
    )
    assert "[green]literal output[/green]" in result
    assert "# Heading" in render(assistant_panel("# Heading", 100))


def test_progress_precedes_execution_and_does_not_enter_tool_results(
    shell, tmp_path, capsys
):
    events = []

    class Model:
        count = 0

        def bind_tools(self, tools):
            return self

        def invoke(self, messages):
            self.count += 1
            if self.count == 1:
                return AIMessage(
                    content="",
                    tool_calls=[
                        {
                            "id": str(i),
                            "type": "tool_call",
                            "name": "execute_in_current_xonsh",
                            "args": {
                                "code": f'display_probe = {i}\nprint("output {i}")'
                            },
                        }
                        for i in (1, 2)
                    ],
                )
            return AIMessage(content="finished")

    def observe(event, payload):
        events.append(event)
        print(f"UI EVENT: {event}")
        if event == "tool_start":
            assert shell.ctx.get("display_probe", 0) == payload["index"]
            assert payload["total"] == 2
        if event == "tool_result":
            assert payload.content == f"output {shell.ctx['display_probe']}\n"

    assert (
        run_agent("work", shell, model=Model(), trace_dir=tmp_path, on_event=observe)
        == "finished"
    )
    assert events == [
        "thinking",
        "assistant",
        "tool_start",
        "tool_result",
        "tool_start",
        "tool_result",
        "thinking",
        "assistant",
    ]
    (path,) = tmp_path.glob("*.jsonl")
    tools = [m for m in message_bodies(read_records(path)) if m["role"] == "tool"]
    assert [m["content"] for m in tools] == ["output 1\n", "output 2\n"]
    assert "UI EVENT: tool_start" in capsys.readouterr().out


@pytest.mark.parametrize("failure", [RuntimeError, KeyboardInterrupt])
def test_waiting_status_stops_on_failure(failure):
    class Waiting:
        started = False
        stopped = False

        def start(self):
            self.started = True

        def stop(self):
            self.stopped = True

    waiting = Waiting()

    class FakeConsole:
        def status(self, *args):
            return waiting

    with pytest.raises(failure), TurnDisplay(FakeConsole()) as display:
        display("thinking", None)
        display("thinking", None)
        assert waiting.started
        raise failure()
    assert waiting.stopped


def test_nonterminal_alias_has_no_progress_or_ansi(shell, monkeypatch):
    import clanker_mode

    output, errors = io.StringIO(), io.StringIO()

    def agent(prompt, xsh, on_event):
        assert on_event is None
        return "plain answer"

    monkeypatch.setattr(clanker_mode, "run_agent", agent)
    assert clanker_mode.clank(["help"], stdout=output, stderr=errors) == 0
    assert output.getvalue() == "plain answer\n"
    assert errors.getvalue() == ""


@pytest.mark.parametrize("width", [32, 80, 160, 241])
def test_content_sized_bubbles_use_centered_lane_and_visible_cell_width(width):
    from rich.cells import cell_len

    lane = min(width, 160)
    left = (width - lane) // 2
    short = render(assistant_panel("ok", width), width).splitlines()[0]
    assert len(short) - len(short.lstrip()) == left
    assert cell_len(short.strip()) == min(width, 50)

    text = "界" * 30
    result = ToolMessage(content=f"\x1b[31m{text}\x1b[0m", tool_call_id="1")
    lines = render(tool_result_panel(result, width), width).splitlines()
    assert cell_len(lines[0].rstrip()) == left + lane
    assert cell_len(lines[0].strip()) == min(68, width)
    assert all(cell_len(line) <= width and "\x1b" not in line for line in lines)
    assert "".join(lines).count("界") == 30


def test_console_tracks_output_pane_resize_despite_stale_env(monkeypatch):
    import os
    import termios

    from clanker_display import TerminalConsole

    monkeypatch.setenv("COLUMNS", "400")
    master, slave = os.openpty()
    try:
        with os.fdopen(slave, "w") as output:
            console = TerminalConsole(file=output)
            for width in (210, 42):
                termios.tcsetwinsize(output.fileno(), (24, width))
                assert console.width == width
    finally:
        os.close(master)
