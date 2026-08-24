import os
import stat
import sys
from pathlib import Path

import pytest


XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))

from wes_fish_executable import find_fish  # noqa: E402


def test_find_fish_uses_explicit_live_xonsh_path_before_process_path(tmp_path):
    live_bin = tmp_path / "live-bin"
    live_bin.mkdir()
    fish = live_bin / "fish"
    fish.write_text("#!/bin/sh\n")
    fish.chmod(fish.stat().st_mode | stat.S_IXUSR)

    assert find_fish([str(live_bin)], process_path="/usr/bin:/bin") == str(fish)


def test_find_fish_falls_back_to_process_path(tmp_path):
    process_bin = tmp_path / "process-bin"
    process_bin.mkdir()
    fish = process_bin / "fish"
    fish.write_text("#!/bin/sh\n")
    fish.chmod(fish.stat().st_mode | stat.S_IXUSR)

    assert find_fish([], process_path=str(process_bin)) == str(fish)


def test_find_fish_reports_paths_checked(monkeypatch):
    monkeypatch.setattr(os.path, "isfile", lambda _path: False)
    with pytest.raises(FileNotFoundError, match="Xonsh PATH"):
        find_fish([], process_path="", standard_paths=())
