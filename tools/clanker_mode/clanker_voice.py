"""Private voiced dictation for Clanker's prompt-toolkit buffers."""

from __future__ import annotations

import asyncio
import json
import os
from contextlib import suppress
from pathlib import Path

from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.keys import Keys


def voiced_socket_path():
    state_home = os.environ.get("XDG_STATE_HOME")
    base = Path(state_home) if state_home else Path.home() / ".local" / "state"
    return base / "ask-openai" / "voiced.sock"


def insert_transcript(buffer, transcript):
    """Insert final speech at the cursor without accepting the prompt."""
    transcript = " ".join(transcript.split())
    if not transcript:
        return
    before = buffer.document.text_before_cursor
    prefix = " " if before and not before[-1].isspace() else ""
    buffer.insert_text(prefix + transcript)


class PrivateDictation:
    """Own one private voiced connection for one prompt-toolkit session."""

    def __init__(self, path=None):
        self.path = Path(path) if path is not None else voiced_socket_path()
        self.state = "idle"
        self.detail = ""
        self.reader = None
        self.writer = None
        self.read_task = None
        self.buffer = None
        self.app = None

    def toolbar(self):
        if self.state == "idle":
            return [("class:bottom-toolbar", " Shift-F7 private voice ")]
        if self.state == "listening":
            text = " 🎙 private voice — Shift-F7 to stop "
        elif self.state == "finalizing":
            text = " 🎙 finalizing private transcript… "
        elif self.state == "error":
            text = f" voice: {self.detail} "
        else:
            text = " 🎙 starting private voice… "
        return [("class:bottom-toolbar", text)]

    def bindings(self):
        bindings = KeyBindings()

        @bindings.add(Keys.F19, eager=True, save_before=lambda event: False)
        def toggle_private_voice(event):
            event.app.create_background_task(
                self.toggle(event.current_buffer, event.app)
            )

        return bindings

    async def toggle(self, buffer, app):
        try:
            if self.state in {"starting", "listening"}:
                await self.stop()
            elif self.state == "idle" or self.state == "error":
                await self.start(buffer, app)
        except Exception as error:
            self.state = "error"
            self.detail = str(error)
            await self._disconnect()
        finally:
            app.invalidate()

    async def start(self, buffer, app):
        self.state = "starting"
        self.detail = ""
        self.buffer = buffer
        self.app = app
        app.invalidate()
        try:
            self.reader, self.writer = await asyncio.open_unix_connection(self.path)
        except (FileNotFoundError, ConnectionRefusedError) as error:
            raise RuntimeError(f"voiced unavailable at {self.path}") from error
        await self._send("hello")
        hello = await asyncio.wait_for(self._read_event(), timeout=2)
        if hello.get("type") != "hello" or not hello.get("private_dictation"):
            raise RuntimeError("voiced does not support private dictation")
        await self._send("dictation_start")
        self.read_task = app.create_background_task(self._read_events())

    async def stop(self):
        if self.writer is None:
            return
        self.state = "finalizing"
        self.app.invalidate()
        await self._send("dictation_stop")

    async def _read_events(self):
        try:
            while True:
                event = await self._read_event()
                kind = event.get("type")
                if kind == "status":
                    state = event.get("state")
                    if state == "listening":
                        self.state = "listening"
                    elif state == "idle":
                        self.state = "idle"
                        break
                elif kind == "transcription":
                    text = event.get("text", "")
                    if event.get("final"):
                        insert_transcript(self.buffer, text)
                    else:
                        self.detail = text
                elif kind == "error":
                    self.state = "error"
                    self.detail = event.get("message", "unknown voiced error")
                    break
                self.app.invalidate()
        except asyncio.CancelledError:
            raise
        except Exception as error:
            self.state = "error"
            self.detail = str(error)
        finally:
            await self._disconnect(from_reader=True)
            self.app.invalidate()

    async def _send(self, kind):
        self.writer.write((json.dumps({"type": kind}) + "\n").encode())
        await self.writer.drain()

    async def _read_event(self):
        line = await self.reader.readline()
        if not line:
            raise RuntimeError("voiced connection closed")
        return json.loads(line)

    async def _disconnect(self, *, from_reader=False):
        task = self.read_task
        self.read_task = None
        if task is not None and not from_reader and not task.done():
            task.cancel()
            with suppress(asyncio.CancelledError):
                await task
        writer = self.writer
        self.reader = None
        self.writer = None
        if writer is not None:
            writer.close()
            with suppress(Exception):
                await writer.wait_closed()

    async def close(self):
        await self._disconnect()

    def close_nowait(self):
        """Release a prompt-owned connection after its event loop has stopped."""
        if self.read_task is not None and not self.read_task.done():
            self.read_task.cancel()
        if self.writer is not None:
            self.writer.close()
        self.reader = None
        self.writer = None
        self.read_task = None
        self.state = "idle"
