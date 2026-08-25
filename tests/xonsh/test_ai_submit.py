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
    env["XONSH_LOG"] = os.devnull
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr


def test_iterm_esc_plus_alt_tab_decodes_as_one_regeneration_key():
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    command = (
        f"source {ai}; "
        "from prompt_toolkit.input.vt100_parser import Vt100Parser; "
        "from prompt_toolkit.keys import Keys; "
        "pressed = []; parser = Vt100Parser(pressed.append); "
        "parser.feed('\\x1b\\t'); "
        "assert [key.key for key in pressed] == [Keys.F24]"
    )
    env = os.environ.copy()
    env["XONSH_LOG"] = os.devnull

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr


def test_semantic_history_is_included_as_a_separate_prompt_signal():
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    command = (
        f"source {ai}; "
        "from prompt_toolkit.buffer import Buffer; "
        "buffer = Buffer(); buffer.text = 'git st'; buffer.cursor_position = 6; "
        "body = _ai_autosuggester._request_body("
        "buffer, buffer.document, ['git status', 'git diff --staged']); "
        "content = body['messages'][1]['content']; "
        "assert 'semantic_history_commands_most_relevant_first=' in content; "
        "assert 'git diff --staged' in content"
    )
    env = os.environ.copy()
    env["XONSH_LOG"] = os.devnull

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
