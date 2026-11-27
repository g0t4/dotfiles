import asyncio

from langchain_core.messages import AIMessage

from clanker_steering import TerminalSteering, steering_message


def test_steering_message_preserves_submission_order():
    assert steering_message(["first", "second"]).endswith("1. first\n2. second")


def test_ctrl_d_during_inference_waits_for_model_and_requests_repl_exit():
    class Model:
        async def ainvoke(self, messages):
            await asyncio.sleep(0)
            return AIMessage(content="finished")

    class Input:
        async def prompt_async(self, *args, **kwargs):
            raise EOFError

    steering = TerminalSteering()
    steering.session = Input()
    answer, queued = steering.invoke(Model(), [])
    steering.close()

    assert answer.content == "finished"
    assert queued == []
    assert steering.exit_requested is True


def test_model_rounds_share_one_event_loop_until_steering_closes():
    class Model:
        loop = None

        async def ainvoke(self, messages):
            running = asyncio.get_running_loop()
            if self.loop is None:
                self.loop = running
            assert running is self.loop
            return AIMessage(content="finished")

    class Input:
        async def prompt_async(self, *args, **kwargs):
            await asyncio.Event().wait()

    steering = TerminalSteering()
    steering.session = Input()
    model = Model()

    first, _ = steering.invoke(model, [])
    second, _ = steering.invoke(model, [])
    steering.close()

    assert first.content == "finished"
    assert second.content == "finished"
    assert steering.loop.is_closed()


def test_separate_turn_prompts_share_session_loop_without_closing_it():
    class Session:
        pass

    class Input:
        async def prompt_async(self, *args, **kwargs):
            await asyncio.Event().wait()

    class Model:
        expected_loop = None

        async def ainvoke(self, messages):
            running = asyncio.get_running_loop()
            if Model.expected_loop is None:
                Model.expected_loop = running
            assert running is Model.expected_loop
            return AIMessage(content="finished")

    session = Session()
    for _ in range(2):
        steering = TerminalSteering.for_session(session)
        steering.session = Input()
        answer, _ = steering.invoke(Model(), [])
        steering.close()
        assert answer.content == "finished"
        assert steering.loop.is_closed() is False

    session._clanker_steering_loop.close()


def test_unsubmitted_text_carries_to_the_next_steering_prompt():
    class Buffer:
        text = "keep this partial thought"

    class App:
        current_buffer = Buffer()

    class Input:
        app = App()

        def __init__(self):
            self.defaults = []

        async def prompt_async(self, *args, **kwargs):
            self.defaults.append(kwargs["default"])
            await asyncio.Event().wait()

    class Model:
        async def ainvoke(self, messages):
            return AIMessage(content="finished")

    steering = TerminalSteering()
    steering.session = Input()
    model = Model()

    steering.invoke(model, [])
    assert steering.unsent_text == "keep this partial thought"
    steering.invoke(model, [])
    steering.close()

    assert steering.session.defaults == ["", "keep this partial thought"]


def test_real_ctrl_c_cancels_model_and_leaves_loop_ready_for_next_turn():
    import pytest
    from prompt_toolkit.input import create_pipe_input
    from prompt_toolkit.output import DummyOutput

    class Model:
        cancelled = False

        async def ainvoke(self, messages):
            try:
                await asyncio.Event().wait()
            finally:
                self.cancelled = True

    with create_pipe_input() as pipe:
        steering = TerminalSteering(input=pipe, output=DummyOutput())
        model = Model()
        pipe.send_bytes(b"\x03")
        try:
            with pytest.raises(KeyboardInterrupt):
                steering.invoke(model, [])
            assert model.cancelled
            assert not asyncio.all_tasks(steering.loop)
            steering.loop.run_until_complete(asyncio.sleep(0))
        finally:
            steering.close()


