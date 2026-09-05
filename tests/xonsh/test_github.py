import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))


def test_github_rc_loads_aliases_and_abbreviations():
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    github = ROOT / ".config/xonsh/rc.d/github.xsh"
    command = (
        f"source {abbreviations}; source {github}; "
        "assert callable(aliases['gh_repo_create_private']); "
        "assert callable(aliases['copy_github_link']); "
        "assert any(a.trigger == 'ghrc' for a in wes_abbreviations.XONSH_ABBREVIATIONS.abbreviations)"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )
    assert completed.returncode == 0, completed.stderr


def test_github_cli_resolves_from_live_xonsh_path(tmp_path):
    executable = tmp_path / "gh"
    executable.write_text("#!/bin/sh\nexit 0\n")
    executable.chmod(0o755)
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    github = ROOT / ".config/xonsh/rc.d/github.xsh"
    command = (
        f"source {abbreviations}; source {github}; "
        f"$PATH = ['{tmp_path}']; "
        f"assert _github_executable('gh') == '{executable}'"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
    )
    assert completed.returncode == 0, completed.stderr
