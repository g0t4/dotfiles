"""Read-only, paginated video access owned by the chat worker."""

import json
import math
from bisect import bisect_left, bisect_right
from io import BytesIO
from typing import Literal

from langchain_core.tools import tool
from PIL import Image, ImageStat

from changes import scan
from media import Media


class VideoTools:
    def __init__(self, path, commands, cancelled, notify=lambda text: None):
        self.path, self.commands = path, commands
        self.cancelled, self.notify = cancelled, notify
        self.media = None
        self.changes = None
        self.position = 0

    def prepare(self):
        if self.commands.stopped:
            from commands import Commands

            self.commands = Commands()
            if self.media:
                self.media.commands = self.commands

    def tools(self):
        @tool
        def inspect_video(
            mode: Literal["info", "current", "frames", "time", "changes"] = "info",
            start: float | None = None,
            end: float | None = None,
            offset: int = 0,
            limit: int = 8,
        ) -> str:
            """Inspect the open video. info returns source bounds and playhead.
            current returns the frame at the playhead captured when the user sent their message.
            frames uses inclusive zero-based frame indices start/end (defaults: current +/-3).
            time uses inclusive source timestamps in seconds start/end (defaults: playhead +/-0.5s).
            changes returns materially changed frames plus frame zero as a baseline, across the
            WHOLE video by default; optional start/end bound source timestamps. Pages are exact,
            not sampled: use next_offset with the SAME mode/start/end until null. At most eight
            labeled images per call. Changes are candidates, not exhaustive visual coverage;
            subtle changes can fall below the detector threshold. You can inspect exact neighboring
            frames to confirm findings. No source audio is supplied. All operations are read-only.
            """
            raise RuntimeError("Schema only; execution is handled by VideoTools")

        return [inspect_video]

    def execute(self, args):
        from chat import request_content

        if self.cancelled.is_set():
            raise RuntimeError("Inspection cancelled")
        mode = args.get("mode", "info")
        if mode not in ("info", "current", "frames", "time", "changes"):
            raise ValueError("Unknown inspection mode")
        offset, limit = args.get("offset", 0), args.get("limit", 8)
        if (
            type(offset) is not int
            or offset < 0
            or type(limit) is not int
            or not 1 <= limit <= 8
        ):
            raise ValueError(
                "offset must be a nonnegative integer and limit must be 1..8"
            )
        self.notify(f"Inspecting video: {mode}, page offset {offset}…")
        if self.media is None:
            self.media = Media(self.path, self.commands)
        media = self.media
        center = media.index_at(self.position)
        info = {
            "path": str(media.path),
            "frame_count": len(media.times),
            "first_timestamp": media.times[0],
            "last_timestamp": media.times[-1],
            "playhead_seconds": self.position,
            "playhead_frame": center,
        }
        if mode == "info":
            return json.dumps(info), []
        start, end = args.get("start"), args.get("end")
        if mode == "current":
            indices = [center]
        else:
            default_start, default_end = (
                (max(0, center - 3), min(len(media.times) - 1, center + 3))
                if mode == "frames"
                else (
                    (media.times[0], media.times[-1])
                    if mode == "changes"
                    else (self.position - 0.5, self.position + 0.5)
                )
            )
            start = default_start if start is None else start
            end = default_end if end is None else end
            if (
                not all(
                    type(v) in (int, float) and math.isfinite(v) for v in (start, end)
                )
                or start > end
            ):
                raise ValueError("start/end must be finite numbers in ascending order")
            if mode == "frames":
                if (
                    int(start) != start
                    or int(end) != end
                    or start < 0
                    or end >= len(media.times)
                ):
                    raise ValueError(
                        "Frame bounds must be integer indices within the video"
                    )
                indices = range(int(start), int(end) + 1)
            elif mode == "time":
                indices = range(
                    bisect_left(media.times, start), bisect_right(media.times, end)
                )
            else:
                if self.changes is None:
                    self.changes = scan(media.path, media.times, self.commands)
                indices = [
                    i
                    for i in [0, *(c.index for c in self.changes)]
                    if start <= media.times[i] <= end
                ]
        selected = list(indices[offset : offset + limit])
        frames = media.frames_at(selected)
        measurements = []
        for frame in frames:
            gray = Image.open(BytesIO(frame.jpeg)).convert("L")
            histogram = gray.histogram()
            measurements.append(
                {
                    "index": frame.index,
                    "seconds": frame.seconds,
                    "mean_luma_0_255": round(ImageStat.Stat(gray).mean[0], 3),
                    "near_black_fraction_luma_below_12": round(
                        sum(histogram[:12]) / (gray.width * gray.height), 6
                    ),
                }
            )
        total = len(indices)
        info.update(
            mode=mode,
            start=start,
            end=end,
            total_candidates=total,
            offset=offset,
            returned_indices=selected,
            measured_frames=measurements,
            next_offset=offset + len(selected)
            if offset + len(selected) < total
            else None,
            coverage="Material-change candidates plus frame zero; not every source frame."
            if mode == "changes"
            else "Consecutive source frames in requested range.",
        )
        content = (
            request_content("/frames Tool-selected source frames.", frames, center)
            if frames
            else []
        )
        return json.dumps(info), content
