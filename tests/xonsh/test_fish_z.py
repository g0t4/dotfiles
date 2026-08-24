import subprocess
import sys
from pathlib import Path

import pytest


XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))

from wes_fish_z import FishZ, FishZError  # noqa: E402


class RecordingRunner:
    def __init__(self, *results):
        self.results = list(results)
        self.calls = []

    def __call__(self, command, **kwargs):
        self.calls.append((command, kwargs))
        return self.results.pop(0)


def completed(returncode=0, stdout="", stderr=""):
    return subprocess.CompletedProcess([], returncode, stdout, stderr)


def test_resolve_asks_fish_z_to_echo_the_destination(tmp_path):
    destination = tmp_path / "project"
    destination.mkdir()
    runner = RecordingRunner(completed(stdout=f"{destination}\n"))

    result = FishZ(runner=runner, fish_executable="/test/fish").resolve(
        ["github", "project"]
    )

    assert result == destination
    assert runner.calls[0][0] == [
        "/test/fish",
        "-c",
        '__z --echo "$argv"',
        "--",
        "github",
        "project",
    ]


def test_resolve_preserves_rank_and_recency_options(tmp_path):
    runner = RecordingRunner(completed(stdout=f"{tmp_path}\n"))

    FishZ(runner=runner, fish_executable="/test/fish").resolve(
        ["--recent", "repos"]
    )

    assert runner.calls[0][0][-2:] == ["--recent", "repos"]


def test_resolve_rejects_missing_and_non_directory_results(tmp_path):
    runner = RecordingRunner(completed(returncode=1, stdout="no match\n"))
    with pytest.raises(FishZError, match="no match"):
        FishZ(runner=runner).resolve(["missing"])

    runner = RecordingRunner(completed(stdout=str(tmp_path / "missing") + "\n"))
    with pytest.raises(FishZError, match="not a directory"):
        FishZ(runner=runner).resolve(["missing"])


def test_record_runs_fish_z_add_from_the_visited_directory(tmp_path):
    runner = RecordingRunner(completed())

    FishZ(runner=runner, fish_executable="/test/fish").record(tmp_path)

    command, kwargs = runner.calls[0]
    assert command == ["/test/fish", "-c", "__z_add"]
    assert kwargs["cwd"] == tmp_path


def test_record_failure_is_reported_without_raising(tmp_path, capsys):
    runner = RecordingRunner(completed(returncode=1, stderr="database busy\n"))

    assert FishZ(runner=runner).record(tmp_path) is False
    assert "database busy" in capsys.readouterr().err


def test_record_cannot_break_cd_when_fish_cannot_start(tmp_path, capsys):
    def unavailable(*_, **__):
        raise FileNotFoundError("fish")

    assert FishZ(runner=unavailable).record(tmp_path) is False
    assert "failed to record" in capsys.readouterr().err
