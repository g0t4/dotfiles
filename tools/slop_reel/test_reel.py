import asyncio
import base64
import json
import threading
from io import BytesIO

import pytest
from langchain_core.messages import AIMessage
from PIL import Image, ImageStat

from chat import Chat, request_content
from fixtures import generate
from media import Media, waveform


@pytest.fixture(scope="module")
def videos(tmp_path_factory):
    return generate(tmp_path_factory.mktemp("reel"))


def brightness(frame):
    return sum(ImageStat.Stat(Image.open(BytesIO(frame.jpeg))).mean) / 3


def test_consecutive_black_frame_and_boundaries(videos):
    media = Media(videos / "one-black.mp4")
    center, frames = media.frames(0.5)
    assert center == 15
    assert [f.index for f in frames] == list(range(12, 19))
    assert brightness(frames[3]) < 3
    assert all(brightness(f) > 30 for f in frames if f.index != 15)
    assert [f.index for f in media.frames(0)[1]] == [0, 1, 2, 3]
    assert [f.index for f in media.frames(100)[1]] == [56, 57, 58, 59]
    assert len(media.cache) <= 42
    media.close()


def test_variable_frame_rate_uses_actual_timestamps(videos):
    media = Media(videos / "variable-rate.mp4")
    deltas = {round(b - a, 3) for a, b in zip(media.times, media.times[1:])}
    assert len(deltas) > 1
    for index in (1, 5, 10):
        center, frames = media.frames(media.times[index])
        assert center == index
        assert [f.index for f in frames] == list(
            range(max(0, index - 3), min(len(media.times), index + 4))
        )
        reference = Media(videos / "numbered.mp4").frames(media.times[index], 0)[1][0]
        # Correct source frame even after nonuniform seeks; compare average color.
        assert (
            abs(brightness(frames[index - frames[0].index]) - brightness(reference)) < 3
        )


def test_waveform_silent_and_audio(videos):
    duration, peaks = waveform(videos / "numbered.mp4")
    assert duration == pytest.approx(2, abs=0.1)
    assert peaks == []
    duration, peaks = waveform(videos / "numbered-audio.mp4")
    assert duration == pytest.approx(2, abs=0.1)
    assert 100 < len(peaks) <= 1801
    assert max(peaks) > 0.05


def test_attachment_pixels_labels_and_no_shell_interpretation(videos):
    center, frames = Media(videos / "one-black.mp4").frames(0.5)
    content = request_content("/frames find {} black # $HOME", frames, center)
    images = [c for c in content if c["type"] == "image_url"]
    assert len(images) == 7
    assert content[-1]["text"] == "find {} black # $HOME"
    assert "Source frame 15" in content[6]["text"]
    image = Image.open(
        BytesIO(base64.b64decode(images[3]["image_url"]["url"].split(",")[1]))
    )
    assert max(image.size) <= 640
    assert sum(ImageStat.Stat(image).mean) < 9
    with pytest.raises(ValueError, match="Unknown command"):
        request_content("/oops hi")


class Model:
    def __init__(self):
        self.calls = []
        self.loops = []

    async def ainvoke(self, messages):
        self.loops.append(asyncio.get_running_loop())
        self.calls.append(messages)
        return AIMessage(
            content="A flexible description.", response_metadata={"example": True}
        )


def test_trace_replay_keeps_exact_prefix_and_media(tmp_path, videos):
    model = Model()
    chat = Chat(tmp_path, model)
    center, frames = Media(videos / "one-black.mp4").frames(0.5)
    chat.ask(request_content("/frames", frames, center), {"playhead_seconds": 0.5})
    before = chat.session.path.read_bytes()
    chat.ask("Tell me more")
    assert chat.session.path.read_bytes().startswith(before)
    records = [json.loads(line) for line in chat.session.path.read_text().splitlines()]
    assert records[0]["type"] == "version"
    assert records[1]["trace_type"] == "slop_reel"
    assert [r["turn_id"] for r in records if r["type"] == "turn_start"] == [1, 2]
    assert model.loops[0] is model.loops[1]
    assert model.calls[1][1].content == model.calls[0][1].content
    assert "image_url" in str(model.calls[1][1].content)
    assert (
        len(
            [
                r
                for r in records
                if r["type"] == "message" and r["message"]["role"] == "system"
            ]
        )
        == 1
    )


