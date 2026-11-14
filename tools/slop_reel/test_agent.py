"""Agent capability validation against actual decoded source frames."""

import json
from threading import Event

import pytest
from langchain_core.messages import AIMessage

from chat import Chat
from commands import Commands
from fixtures import generate
from video_tools import VideoTools


@pytest.fixture(scope="module")
def video(tmp_path_factory):
    return generate(tmp_path_factory.mktemp("agent-video")) / "one-black.mp4"


def test_tool_pagination_bounds_and_exact_frame_identity(video):
    access = VideoTools(video, Commands(), Event())
    access.position = 0.5
    info, _ = access.execute({"mode": "info"})
    assert json.loads(info)["playhead_frame"] == 15
    info, images = access.execute({"mode": "current"})
    assert json.loads(info)["returned_indices"] == [15]
    measurement = json.loads(info)["measured_frames"][0]
    assert measurement["mean_luma_0_255"] < 3
    assert measurement["near_black_fraction_luma_below_12"] > 0.99
    assert "Source frame 15" in images[0]["text"]
    info, _ = access.execute({"mode": "time", "start": 0.49, "end": 0.51})
    assert json.loads(info)["returned_indices"] == [15]
    seen, offset = [], 0
    while True:
        info, _ = access.execute({"mode": "changes", "offset": offset, "limit": 2})
        page = json.loads(info)
        seen.extend(page["returned_indices"])
        if page["next_offset"] is None:
            break
        offset = page["next_offset"]
    assert seen[0] == 0
    assert 15 in seen and 16 in seen
    assert seen == sorted(set(seen))
    assert len(seen) == page["total_candidates"]
    with pytest.raises(ValueError):
        access.execute({"mode": "frames", "start": 1.5, "end": 10})
    with pytest.raises(ValueError):
        access.execute({"mode": "time", "start": float("nan")})
    with pytest.raises(ValueError):
        access.execute({"limit": 500})
    access.cancelled.set()
    with pytest.raises(RuntimeError, match="cancelled"):
        access.execute({"mode": "current"})


def test_agent_gets_images_without_user_attachment_and_replays_tools(tmp_path, video):
    class Agent:
        def __init__(self):
            self.requests = []

        def bind_tools(self, tools):
            assert tools[0].name == "inspect_video"
            return self

        async def ainvoke(self, messages):
            self.requests.append(messages)
            if len(self.requests) == 1:
                return AIMessage(
                    "",
                    tool_calls=[
                        {
                            "id": "frames1",
                            "name": "inspect_video",
                            "args": {"mode": "frames", "start": 14, "end": 16},
                        }
                    ],
                )
            assert any(m.type == "tool" for m in messages)
            assert "image_url" in str(messages[-1].content) or len(self.requests) == 3
            return AIMessage("Black source frame 15 at 0.500000s.")

    agent = Agent()
    access = VideoTools(video, Commands(), Event())
    chat = Chat(tmp_path, agent, video=access)
    assert "frame 15" in chat.ask("Any black frames?", {"playhead_seconds": 0})
    assert agent.requests[0][-1].content == "Any black frames?"
    before = chat.session.path.read_bytes()
    chat.ask("Thanks")
    assert chat.session.path.read_bytes().startswith(before)
    records = [json.loads(line) for line in chat.session.path.read_text().splitlines()]
    assert any(
        r.get("metadata", {}).get("tool_observation") == "frames1" for r in records
    )
    chat.close()


def test_cancelled_tool_is_closed_and_next_turn_can_continue(tmp_path, video):
    import sys
    import threading

    started = Event()

    class Agent:
        def __init__(self):
            self.count = 0

        def bind_tools(self, tools):
            return self

        async def ainvoke(self, messages):
            self.count += 1
            if self.count == 1:
                return AIMessage(
                    "",
                    tool_calls=[{"id": "cancel1", "name": "inspect_video", "args": {}}],
                )
            assert any(
                m.type == "tool" and m.tool_call_id == "cancel1" for m in messages
            )
            return AIMessage("Ready for another request.")

    cancelled = Event()
    access = VideoTools(video, Commands(), cancelled)
    original = access.execute

    def slow(args):
        started.set()
        access.commands.output([sys.executable, "-c", "import time; time.sleep(20)"])
        return original(args)

    access.execute = slow
    chat = Chat(tmp_path, Agent(), video=access)
    chat.cancelled = cancelled
    result = []
    worker = threading.Thread(target=lambda: result.append(chat.ask("Inspect video")))
    worker.start()
    assert started.wait(2)
    cancelled.set()
    access.commands.stop()
    worker.join(2)
    assert not worker.is_alive()
    assert result == [None]
    cancelled.clear()
    assert chat.ask("Continue") == "Ready for another request."
    assert not access.commands.stopped
    chat.close()
