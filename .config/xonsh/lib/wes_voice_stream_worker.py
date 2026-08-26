"""Resident pywhispercpp worker for experimental live command dictation."""

from __future__ import annotations

import argparse
import json
import signal
import subprocess
import sys
import threading
from pathlib import Path


def emit(kind: str, **values) -> None:
    print(json.dumps({"type": kind, **values}, ensure_ascii=False), flush=True)


def transcript_text(segments) -> str:
    text = " ".join(" ".join(segment.text.split()) for segment in segments).strip()
    if text in {"[BLANK_AUDIO]", "(silence)", "[Silence]"}:
        return ""
    return text


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--ffmpeg", required=True)
    parser.add_argument("--audio-device", default="0")
    parser.add_argument("--interval-ms", type=int, default=500)
    args = parser.parse_args()

    import numpy as np
    from pywhispercpp.model import Model

    stop = threading.Event()
    signal.signal(signal.SIGINT, lambda *_: stop.set())
    signal.signal(signal.SIGTERM, lambda *_: stop.set())

    model = Model(
        str(args.model),
        redirect_whispercpp_logs_to=None,
        print_progress=False,
        print_realtime=False,
        print_timestamps=False,
    )
    ffmpeg = subprocess.Popen(
        [
            args.ffmpeg,
            "-hide_banner",
            "-loglevel",
            "error",
            "-f",
            "avfoundation",
            "-i",
            f":{args.audio_device}",
            "-ac",
            "1",
            "-ar",
            "16000",
            "-f",
            "f32le",
            "-",
        ],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    audio = bytearray()
    audio_lock = threading.Lock()
    reset_generation = 0

    def read_audio() -> None:
        while not stop.is_set():
            chunk = ffmpeg.stdout.read(8192)
            if not chunk:
                break
            with audio_lock:
                audio.extend(chunk)

    reader = threading.Thread(target=read_audio, daemon=True)
    reader.start()

    def read_control() -> None:
        nonlocal reset_generation
        for line in sys.stdin:
            if line.strip() != "reset":
                continue
            with audio_lock:
                audio.clear()
                reset_generation += 1

    control = threading.Thread(target=read_control, daemon=True)
    control.start()
    emit("ready")
    previous = ""
    last_size = 0
    observed_generation = reset_generation

    try:
        while not stop.wait(args.interval_ms / 1000):
            with audio_lock:
                snapshot = bytes(audio)
                generation = reset_generation
            if generation != observed_generation:
                observed_generation = generation
                previous = ""
                last_size = 0
            if len(snapshot) == last_size or len(snapshot) < 16000 * 4:
                continue
            last_size = len(snapshot)
            samples = np.frombuffer(snapshot, dtype=np.float32).copy()
            text = transcript_text(model.transcribe(samples))
            with audio_lock:
                if generation != reset_generation:
                    previous = ""
                    last_size = 0
                    continue
            if text and text != previous:
                previous = text
                emit("partial", text=text, audio_ms=len(samples) * 1000 // 16000)
    except Exception as error:
        emit("error", message=f"{type(error).__name__}: {error}")
        return 1
    finally:
        ffmpeg.terminate()
        try:
            ffmpeg.wait(timeout=1)
        except subprocess.TimeoutExpired:
            ffmpeg.kill()
            ffmpeg.wait()

    with audio_lock:
        snapshot = bytes(audio)
    if snapshot:
        samples = np.frombuffer(snapshot, dtype=np.float32).copy()
        text = transcript_text(model.transcribe(samples))
        emit("final", text=text, audio_ms=len(samples) * 1000 // 16000)
    else:
        emit("final", text="", audio_ms=0)
    return 0


if __name__ == "__main__":
    sys.exit(main())
