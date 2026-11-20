import asyncio
import json
import tempfile
from pathlib import Path

from prompt_toolkit.buffer import Buffer
from prompt_toolkit.document import Document

from clanker_voice import PrivateDictation, insert_transcript


class App:
    def __init__(self):
        self.invalidations = 0

    def create_background_task(self, coroutine):
        return asyncio.create_task(coroutine)

    def invalidate(self):
        self.invalidations += 1


async def wait_until(predicate):
    for _ in range(100):
        if predicate():
            return
        await asyncio.sleep(0.01)
    raise AssertionError("condition was not reached")


def test_private_dictation_inserts_final_text_without_submitting():
    async def scenario():
        with tempfile.TemporaryDirectory(prefix="clanker-voice-", dir="/tmp") as root:
            socket = Path(root) / "voiced.sock"
            commands = []

            async def handle(reader, writer):
                while line := await reader.readline():
                    command = json.loads(line)
                    commands.append(command["type"])
                    if command["type"] == "hello":
                        event = {"type": "hello", "private_dictation": 1}
                    elif command["type"] == "dictation_start":
                        event = {"type": "status", "state": "listening"}
                    else:
                        events = (
                            {
                                "type": "transcription",
                                "text": "spoken words",
                                "final": True,
                            },
                            {"type": "status", "state": "idle"},
                        )
                        for event in events:
                            writer.write((json.dumps(event) + "\n").encode())
                        await writer.drain()
                        continue
                    writer.write((json.dumps(event) + "\n").encode())
                    await writer.drain()

            server = await asyncio.start_unix_server(handle, path=socket)
            async with server:
                voice = PrivateDictation(socket)
                buffer = Buffer(document=Document("before after", cursor_position=6))
                app = App()
                await voice.start(buffer, app)
                await wait_until(lambda: voice.state == "listening")
                await voice.stop()
                await wait_until(lambda: voice.state == "idle")
                await voice.close()

            assert commands == ["hello", "dictation_start", "dictation_stop"]
            assert buffer.text == "before spoken words after"
            assert buffer.cursor_position == len("before spoken words")
            assert app.invalidations > 0

    asyncio.run(scenario())


def test_transcript_spacing_preserves_existing_buffer():
    buffer = Buffer(document=Document("hello world", cursor_position=5))
    insert_transcript(buffer, "  from   voice  ")
    assert buffer.text == "hello from voice world"
