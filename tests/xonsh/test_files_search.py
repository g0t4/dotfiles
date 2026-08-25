import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]


def test_ripgrep_searches_hidden_config_without_an_inherited_fish_environment():
    env = os.environ.copy()
    env.pop("RIPGREP_CONFIG_PATH", None)
    env["XONSH_CONFIG_DIR"] = str(ROOT / ".config/xonsh")
    config_rc = ROOT / ".config/xonsh/rc.d/config.xsh"
    rc = ROOT / ".config/xonsh/rc.d/files-search-specific.xsh"

    completed = subprocess.run(
        [
            "xonsh",
            "--no-rc",
            "-c",
            f"source {config_rc}; source {rc}; rg viinsert",
        ],
        capture_output=True,
        text=True,
        env=env,
        cwd=ROOT,
    )

    assert completed.returncode == 0, completed.stderr
    hidden_matches = [
        line
        for line in completed.stdout.splitlines()
        if line.startswith(".config/xonsh/")
    ]
    assert len(hidden_matches) == 6
