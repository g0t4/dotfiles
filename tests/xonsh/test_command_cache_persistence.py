import os
from pathlib import Path
import subprocess

from xonsh.commands_cache import CommandsCache
from xonsh.environ import Env


ROOT = Path(__file__).parents[2]
ENV_RC = ROOT / ".config/xonsh/rc.d/00-env.xsh"


def executable(path):
    path.write_text("#!/bin/sh\n")
    path.chmod(0o755)
    return path


def bump_directory_mtime(path):
    current = path.stat().st_mtime_ns
    os.utime(path, ns=(current + 1_000_000, current + 1_000_000))


def test_rc_enables_persistent_command_cache(tmp_path):
    completed = subprocess.run(
        [
            "xonsh",
            "--no-rc",
            "-c",
            f"source {ENV_RC}; assert $COMMANDS_CACHE_SAVE_INTERMEDIATE is True",
        ],
        capture_output=True,
        text=True,
        env=os.environ | {"HOME": str(tmp_path)},
    )

    assert completed.returncode == 0, completed.stderr


def test_persistent_cache_tracks_path_contents_and_path_replacement(tmp_path):
    cache_directory = tmp_path / "cache"
    cache_directory.mkdir()
    first_bin = tmp_path / "first-bin"
    second_bin = tmp_path / "second-bin"
    first_bin.mkdir()
    second_bin.mkdir()
    first = executable(first_bin / "first-command")
    executable(second_bin / "second-command")
    env = Env(
        PATH=[str(first_bin)],
        XONSH_CACHE_DIR=str(cache_directory),
        COMMANDS_CACHE_SAVE_INTERMEDIATE=True,
    )

    initial = CommandsCache(env, aliases={})
    assert "first-command" in initial
    assert initial.cache_file.is_file()

    reused = CommandsCache(env, aliases={})
    assert "first-command" in reused

    executable(first_bin / "added-command")
    bump_directory_mtime(first_bin)
    assert "added-command" in reused

    first.unlink()
    bump_directory_mtime(first_bin)
    assert "first-command" not in reused

    env["PATH"] = [str(second_bin)]
    assert "second-command" in reused
    assert "added-command" not in reused
