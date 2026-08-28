"""Push-to-talk recording and local speech-to-text for Xonsh."""

from __future__ import annotations

import asyncio
import os
import signal
import shutil
import subprocess
import tempfile
from functools import cached_property
from pathlib import Path
from typing import Callable


DEFAULT_MODEL = (
    Path.home()
    / "Library/Application Support/pywhispercpp/models/ggml-large-v3-turbo.bin"
)


def resolve_executable(name: str) -> str:
    """Resolve tools even when Xonsh's live PATH has not reached os.environ."""
    if os.path.isabs(name):
        return name
    resolved = shutil.which(name)
    if resolved:
        return resolved
    for directory in (Path("/opt/homebrew/bin"), Path("/usr/local/bin")):
        candidate = directory / name
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    raise FileNotFoundError(f"required executable not found: {name}")


class VoiceIntent:
    """Own recording/transcription state independently of the terminal UI."""

    def __init__(
        self,
        *,
        audio_device: str = "0",
        model: Path = DEFAULT_MODEL,
        ffmpeg: str = "ffmpeg",
        whisper: str = "whisper-cli",
        recorder_factory: Callable[..., subprocess.Popen] = subprocess.Popen,
        transcriber: Callable[..., subprocess.CompletedProcess] = subprocess.run,
        executable_resolver: Callable[[str], str] = resolve_executable,
    ) -> None:
        self.audio_device = audio_device
        self.model = Path(model)
        self._resolve_executable = executable_resolver
        self.ffmpeg = self._resolve_executable(ffmpeg)
        self._whisper_name = whisper
        self._recorder_factory = recorder_factory
        self._transcriber = transcriber
        self._recorder: subprocess.Popen | None = None
        self._audio_path: Path | None = None
        self._transcription_task: asyncio.Task | None = None

    @cached_property
    def whisper(self) -> str:
        return self._resolve_executable(self._whisper_name)

    @property
    def recording(self) -> bool:
        return self._recorder is not None and self._recorder.poll() is None

    @property
    def transcribing(self) -> bool:
        return (
            self._transcription_task is not None and not self._transcription_task.done()
        )

    def start(self) -> Path:
        if self.recording:
            raise RuntimeError("voice recording is already active")
        if self.transcribing:
            raise RuntimeError("voice transcription is still active")
        handle = tempfile.NamedTemporaryFile(
            prefix="xonsh-voice-", suffix=".wav", delete=False
        )
        handle.close()
        self._audio_path = Path(handle.name)
        self._recorder = self._recorder_factory(
            [
                self.ffmpeg,
                "-hide_banner",
                "-loglevel",
                "error",
                "-f",
                "avfoundation",
                "-i",
                f":{self.audio_device}",
                "-ac",
                "1",
                "-ar",
                "16000",
                "-y",
                str(self._audio_path),
            ],
            # FFmpeg's interactive `q` command gives it a chance to finalize
            # the WAV header before exiting.
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )
        return self._audio_path

    def stop_and_transcribe(self) -> asyncio.Task:
        if not self.recording or self._recorder is None or self._audio_path is None:
            raise RuntimeError("voice recording is not active")
        recorder = self._recorder
        audio_path = self._audio_path
        if recorder.stdin is not None:
            recorder.stdin.write(b"q\n")
            recorder.stdin.flush()
            recorder.stdin.close()
        else:
            recorder.send_signal(signal.SIGINT)
        self._recorder = None
        self._audio_path = None
        self._transcription_task = asyncio.create_task(
            self._finish_and_transcribe(recorder, audio_path)
        )
        return self._transcription_task

    async def _finish_and_transcribe(self, recorder, audio_path: Path) -> str:
        try:
            try:
                returncode = await asyncio.to_thread(recorder.wait, 3)
            except subprocess.TimeoutExpired:
                recorder.terminate()
                try:
                    returncode = await asyncio.to_thread(recorder.wait, 1)
                except subprocess.TimeoutExpired:
                    recorder.kill()
                    returncode = await asyncio.to_thread(recorder.wait)
            if returncode not in (0, 255):
                error = (recorder.stderr.read() if recorder.stderr else b"").decode(
                    errors="replace"
                )
                raise RuntimeError(f"audio recording failed: {error.strip()}")
            if not self.model.exists():
                raise RuntimeError(f"Whisper model not found: {self.model}")
            completed = await asyncio.to_thread(
                self._transcriber,
                [
                    self.whisper,
                    "--model",
                    str(self.model),
                    "--language",
                    "en",
                    "--no-timestamps",
                    "--no-prints",
                    str(audio_path),
                ],
                capture_output=True,
                text=True,
            )
            if completed.returncode != 0:
                raise RuntimeError(
                    f"voice transcription failed: {completed.stderr.strip()}"
                )
            return " ".join(completed.stdout.split()).strip()
        finally:
            audio_path.unlink(missing_ok=True)

    def cancel(self) -> None:
        if self.recording and self._recorder is not None:
            self._recorder.terminate()
        self._recorder = None
        self._audio_path = None
        if self._transcription_task is not None:
            self._transcription_task.cancel()


def insert_transcript(buffer, transcript: str) -> None:
    """Insert speech at the cursor while preserving existing command text."""
    if not transcript:
        return
    before = buffer.document.text_before_cursor
    prefix = " " if before and not before[-1].isspace() else ""
    buffer.insert_text(prefix + transcript)
