import subprocess
from io import BytesIO

import pytest
from PIL import Image, ImageDraw, ImageStat

from changes import (
    Change,
    difference,
    material,
    measure,
    next_change,
    overlay,
    scan,
    sequence,
)
from commands import Commands
from media import Media


def jpeg(image):
    stream = BytesIO()
    image.save(stream, "JPEG", quality=95)
    return stream.getvalue()


def test_identical_and_small_noise_are_ignored():
    base = Image.new("RGB", (640, 360), (60, 80, 100))
    assert measure(difference(base, base)) == (0, 0)
    noise = Image.new("RGB", base.size, (65, 83, 98))
    assert not material(*measure(difference(base, noise)))
    tiny = base.copy()
    ImageDraw.Draw(tiny).point((50, 50), fill="white")
    assert not material(*measure(difference(base, tiny)))


def test_concentrated_small_change_and_color_only_change():
    base = Image.new("RGB", (640, 360), "#203040")
    current = base.copy()
    ImageDraw.Draw(current).rectangle((64, 64, 85, 85), fill="white")
    fraction, local = measure(difference(base, current))
    assert fraction < 0.003
    assert local >= 0.25
    assert material(fraction, local)
    # Similar luminance does not hide a color change.
    red, green = (
        Image.new("RGB", base.size, (255, 0, 0)),
        Image.new("RGB", base.size, (0, 130, 0)),
    )
    assert material(*measure(difference(red, green)))


def test_diff_overlay_marks_changed_region_only():
    base = Image.new("RGB", (640, 360), "#203040")
    current = base.copy()
    ImageDraw.Draw(current).rectangle((200, 100, 300, 200), fill="white")
    data, fraction, _local = overlay(jpeg(base), jpeg(current))
    result = Image.open(BytesIO(data))
    assert fraction > 0.03
    changed, unchanged = result.getpixel((250, 150)), result.getpixel((20, 20))
    assert changed[0] > changed[2]  # warm palette accent
    assert sum(changed) > sum(unchanged) * 2


@pytest.fixture
def review_video(tmp_path):
    target = tmp_path / "review.mp4"
    process = subprocess.Popen(
        [
            "ffmpeg",
            "-v",
            "error",
            "-y",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            "-s",
            "640x360",
            "-r",
            "30",
            "-i",
            "pipe:0",
            "-an",
            "-c:v",
            "libx264",
            "-pix_fmt",
            "yuv420p",
            str(target),
        ],
        stdin=subprocess.PIPE,
    )
    for index in range(60):
        image = Image.new("RGB", (640, 360), "#203040" if index < 20 else "#405080")
        draw = ImageDraw.Draw(image)
        draw.text((20, 20), "Review fixture", fill="white", font_size=30)
        if index == 10 or index >= 40:
            draw.rectangle((200, 100, 300, 200), fill="white")
        process.stdin.write(image.tobytes())
    process.stdin.close()
    assert process.wait() == 0
    return target


def test_scan_retains_one_frame_flash_entry_exit_and_plateaus(review_video):
    media = Media(review_video)
    changes = scan(review_video, media.times, Commands())
    assert [c.index for c in changes] == [10, 11, 20, 40]
    assert [c.seconds for c in changes] == pytest.approx(
        [10 / 30, 11 / 30, 20 / 30, 40 / 30]
    )
    assert next_change(changes, 10, 1).index == 11
    assert next_change(changes, 11, -1).index == 10
    assert next_change(changes, 40, 1) is None
    assert next_change(changes, 0, -1) is None
    center, selected = sequence(changes, 15)
    assert center == 20
    assert [c.index for c in selected] == [10, 11, 20, 40]
    # Sparse source extraction includes each event's actual predecessor.
    sparse = media.frames_at([9, 10, 19, 20, 39, 40])
    assert [f.index for f in sparse] == [9, 10, 19, 20, 39, 40]
    assert (
        abs(
            ImageStat.Stat(Image.open(BytesIO(sparse[0].jpeg))).mean[0]
            - ImageStat.Stat(Image.open(BytesIO(sparse[1].jpeg))).mean[0]
        )
        > 5
    )


def test_sequence_and_jump_boundaries():
    changes = [Change(i, i / 30, 0.1, 0.5) for i in range(10, 110, 10)]
    center, selected = sequence(changes, 50)
    assert center == 50
    assert [c.index for c in selected] == [20, 30, 40, 50, 60, 70, 80]
    assert next_change(changes, 55, 1).index == 60
    assert next_change(changes, 55, -1).index == 50
    assert sequence([], 0) == (None, [])
    assert next_change([], 0, 1) is None


def test_sequence_pages_do_not_overlap():
    from changes import page_changes

    changes = [Change(i, i / 30, 0.1, 0.5) for i in range(1, 25)]
    assert [c.index for c in page_changes(changes, 7, 1)] == list(range(8, 15))
    assert [c.index for c in page_changes(changes, 8, -1)] == list(range(1, 8))
    assert [c.index for c in page_changes(changes, 21, 1)] == [22, 23, 24]
    assert page_changes(changes, 24, 1) == []
    assert page_changes(changes, 1, -1) == []


def test_scan_uses_variable_source_timestamps(review_video, tmp_path):
    target = tmp_path / "variable.mp4"
    subprocess.run(
        [
            "ffmpeg",
            "-v",
            "error",
            "-i",
            str(review_video),
            "-vf",
            "select='not(mod(n,2))+eq(n,11)'",
            "-fps_mode",
            "vfr",
            "-c:v",
            "libx264",
            str(target),
        ],
        check=True,
    )
    media = Media(target)
    changes = scan(target, media.times, Commands())
    assert [c.index for c in changes] == [5, 6, 11, 21]
    assert [c.seconds for c in changes] == pytest.approx(
        [10 / 30, 11 / 30, 20 / 30, 40 / 30]
    )


def test_scan_rejects_misaligned_frame_index_and_releases_process(review_video):
    media = Media(review_video)
    commands = Commands()
    with pytest.raises(RuntimeError, match="does not match"):
        scan(review_video, media.times[:-1], commands)
    assert not commands.processes


def test_neighbor_inspection_supplies_first_tiles_previous_frame(review_video):
    media = Media(review_video)
    center, frames, predecessors = media.inspection(0.5)
    assert center == 15
    assert [frame.index for frame in frames] == list(range(12, 19))
    assert 11 in predecessors
    assert all(frame.index - 1 in predecessors for frame in frames)
