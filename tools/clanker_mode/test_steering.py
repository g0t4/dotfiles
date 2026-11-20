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
