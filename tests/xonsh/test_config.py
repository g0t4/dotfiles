import os
import platform
import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]


def test_common_variables_do_not_require_an_inherited_shell_environment():
    env = os.environ.copy()
    for name in (
        "IS_MACOS",
        "IS_LINUX",
        "IS_ARCH",
        "WES_REPOS",
        "WES_BOOTSTRAP",
        "WES_DOTFILES",
        "WES_ASK_CAPTURES",
        "XDG_STATE_HOME",
        "XONSH_LOG",
        "XONSH_LOG_RICH",
        "VI_MODE",
    ):
        env.pop(name, None)
    env["XONSH_CONFIG_DIR"] = str(ROOT / ".config/xonsh")
    rc = ROOT / ".config/xonsh/rc.d/00-env.xsh"
    command = (
        f"source {rc}; "
        "print($IS_MACOS); print($IS_LINUX); print($IS_ARCH); "
        "print($WES_REPOS); print($WES_BOOTSTRAP); "
        "print($WES_DOTFILES); print($WES_ASK_CAPTURES); "
        "print($VI_MODE)"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
    home = Path.home()
    is_macos = platform.system() == "Darwin"
    assert completed.stdout.splitlines() == [
        "true" if is_macos else "false",
        "false" if is_macos else "true",
        "true"
        if not is_macos and Path("/etc/arch-release").is_file()
        else "false",
        str(home / "repos"),
        str(home / "repos/wes-config/wes-bootstrap"),
        str(home / "repos/github/g0t4/dotfiles"),
        str(home / ".local/state/nvim/ask-openai"),
        "True",
    ]
