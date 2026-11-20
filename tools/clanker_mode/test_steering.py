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

    assert answer.content == "finished"
    assert queued == []
    assert steering.exit_requested is True