def test_cancel_aborts_inflight_request_and_records_turn(tmp_path):
    started = threading.Event()
    stopped = threading.Event()

    class Slow:
        async def ainvoke(self, messages):
            started.set()
            try:
                await asyncio.sleep(30)
            finally:
                stopped.set()

    chat = Chat(tmp_path, Slow())
    result = []
    thread = threading.Thread(target=lambda: result.append(chat.ask("hello")))
    thread.start()
    assert started.wait(2)
    chat.cancelled.set()
    thread.join(2)
    assert not thread.is_alive()
    assert stopped.is_set()
    assert result == [None]
    assert (
        json.loads(chat.session.path.read_text().splitlines()[-1])["status"]
        == "interrupted"
    )


def test_inference_error_is_retained(tmp_path):
    class Broken:
        async def ainvoke(self, messages):
            raise RuntimeError("offline")

    chat = Chat(tmp_path, Broken())
    with pytest.raises(RuntimeError, match="offline"):
        chat.ask("hello")
    records = [json.loads(line) for line in chat.session.path.read_text().splitlines()]
    assert records[-2]["type"] == "error"
    assert records[-1]["status"] == "error"
    assert not chat.session.active


def test_nonzero_start_time_keeps_source_identity(videos, tmp_path):
    import subprocess

    target = tmp_path / "offset.mp4"
    subprocess.run(
        [
            "ffmpeg",
            "-v",
            "error",
            "-y",
            "-itsoffset",
            "0.4",
            "-i",
            str(videos / "one-black.mp4"),
            "-c",
            "copy",
            str(target),
        ],
        check=True,
    )
    media = Media(target)
    assert media.times[0] == pytest.approx(0.4)
    center, frames = media.frames(0.9)
    assert center == 15
    assert frames[3].seconds == pytest.approx(0.9)
    assert brightness(frames[3]) < 3


def test_close_stops_owned_processes():
    import subprocess
    import sys

    from commands import Commands

    commands = Commands()
    process = commands.spawn(
        [sys.executable, "-c", "import time; time.sleep(30)"], stdout=subprocess.PIPE
    )
    commands.stop()
    assert process.wait(timeout=2) != 0
    with pytest.raises(RuntimeError, match="cancelled"):
        commands.spawn([sys.executable, "-c", "pass"])


def test_real_provider_http_images_and_replay(tmp_path, videos):
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    from ai_shared.models import connect

    requests = []

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            body = json.dumps({"data": [{"id": "fixture-model"}]}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            payload = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            requests.append(payload)
            body = json.dumps(
                {
                    "id": "fixture-response",
                    "object": "chat.completion",
                    "created": 1,
                    "model": "fixture-model",
                    "choices": [
                        {
                            "index": 0,
                            "message": {
                                "role": "assistant",
                                "content": "Observed the supplied frames.",
                            },
                            "finish_reason": "stop",
                        }
                    ],
                    "usage": {
                        "prompt_tokens": 10,
                        "completion_tokens": 5,
                        "total_tokens": 15,
                    },
                }
            ).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever)
    thread.start()
    try:
        model = connect(f"http://127.0.0.1:{server.server_port}/v1")
        chat = Chat(tmp_path, model)
        center, frames = Media(videos / "one-black.mp4").frames(0.5)
        assert (
            chat.ask(request_content("/frames inspect", frames, center))
            == "Observed the supplied frames."
        )
        chat.ask("follow up")
        assert requests[1]["messages"][:2] == requests[0]["messages"]
        assert (
            len(
                [
                    c
                    for c in requests[0]["messages"][1]["content"]
                    if c["type"] == "image_url"
                ]
            )
            == 7
        )
        assert "metadata" not in str(requests[0]["messages"])
    finally:
        server.shutdown()
        thread.join()
        server.server_close()
