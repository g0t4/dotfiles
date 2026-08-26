"""Async client for the experimental resident voice transcription worker."""

from __future__ import annotations

import asyncio
import json
import signal


def bounded_command_result(
    command: str,
    return_code: int,
    output: str | None,
    *,
    max_lines: int = 20,
    preview_lines: int = 5,
    max_bytes: int = 4096,
) -> dict:
    """Build bounded context for the next conversational command turn."""
    result = {"command": command, "return_code": return_code}
    if output is None:
        result["output"] = None
        result["output_notice"] = "stdout was not captured"
        return result

    encoded = output.encode("utf-8")
    lines = output.splitlines()
    if len(lines) <= max_lines and len(encoded) <= max_bytes:
        result["output"] = output
        return result

    result["output"] = "\n".join(lines[:preview_lines])
    result["output_notice"] = (
        f"output truncated: {len(lines)} lines / {len(encoded)} bytes; "
        f"showing first {min(preview_lines, len(lines))} lines"
    )
    return result


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
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        self.reader_task = asyncio.create_task(self._read_events())
        await asyncio.wait_for(self.ready.wait(), timeout=15)

    def reset_nowait(self):
        """Begin a fresh utterance without unloading the resident model."""
        if not self.running or self.process.stdin is None:
            return False
        self.final_text = ""
        self.process.stdin.write(b"reset\n")
        return True

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
