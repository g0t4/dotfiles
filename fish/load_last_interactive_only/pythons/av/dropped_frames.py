import subprocess
import json
from numpy._typing import NDArray
import rich
import numpy as np
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Tuple

class MediaValidationError(ValueError):
    pass

def get_container(video_path: Path):
    cmd = [
        "ffprobe",
        "-loglevel",
        "error",
        "-show_format",
        "-of",
        "json",
        str(video_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)
    container = data.get("format")
    if not container:
        raise MediaValidationError("No format information found")
    return container

def verify_container(video_path: Path) -> None:
    container = get_container(video_path)
    warn_if_unexpected(container, "nb_streams", 2)
    throw_if_unexpected(container, "start_time", 0.0, float)
    return container

def get_streams(video_path: Path):
    # FYI to review:
    #   ffprobe -loglevel warning  -show_streams min3dropped.mp4 | bat -l ini
    cmd = [
        "ffprobe",
        "-loglevel",
        "error",
        "-show_streams",
        "-of",
        "json",
        str(video_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)

    # * get ONE audio stream
    audio_streams = [s for s in data.get("streams", []) if s.get("codec_type") == "audio"]
    if not audio_streams:
        raise MediaValidationError("No audio streams found")
    if len(audio_streams) > 1:
        raise MediaValidationError(f"Multiple audio streams found, only one allowed: {len(audio_streams)}")
    audio = audio_streams[0]

    # * get ONE video stream:
    video_streams = [s for s in data.get("streams", []) if s.get("codec_type") == "video"]
    if not video_streams:
        raise MediaValidationError("No video streams found")
    if len(video_streams) > 1:
        raise MediaValidationError(f"Multiple video streams found, only one allowed: {len(video_streams)}")
    video = video_streams[0]

    return audio, video

def throw_if_unexpected(data: dict, key: str, expected: str | int | float, convert: Callable[[Any], Any] | None = None):
    actual = data.get(key)
    if convert is not None:
        actual = convert(actual)

    if actual != expected:
        rich.inspect(actual)
        raise MediaValidationError(f"{key} is {actual}, expected {expected}")

def warn_if_unexpected(data: dict, key: str, expected: str | int | float, convert: Callable[[Any], Any] | None = None):
    actual = data.get(key)
    if convert is not None:
        actual = convert(actual)
    if actual != expected:
        rich.inspect(actual)
        rich.print(f"WARNING: {key} is not {expected}, should be fine but just a heads up: {actual}")

def verify_streams(video_path: Path) -> tuple[dict, dict]:
    audio, video = get_streams(video_path)

    # * audio stream
    throw_if_unexpected(audio, "channels", 1)
    throw_if_unexpected(audio, "channel_layout", "mono")
    #
    # not show stoppers but that I might want to know, b/c they don't match what I tested with initially
    warn_if_unexpected(audio, "sample_rate", 48000, int)  # str in my testing
    warn_if_unexpected(audio, "codec_name", "aac")
    #
    throw_if_unexpected(audio, "start_pts", 0)
    throw_if_unexpected(audio, "start_time", 0.0, float)  # str in my testing
    # r_frame_rate=0/0
    # avg_frame_rate=0/0
    # time_base=1/48000
    # duration_ts=2880000
    # nb_frames=2814
    #
    # PRN? pass -count_frames/packets and then compare nb_frames to nb_read_frames?
    # nb_read_frames=N/A
    # nb_read_packets=N/A

    # * video stream
    throw_if_unexpected(video, "codec_name", "h264")
    # prn can add other resolutions but actually I have things coded for 4k IIRC in fcpxml builder
    warn_if_unexpected(video, "width", 3840)
    warn_if_unexpected(video, "height", 2160)
    # ? has_b_frames=2
    # pix_fmt=yuv420p
    throw_if_unexpected(video, "r_frame_rate", "30/1")
    # avg_frame_rate=?
    # time_base=1/15360
    #
    throw_if_unexpected(video, "start_pts", 0)
    throw_if_unexpected(video, "start_time", 0.0, float)
    # nb_frames=1799 # duration=59.966667 # duration_ts=921088
    #
    # PRN pass -count_frames/packets to get these too (takes longer, verify needed first.. and if so, probably get this while reading the frames too)
    # nb_read_frames=N/A
    # nb_read_packets=N/A

    # PRN compare across streams?
    audio_duration = audio.get("duration")
    video_duration = video.get("duration")
    if not (audio_duration == video_duration):
        raise MediaValidationError(f"Audio and video durations differ: {audio_duration} vs {video_duration}")

    return audio, video

def verify_all(container, audio, video):
    # Placeholder for additional verification logic
    # duration check
    # Example additional verification: ensure container duration matches stream duration
    container_duration = float(container.get("duration"))
    audio_duration = float(audio.get("duration"))
    video_duration = float(video.get("duration"))
    if container_duration != audio_duration or container_duration != video_duration:
        raise MediaValidationError(f"Container duration {container_duration} does not match audio ({audio_duration}) or video ({video_duration}) durations")

@dataclass
class FrameInfo:
    pts: int
    pts_time: float
    duration: int
    duration_time: float

def get_frame_info(video_path: Path, stream: str) -> list[FrameInfo]:
    cmd = [
        "ffprobe",
        "-loglevel",
        "error",
        "-select_streams",
        stream,
        "-show_entries",
        "frame=pts,pts_time,nb_samples,duration,duration_time",
        # ? pkt_dts/pkt_dts_time
        #   ? would these always match pts in my case? any use in verifying they match pts to avoid another set of problems?
        #   ? likewise with best_effort_timestamp/best_effort_timestamp_time
        "-of",
        "json",
        str(video_path),
    ]

    joined_cmd = " ".join(str(arg) for arg in cmd)
    rich.print("cmd", joined_cmd)

    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)
    frames = [FrameInfo(
        pts=int(frame["pts"]),
        pts_time=float(frame["pts_time"]),
        duration=int(frame["duration"]),
        duration_time=float(frame["duration_time"]),
    ) for frame in data.get("frames", [])]
    return frames

def find_missing_frames(
    timestamps: NDArray[np.float64],
    fps: float,
    duration_frames: int,
) -> tuple[list[float], list[float]]:
    # PRN read r_frame_rate instead of throw/hardcode this
    frame_numbers = np.array(timestamps) * fps
    extra_frames = []
    missing_frames = []
    last_int: int = -1  # thus 0 is the next frame to find
    # print()
    for _cur in frame_numbers:

        # * anything before/after expected frames => extras
        if _cur >= duration_frames:
            # add all frames past duration_frames as extras
            # BTW duration_frames is NOT inclusive b/c 0 is first frame
            extra_frames.append(_cur)
            continue
        if _cur < 0:
            # everything below zero is always extra, and should never happen b/c I test for start_time == 0
            extra_frames.append(_cur)
            continue

        # * any timestamp not on a frame exactly (i.e. 2.000 or 3.000, after rounding 3rd digit) => extras (not an exact frame)
        #    so 2.105 => not on a frame boundary, mark as extra (b/w expected video frames)
        _cur_rounded_int = round(_cur)
        cur_is_on_a_frame = np.isclose(_cur, _cur_rounded_int, atol=1e-6)
        if not cur_is_on_a_frame:
            # rich.print(f'{cur_is_on_a_frame=} {_cur}')
            extra_frames.append(_cur)
            # do not increment last until hit an exact frame at which time will add all missing since last frame
            continue

        # * cur is a frame exactly (close test above means its on a frame => so round any error away and integer it)
        cur_int: int = int(round(_cur))
        diff = cur_int - last_int
        if diff > 1:
            # * add missing frames since last
            _missing_since_last = np.arange(last_int + 1, cur_int)
            # rich.print(f'{_missing_since_last=}')
            missing_frames.extend(_missing_since_last)

        last_int = cur_int

    # * missing frames after last frame:
    if last_int < duration_frames:
        missing_frames.extend(np.arange(last_int + 1, duration_frames))

    return [float(m) for m in missing_frames], [float(e) for e in extra_frames]

def report_missing_frames(video_path: Path, video: dict) -> None:
    frames = get_frame_info(video_path, "v:0")
    timestamps = np.array([frame.pts_time for frame in frames])
    fps = 30
    duration_frames = int(float(video.get("duration", 0)) * fps)
    missing_frames, extra_frames = find_missing_frames(timestamps, fps, duration_frames)
    if missing_frames:
        missing_times = [f"{int(m) / fps:.5f}" for m in missing_frames]
        print(f"[FAILURE] missing frames detected: {missing_times}")
    if extra_frames:
        extra_times = [f"{int(e) / fps:.5f}" for e in extra_frames]
        print(f"[FAILIURE] extra frames detected: {extra_times}")
    if missing_frames or extra_frames:
        exit(-1)

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python dropped_frames.py <video_file>")
        sys.exit(1)
    video_path = Path(sys.argv[1])
    if not video_path.is_file():
        print(f"File not found: {video_path}")
        sys.exit(1)
    try:
        container = verify_container(video_path)
        audio, video = verify_streams(video_path)
        verify_all(container, audio, video)
        report_missing_frames(video_path, video)
    except MediaValidationError:
        rich.print(f"Error: {sys.exc_info()[1]}")
        exit(-1)
