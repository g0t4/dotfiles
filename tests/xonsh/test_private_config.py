import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]
CONFIG = ROOT / ".config/xonsh/rc.d/00-env.xsh"
PRIVATE = ROOT / ".config/xonsh/rc.d/zz-private.xsh"


def run_bridge(bootstrap: Path):
    command = (
        f"source {CONFIG}; "
        f"$WES_BOOTSTRAP = {str(bootstrap)!r}; "
        f"source {PRIVATE}; "
        "print(${...}.get('PRIVATE_CONFIG_PROBE', 'missing'))"
    )
    return subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
    )


def test_private_config_is_optional(tmp_path):
    completed = run_bridge(tmp_path / "not-installed")

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.strip() == "missing"


def test_private_config_sources_only_the_private_entrypoint(tmp_path):
    entrypoint = tmp_path / "xonsh/config-private.xsh"
    entrypoint.parent.mkdir(parents=True)
    entrypoint.write_text("$PRIVATE_CONFIG_PROBE = 'loaded'\n")

    completed = run_bridge(tmp_path)

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.strip() == "loaded"
