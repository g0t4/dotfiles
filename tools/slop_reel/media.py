"""Timestamp-aware source frame decoding, bounded image cache, audio peaks."""

import json
import subprocess
from bisect import bisect_right
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path

from commands import Commands


@dataclass(frozen=True)
class Frame:
    index: int
    seconds: float
    jpeg: bytes


class Media:
    """One worker owns this object. Never share its decoder across threads."""

    def __init__(self, path, commands=None):
        self.commands = commands or Commands()
        self.path = Path(path).resolve(strict=True)
        probe = self.commands.output(
            [
                "ffprobe",
                "-v",
                "error",
                "-select_streams",
                "v:0",
                "-show_frames",
                "-show_entries",
                "frame=best_effort_timestamp_time",
                "-of",
                "json",
                str(self.path),
            ],
        )
        self.times = [
            float(f["best_effort_timestamp_time"])
            for f in json.loads(probe)["frames"]
            if "best_effort_timestamp_time" in f
        ]
        if not self.times:
            self.close()
            raise ValueError("No timestamped video frames found")
        self.cache = OrderedDict()

    def index_at(self, seconds):
        return max(
            0, min(len(self.times) - 1, bisect_right(self.times, seconds + 1e-6) - 1)
        )

    def frames(self, seconds, radius=3):
        center = self.index_at(seconds)
        indices = list(
            range(max(0, center - radius), min(len(self.times), center + radius + 1))
        )
        missing = [i for i in indices if i not in self.cache]
        if missing:
            start, end = indices[0], indices[-1]
            # ffmpeg performs accurate input seeking, decoding from the preceding
            # keyframe and discarding frames before the requested presentation time.
            data = self.commands.output(
                [
                    "ffmpeg",
                    "-v",
                    "error",
                    "-seek_timestamp",
                    "1",
                    "-ss",
                    f"{max(0, self.times[start] - 0.000001):.6f}",
                    "-i",
                    str(self.path),
                    "-map",
                    "0:v:0",
                    "-frames:v",
                    str(end - start + 1),
                    "-vf",
                    "scale=1280:1280:force_original_aspect_ratio=decrease",
                    "-fps_mode",
                    "passthrough",
                    "-f",
                    "image2pipe",
                    "-vcodec",
                    "mjpeg",
                    "pipe:1",
                ],
                timeout=60,
            )
            images = [b"\xff\xd8" + piece for piece in data.split(b"\xff\xd8")[1:]]
            if len(images) != len(indices):
                raise RuntimeError("Source decoder returned an unexpected frame count")
            for index, jpeg in zip(indices, images, strict=True):
                self.cache[index] = Frame(index, self.times[index], jpeg)
            while len(self.cache) > 42:
                self.cache.popitem(last=False)
        return center, [self.cache[i] for i in indices if i in self.cache]

    def frames_at(self, indices):
        """Fetch sparse source frames without decoding all intervening spans."""
        return [
            self.frames(self.times[index], radius=0)[1][0]
            for index in sorted(set(indices))
            if 0 <= index < len(self.times)
        ]

    def inspection(self, seconds):
        center, nearby = self.frames(seconds, radius=4)
        frames = [frame for frame in nearby if abs(frame.index - center) <= 3]
        return center, frames, {frame.index: frame for frame in nearby}

    def close(self):
        pass


def waveform(path, buckets=1800, commands=None):
    commands = commands or Commands()
    """Stream mono float PCM, retaining only bounded time buckets."""
    import math
    import struct

    info = commands.output(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration:stream=codec_type",
            "-of",
            "json",
            str(path),
        ]
    )
    info = json.loads(info)
    duration = float(info["format"]["duration"])
    if not any(s["codec_type"] == "audio" for s in info["streams"]):
        return duration, []
    samples_per_bucket = max(1, math.ceil(duration * 8000 / buckets))
    proc = commands.spawn(
        [
            "ffmpeg",
            "-v",
            "error",
            "-i",
            str(path),
            "-vn",
            "-ac",
            "1",
            "-ar",
            "8000",
            "-f",
            "f32le",
            "pipe:1",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    peaks = []
    try:
        while data := proc.stdout.read(samples_per_bucket * 4):
            # ffmpeg's f32le is explicitly little endian.
            values = (v[0] for v in struct.iter_unpack("<f", data))
            peaks.append(max((abs(v) for v in values), default=0))
        if proc.wait() != 0:
            raise RuntimeError("Audio waveform decode failed")
    finally:
        commands.release(proc)
        proc.stdout.close()
        if proc.poll() is None:
            proc.terminate()
            proc.wait()
    return duration, peaks
