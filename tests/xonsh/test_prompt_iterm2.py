import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]


def run_xonsh(command, tmp_path):
    env = os.environ.copy()
    env["HOME"] = str(tmp_path)
    env["XONSH_CONFIG_DIR"] = str(ROOT / ".config/xonsh")
    return subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )


def test_disabled_iterm2_integration_does_not_wrap_prompt(tmp_path):
    iterm2 = ROOT / ".config/xonsh/rc.d/iterm2.xsh"
    prompt = ROOT / ".config/xonsh/rc.d/prompt.xsh"
    completed = run_xonsh(
        f"source {iterm2}; source {prompt}; "
        "assert not $ITERM2_INTEGRATION; "
        "assert 'iterm2_prompt_start' not in $PROMPT; "
        "assert 'iterm2_prompt_end' not in $PROMPT",
        tmp_path,
    )

    assert completed.returncode == 0, completed.stderr


def test_enabled_iterm2_integration_registers_fields_and_wraps_prompt(tmp_path):
    iterm2 = ROOT / ".config/xonsh/rc.d/iterm2.xsh"
    prompt = ROOT / ".config/xonsh/rc.d/prompt.xsh"
    completed = run_xonsh(
        "$XONSH_INTERACTIVE = True; $TERM = 'xterm-256color'; "
        "$TERM_PROGRAM = 'iTerm.app'; "
        f"source {iterm2}; source {prompt}; "
        "assert $ITERM2_INTEGRATION; "
        "assert 'iterm2_prompt_start' in $PROMPT_FIELDS; "
        "assert 'iterm2_prompt_end' in $PROMPT_FIELDS; "
        "assert 'iterm2_prompt_start' in $PROMPT; "
        "assert 'iterm2_prompt_end' in $PROMPT",
        tmp_path,
    )

    assert completed.returncode == 0, completed.stderr
