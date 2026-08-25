import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]


def test_submit_cancels_active_prediction_and_blocks_replacement_request():
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    command = (
        f"source {abbreviations}; source {ai}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from types import SimpleNamespace; "
        "state = {'cancelled': False}; "
        "task = SimpleNamespace(done=lambda: False, "
        "cancel=lambda: state.__setitem__('cancelled', True)); "
        "buffer = Buffer(); buffer.text = 'git status'; "
        "_ai_autosuggester._active_task = task; "
        "_ai_autosuggester._active_request_id = 42; "
        "_cancel_ai_autosuggestion_for_submit(buffer); "
        "assert state['cancelled']; assert buffer.suggestion is None; "
        "assert _ai_autosuggester._submitting_buffer is buffer; "
        "result = __import__('asyncio').run("
        "_ai_autosuggester.get_suggestion_async(buffer, buffer.document)); "
        "assert result is None"
    )
    env = os.environ.copy()
    env["XONSH_AI_AUTOSUGGEST_LOG"] = os.devnull
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
