"""Deterministic adjacent-frame change detection; no temporal smoothing."""

import subprocess
from bisect import bisect_left, bisect_right
from dataclasses import dataclass
from io import BytesIO

from PIL import Image, ImageChops, ImageFilter, ImageOps

SIZE = (640, 360)
PIXEL_DELTA = 24
AREA_THRESHOLD = 0.003
TILE_SIZE = 32
TILE_THRESHOLD = 0.25


@dataclass(frozen=True)
class Change:
    index: int
    seconds: float
    fraction: float
    local_fraction: float


def prepare(image):
    return ImageOps.pad(
        image.convert("RGB"), SIZE, method=Image.Resampling.BILINEAR, color="black"
    )


def difference(previous, current):
    """Threshold max RGB-channel difference after a small spatial denoise."""
    a = prepare(previous).filter(ImageFilter.GaussianBlur(0.5))
    b = prepare(current).filter(ImageFilter.GaussianBlur(0.5))
    channels = ImageChops.difference(a, b).split()
    maximum = ImageChops.lighter(
        ImageChops.lighter(channels[0], channels[1]), channels[2]
    )
    return maximum.point(lambda value: 255 if value >= PIXEL_DELTA else 0)


def measure(mask):
    fraction = mask.histogram()[255] / (mask.width * mask.height)
    # Look for concentrated changes too; padding edge tiles to a full tile's
    # area prevents a handful of edge pixels from becoming a 100% tile change.
    local = 0.0
    if mask.getbbox():
        for y in range(0, mask.height, TILE_SIZE):
            for x in range(0, mask.width, TILE_SIZE):
                count = mask.crop((x, y, x + TILE_SIZE, y + TILE_SIZE)).histogram()[255]
                local = max(local, count / (TILE_SIZE * TILE_SIZE))
    return fraction, local


def material(fraction, local):
    return fraction >= AREA_THRESHOLD or local >= TILE_THRESHOLD


def overlay(previous_jpeg, current_jpeg):
    current = Image.open(BytesIO(current_jpeg)).convert("RGB")
    previous = Image.open(BytesIO(previous_jpeg)).convert("RGB")
    mask = difference(previous, current)
    fraction, local = measure(mask)
    preview = prepare(current)
    # Unchanged areas are dimmed; changed pixels use the palette's warm accent.
    dimmed = Image.blend(preview, Image.new("RGB", SIZE, "#171b23"), 0.65)
    highlighted = Image.blend(preview, Image.new("RGB", SIZE, "#ffcc66"), 0.7)
    result = Image.composite(highlighted, dimmed, mask)
    output = BytesIO()
    result.save(output, "PNG")
    return output.getvalue(), fraction, local


def scan(path, times, commands, progress=None):
    """Decode every source frame once, retaining only change records and a pair.

    Never sample temporally: a one-frame flash must not fall between samples.
    The separately probed timestamp index is validated against the decode count.
    """
    process = commands.spawn(
        [
            "ffmpeg",
            "-v",
            "error",
            "-i",
            str(path),
            "-map",
            "0:v:0",
            "-an",
            "-vf",
            "scale=640:360:force_original_aspect_ratio=decrease:flags=bilinear,pad=640:360:(ow-iw)/2:(oh-ih)/2",
            "-fps_mode",
            "passthrough",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            "pipe:1",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    changes = []
    previous = None
    count = 0
    try:
        while data := process.stdout.read(SIZE[0] * SIZE[1] * 3):
            if len(data) != SIZE[0] * SIZE[1] * 3 or count >= len(times):
                raise RuntimeError("Change decoder does not match source frame index")
            current = Image.frombytes("RGB", SIZE, data)
            if previous is not None:
                fraction, local = measure(difference(previous, current))
                if material(fraction, local):
                    changes.append(Change(count, times[count], fraction, local))
            previous = current
            count += 1
            if progress and count % 60 == 0:
                progress(count, len(times))
        if process.wait() != 0:
            raise RuntimeError("Change scan failed or was cancelled")
        if count != len(times):
            raise RuntimeError("Change decoder does not match source frame index")
        if progress:
            progress(count, len(times))
        return changes
    finally:
        process.stdout.close()
        if process.poll() is None:
            process.kill()
            process.wait()
        commands.release(process)


def next_change(changes, frame_index, direction):
    indices = [change.index for change in changes]
    offset = (
        bisect_right(indices, frame_index)
        if direction > 0
        else bisect_left(indices, frame_index) - 1
    )
    return changes[offset] if 0 <= offset < len(changes) else None


def sequence(changes, frame_index, radius=3):
    """Three changes on either side of the first change at/after playhead."""
    if not changes:
        return None, []
    offset = min(bisect_left([c.index for c in changes], frame_index), len(changes) - 1)
    return changes[offset].index, changes[max(0, offset - radius) : offset + radius + 1]


def page_changes(changes, boundary, direction, count=7):
    indices = [change.index for change in changes]
    if direction > 0:
        start = bisect_right(indices, boundary)
        return changes[start : start + count]
    stop = bisect_left(indices, boundary)
    return changes[max(0, stop - count) : stop]
