"""Async client for the experimental resident voice transcription worker."""

from __future__ import annotations

import asyncio
import json
import signal
from pathlib import Path


class LiveVoice:
    def __init__(self, command: list[str], on_partial):
        self.command = command
        self.on_partial = on_partial
        self.process = None
        self.reader_task = None
        self.final_text = ""
        self.ready = asyncio.Event()

    @property
    def running(self):
        return self.process is not None and self.process.returncode is None

    async def start(self):
        if self.running:
            raise RuntimeError("live voice is already running")
        self.final_text = ""
        self.ready = asyncio.Event()
        self.process = await asyncio.create_subprocess_exec(
            *self.command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        self.reader_task = asyncio.create_task(self._read_events())
        await asyncio.wait_for(self.ready.wait(), timeout=15)

    async def _read_events(self):
        async for raw_line in self.process.stdout:
            try:
                event = json.loads(raw_line)
            except json.JSONDecodeError:
                continue
            kind = event.get("type")
            if kind == "ready":
                self.ready.set()
            elif kind == "partial":
                self.final_text = event.get("text", "")
                self.on_partial(self.final_text)
            elif kind == "final":
                self.final_text = event.get("text", "")
            elif kind == "error":
                raise RuntimeError(event.get("message", "live voice worker failed"))

    async def stop(self):
        if not self.running:
            return self.final_text
        self.process.send_signal(signal.SIGINT)
        try:
            await asyncio.wait_for(self.process.wait(), timeout=10)
        except asyncio.TimeoutError:
            self.process.terminate()
            await self.process.wait()
        if self.reader_task is not None:
            await self.reader_task
        if self.process.returncode != 0:
            error = (await self.process.stderr.read()).decode(errors="replace").strip()
            raise RuntimeError(error or f"live voice exited {self.process.returncode}")
        return self.final_text
