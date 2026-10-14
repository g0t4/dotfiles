import test_setup

import subprocess
from pathlib import Path

import pytest

from wes_fish_z import FishZ, FishZError  # noqa: E402


@pytest.fixture
def z_alias(monkeypatch):
    from xonsh.built_ins import XSH
    from xonsh.events import events

    aliases = {}
    monkeypatch.setattr(type(XSH), "aliases", property(lambda self: aliases))
    namespace = {}
    source = Path(test_setup.ROOT / ".config/xonsh/rc.d/z.xsh").read_text()
    exec(compile(source, "z.xsh", "exec"), namespace)
    events.on_chdir.discard(namespace["_wes_z_record_directory"])
    return namespace


@pytest.mark.parametrize("url", [
    "https://github.com/QwenLM/Qwen3-ASR.git",
    "git@github.com:QwenLM/Qwen3-ASR.git",
])
def test_z_repository_url_jumps_without_pulling_existing_clone(z_alias, tmp_path, url):
    calls = []

    def wcl(args, **kwargs):
        calls.append(args)
        print(tmp_path, file=kwargs["stdout"])
        return 0

    z_alias["aliases"]["wcl"] = [wcl]
    z_alias["_xonsh_cd"] = lambda args: (calls.append(args), None, 0)
    assert z_alias["_wes_z_alias"]([url]) == 0
    assert calls == [["--path-only", url], [str(tmp_path)]]


def test_z_repository_url_clones_missing_repo_and_requests_cd(z_alias, tmp_path):
    url = "https://github.com/QwenLM/Qwen3-ASR.git"
    calls = []

    def wcl(args, **kwargs):
        calls.append(args)
        if "--path-only" in args:
            print(tmp_path / "missing", file=kwargs["stdout"])
            return 0
        return 3

    z_alias["aliases"]["wcl"] = wcl
    assert z_alias["_wes_z_alias"]([url]) == 3
    assert calls == [["--path-only", url], ["--cd", url]]


def test_z_repository_path_lookup_failure_does_not_cd_or_clone(z_alias):
    calls = []
    z_alias["aliases"]["wcl"] = lambda args, **_: (calls.append(args) or 2)
    assert z_alias["_wes_z_alias"](["https://github.com/org/repo.git"]) == 2
    assert len(calls) == 1


def test_z_plain_query_still_resolves_fish_history(z_alias, tmp_path):
    calls = []
    z_alias["_wes_fish_z"].resolve = lambda args: (calls.append(args) or tmp_path)
    z_alias["_xonsh_cd"] = lambda args: (calls.append(args), None, 0)
    assert z_alias["_wes_z_alias"](["Qwen3-ASR"]) == 0
    assert calls == [["Qwen3-ASR"], [str(tmp_path)]]


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
        "__z --echo $argv",
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


def test_non_jumping_operation_passes_each_argument_to_fish_z():
    runner = RecordingRunner(completed())

    FishZ(runner=runner, fish_executable="/test/fish").run(
        ["--list", "ans", "ans"]
    )

    assert runner.calls[0][0] == [
        "/test/fish",
        "-c",
        "__z $argv",
        "--",
        "--list",
        "ans",
        "ans",
    ]


def test_entries_parse_frecency_and_skip_missing_directories(tmp_path):
    present = tmp_path / "ask-openai.nvim"
    present.mkdir()
    runner = RecordingRunner(
        completed(stdout=f"42.5  {present}\n8 /definitely/missing\nnot-a-score nope\n")
    )

    entries = FishZ(runner=runner, fish_executable="/test/fish").entries()

    assert [(entry.path, entry.frecency) for entry in entries] == [(present, 42.5)]
    assert runner.calls[0][0] == ["/test/fish", "-c", "__z --list"]


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
