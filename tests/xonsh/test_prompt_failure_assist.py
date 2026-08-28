import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]
PROMPT = ROOT / ".config/xonsh/rc.d/prompt.xsh"


def run_xonsh(assertions):
    env = os.environ.copy()
    env["XONSH_CONFIG_DIR"] = str(ROOT / ".config/xonsh")
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", f"source {PROMPT}; {assertions}"],
        capture_output=True,
        text=True,
        env=env,
    )
    assert completed.returncode == 0, completed.stderr


def test_two_consecutive_failures_show_assist_message():
    run_xonsh(
        "_wes_prompt_record_status('first', 1); _wes_prompt_choose_status(); "
        "assert _prompt_failure_assist() == ''; "
        "_wes_prompt_record_status('second', 2); _wes_prompt_choose_status(); "
        "assert 'two commands failed in a row' in _prompt_failure_assist()"
    )


def test_success_resets_failure_streak():
    run_xonsh(
        "_wes_prompt_record_status('first', 1); "
        "_wes_prompt_record_status('second', 1); "
        "_wes_prompt_record_status('success', 0); _wes_prompt_choose_status(); "
        "assert _prompt_state['failure_streak'] == 0; "
        "assert _prompt_failure_assist() == ''"
    )


def test_ai_master_toggle_suppresses_assist_message():
    run_xonsh(
        "_wes_prompt_record_status('first', 1); "
        "_wes_prompt_record_status('second', 1); _wes_prompt_choose_status(); "
        "$XONSH_AI_AUTOSUGGEST = False; "
        "assert _prompt_failure_assist() == ''"
    )
