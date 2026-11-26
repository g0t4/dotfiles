import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(os.getenv("WES_DOTFILES"))


def test_recording_and_shorts_modes_change_current_xonsh_environment():
    env = os.environ.copy()
    env["XONSH_LOG"] = os.devnull
    always = REPO_ROOT / ".config/xonsh/rc.d/always.xsh"
    command = (
        f"source {always}; "
        "_recording; "
        "_not_recording; "
        "_shorts; print($wes_recording_youtube_shorts_need_small_prompt); "
        "_not_shorts; print('wes_recording_youtube_shorts_need_small_prompt' "
        "in @.env)"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.splitlines() == ["True", "False"]
