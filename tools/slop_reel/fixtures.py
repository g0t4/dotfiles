"""Generate tiny, inspectable source videos without altering course footage."""

import argparse
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

DEFAULT = Path(
    "/Users/wesdemos/FCT Dropbox/Wes Higbee/Sync/auto-edit-videos/face2camera/slop_reel"
)


def generate(directory):
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    for name, black in [
        ("numbered", set()),
        ("one-black", {15}),
        ("multiple-black", {10, 15, 20}),
    ]:
        target = directory / f"{name}.mp4"
        command = [
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
            "-g",
            "30",
            str(target),
        ]
        process = subprocess.Popen(command, stdin=subprocess.PIPE)
        for index in range(60):
            image = Image.new(
                "RGB",
                (640, 360),
                "black" if index in black else (40 + index * 3, 80, 150),
            )
            if index not in black:
                ImageDraw.Draw(image).text(
                    (35, 120), f"FRAME {index:02d}", fill="white", font_size=64
                )
            process.stdin.write(image.tobytes())
        process.stdin.close()
        if process.wait():
            raise RuntimeError(f"Failed generating {target}")
    subprocess.run(
        [
            "ffmpeg",
            "-v",
            "error",
            "-y",
            "-i",
            str(directory / "numbered.mp4"),
            "-f",
            "lavfi",
            "-i",
            "sine=frequency=440:duration=2",
            "-c:v",
            "copy",
            "-c:a",
            "aac",
            "-shortest",
            str(directory / "numbered-audio.mp4"),
        ],
        check=True,
    )
    # Nonuniform frame intervals, retaining visible frame numbers.
    subprocess.run(
        [
            "ffmpeg",
            "-v",
            "error",
            "-y",
            "-i",
            str(directory / "numbered.mp4"),
            "-vf",
            "select='not(mod(n,3))+eq(n,1)+eq(n,2)'",
            "-fps_mode",
            "vfr",
            "-an",
            "-c:v",
            "libx264",
            str(directory / "variable-rate.mp4"),
        ],
        check=True,
    )
    generate_change_review(directory)
    return directory


def generate_change_review(directory):
    """Static slides, material changes, and one isolated black frame."""
    directory = Path(directory)
    target = directory / "slide-changes.mp4"
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
    colors = ["#6ab7c8", "#ffcc66", "#c792ea", "#89ca78"]
    for index in range(240):
        stage = index // 20
        image = Image.new("RGB", (640, 360), "#171b23")
        draw = ImageDraw.Draw(image)
        draw.text((25, 25), "Slop Reel change review", fill="white", font_size=35)
        draw.rectangle((100, 110, 540, 270), fill=colors[stage % 4])
        draw.text((150, 155), f"SLIDE {stage:02d}", fill="#171b23", font_size=50)
        if index == 115:
            image = Image.new("RGB", image.size, "black")
        process.stdin.write(image.tobytes())
    process.stdin.close()
    if process.wait():
        raise RuntimeError("Failed generating change review fixture")
    (directory / "slide-changes.json").write_text(
        json.dumps(
            {
                "fps": 30,
                "frames": 240,
                "black_frames": [115],
                "changed_frames": sorted([*range(20, 240, 20), 115, 116]),
                "description": "Static slides with an isolated black frame; entry and exit both matter.",
            },
            indent=2,
        )
        + "\n"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", nargs="?", type=Path, default=DEFAULT)
    print(generate(parser.parse_args().directory))
