import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]


def test_recording_and_shorts_modes_change_current_xonsh_environment():
    env = os.environ.copy()
    env["XONSH_LOG"] = os.devnull
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    always = ROOT / ".config/xonsh/rc.d/always.xsh"
    command = (
        f"source {ai}; source {always}; "
        "_recording; print($XONSH_AI_AUTOSUGGEST); "
        "_not_recording; print($XONSH_AI_AUTOSUGGEST); "
        "_shorts; print($wes_recording_youtube_shorts_need_small_prompt); "
        "_not_shorts; print('wes_recording_youtube_shorts_need_small_prompt' "
        "in ${...})"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.splitlines() == ["False", "True", "True", "False"]


def test_recording_restores_disabled_autosuggest_preference():
    env = os.environ.copy()
    env["XONSH_LOG"] = os.devnull
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    always = ROOT / ".config/xonsh/rc.d/always.xsh"
    command = (
        f"source {ai}; source {always}; "
        "$XONSH_AI_AUTOSUGGEST = False; "
        "_recording; _not_recording; print($XONSH_AI_AUTOSUGGEST)"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.strip() == "False"