def test_exit_request_suppresses_prompts_in_later_tool_rounds():
    class Model:
        async def ainvoke(self, messages):
            return AIMessage(content="next round")

    class Input:
        async def prompt_async(self, *args, **kwargs):
            raise AssertionError("prompt reopened after EOF")

    steering = TerminalSteering()
    steering.session = Input()
    steering.exit_requested = True
    try:
        assert steering.invoke(Model(), [])[0].text == "next round"
    finally:
        steering.close()


def test_voice_final_at_model_boundary_reaches_unsubmitted_draft():
    from types import SimpleNamespace

    started = asyncio.Event()
    steering = TerminalSteering()
    buffer = SimpleNamespace(text="")

    class Input:
        app = SimpleNamespace(current_buffer=buffer)

        async def prompt_async(self, *args, **kwargs):
            steering.voice.finished = asyncio.get_running_loop().create_future()
            started.set()
            await asyncio.Event().wait()

    class Model:
        async def ainvoke(self, messages):
            await started.wait()

            def finish_dictation():
                buffer.text = "spoken draft"
                steering.voice.finished.set_result(None)

            asyncio.get_running_loop().call_later(0.02, finish_dictation)
            return AIMessage(content="done")

    steering.session = Input()
    try:
        answer, queued = steering.invoke(Model(), [])
        assert answer.text == "done" and not queued
        assert steering.unsent_text == "spoken draft"
    finally:
        steering.close()


def test_steering_input_survives_preview_redraw_and_ctrl_c_closes_stream():
    import io

    import pytest
    from langchain_core.messages import AIMessageChunk
    from prompt_toolkit.input import create_pipe_input
    from prompt_toolkit.output import DummyOutput
    from rich.console import Console

    from clanker_display import TurnDisplay
    from clanker_stream import StreamingRound

    with create_pipe_input() as pipe:
        steering = TerminalSteering(input=pipe, output=DummyOutput())
        closed = False

        class Model:
            async def astream(self, messages):
                nonlocal closed
                try:
                    yield AIMessageChunk(content="live text")
                    assert "live text" in steering.preview
                    pipe.send_text("unfinished")
                    async with asyncio.timeout(2):
                        while steering.session.app.current_buffer.text != "unfinished":
                            await asyncio.sleep(0.01)
                    yield AIMessageChunk(
                        content="",
                        tool_call_chunks=[
                            {"index": 0, "name": "tool", "args": "{", "id": "one"}
                        ],
                    )
                    assert "tool {" in steering.preview
                    assert steering.session.app.current_buffer.text == "unfinished"
                    pipe.send_bytes(b"\x03")
                    await asyncio.Event().wait()
                finally:
                    closed = True

        try:
            with TurnDisplay(Console(file=io.StringIO())) as display:
                display.steering = steering
                traces = []
                model = StreamingRound(
                    Model(), lambda msg: display("assistant_partial", msg), traces.append
                )
                with pytest.raises(KeyboardInterrupt):
                    steering.invoke(model, [])
            assert closed and steering.preview == ""
            assert [trace.outcome for trace in traces] == ["cancelled"]
            assert traces[0].client_timing.ended_at is not None
        finally:
            steering.close()


def test_submissions_appear_in_scrollback_while_model_is_still_running():
    import io

    from prompt_toolkit.input import create_pipe_input
    from prompt_toolkit.output import DummyOutput
    from rich.console import Console

    from clanker_display import TurnDisplay

    output = io.StringIO()
    display = TurnDisplay(Console(file=output))
    updates = ["[red]inspect first[/red]", "then summarize"]
    with create_pipe_input() as pipe:
        steering = TerminalSteering(
            input=pipe, output=DummyOutput(), on_queued=display.show_queued
        )

        class Model:
            async def ainvoke(self, messages):
                async with asyncio.timeout(2):
                    for text in updates:
                        pipe.send_text(text + "\n")
                        while f"Queued › {text}\n" not in output.getvalue():
                            await asyncio.sleep(0.01)
                return AIMessage(content="done")

        try:
            _, queued = steering.invoke(Model(), [])
        finally:
            steering.close()
    assert queued == updates
    assert output.getvalue().splitlines() == [f"Queued › {text}" for text in updates]
