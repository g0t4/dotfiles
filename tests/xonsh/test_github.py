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
        "assert any(a.trigger == 'ghrc' for a in XONSH_ABBREVIATIONS.abbreviations)"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )
    assert completed.returncode == 0, completed.stderr
