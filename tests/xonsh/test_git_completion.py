import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]
XONSH_LIB = ROOT / ".config/xonsh/lib"
ABBREVIATIONS_RC = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
GIT_RC = ROOT / ".config/xonsh/rc.d/git.xsh"


def _xonsh_env() -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(XONSH_LIB)
    env["XONSH_LOG"] = os.devnull
    return env


def _completion_command(line: str) -> str:
    return f"source {ABBREVIATIONS_RC}; source {GIT_RC}; completer complete '{line}'"


def _git(repo: Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True)


def _init_repo(tmp_path: Path) -> Path:
    repo = tmp_path / "repo"
    repo.mkdir()
    _git(repo, "init", "-q")
    (repo / "deeply/nested").mkdir(parents=True)
    (repo / "deeply/nested/tracked-foo.txt").write_text("original")
    (repo / "clean-foo.txt").write_text("clean")
    _git(repo, "add", ".")
    _git(
        repo,
        "-c",
        "user.name=Xonsh Test",
        "-c",
        "user.email=xonsh@example.invalid",
        "commit",
        "-qm",
        "initial",
    )
    (repo / "deeply/nested/tracked-foo.txt").write_text("modified")
    (repo / "another/deep").mkdir(parents=True)
    (repo / "another/deep/untracked-foo.txt").write_text("untracked")
    return repo


def test_git_add_tab_completion_matches_nested_dirty_paths_by_any_fragment(tmp_path):
    repo = _init_repo(tmp_path)
    command = _completion_command("git add foo")
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        cwd=repo,
        capture_output=True,
        text=True,
        env=_xonsh_env(),
    )

    assert completed.returncode == 0, completed.stderr
    assert "deeply/nested/tracked-foo.txt" in completed.stdout
    assert "another/deep/untracked-foo.txt" in completed.stdout
    assert "clean-foo.txt" not in completed.stdout


def test_git_add_candidates_cover_whole_repo_when_invoked_from_subdirectory(tmp_path):
    repo = _init_repo(tmp_path)
    command = _completion_command("git add untracked")

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        cwd=repo / "deeply",
        capture_output=True,
        text=True,
        env=_xonsh_env(),
    )

    assert completed.returncode == 0, completed.stderr
    assert "../another/deep/untracked-foo.txt" in completed.stdout


def test_git_add_option_completion_is_left_to_existing_git_completer(tmp_path):
    repo = _init_repo(tmp_path)
    command = _completion_command("git add --ver")

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        cwd=repo,
        capture_output=True,
        text=True,
        env=_xonsh_env(),
    )

    assert completed.returncode == 0, completed.stderr
    assert "--verbose" in completed.stdout
