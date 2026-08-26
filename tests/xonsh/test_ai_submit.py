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


def test_ai_toggle_off_disables_all_autosuggestions():
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    command = (
        f"source {ai}; "
        "from prompt_toolkit.buffer import Buffer; "
        "buffer = Buffer(); buffer.text = 'git st'; "
        "$XONSH_AI_AUTOSUGGEST = False; $AUTO_SUGGEST = True; "
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


def test_history_fallback_honors_xonsh_auto_suggest_setting():
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    command = (
        f"source {ai}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.auto_suggest import Suggestion; "
        "from types import SimpleNamespace; "
        "buffer = Buffer(); buffer.text = 'git st'; "
        "_ai_autosuggester._history = SimpleNamespace("
        "get_suggestion=lambda buffer, document: Suggestion('atus')); "
        "$AUTO_SUGGEST = False; "
        "assert _ai_autosuggester._history_suggestion(buffer, buffer.document) is None; "
        "$AUTO_SUGGEST = True; "
        "assert _ai_autosuggester._history_suggestion(buffer, buffer.document).text == 'atus'"
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


def test_prompt_snout_tracks_ai_autosuggest_master_toggle():
    prompt = ROOT / ".config/xonsh/rc.d/prompt.xsh"
    command = (
        f"source {prompt}; "
        "$XONSH_AI_AUTOSUGGEST = True; assert _prompt_ai_snout() == ' 🐽'; "
        "$XONSH_AI_AUTOSUGGEST = False; assert _prompt_ai_snout() == ''; "
        "assert '{wes_ai_snout}' in $PROMPT"
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


def test_shift_f6_refreshes_prompt_after_hiding_snout():
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    command = (
        f"source {ai}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.keys import Keys; "
        "from types import SimpleNamespace; "
        "bindings = KeyBindings(); prompter = SimpleNamespace(message=None); "
        "events.on_ptk_create.fire(bindings=bindings, prompter=prompter); "
        "handler = next(binding.handler for binding in bindings.bindings "
        "if binding.keys == (Keys.F18,)); "
        "shell = SimpleNamespace(prompt_tokens=lambda: [('prompt', 'without snout')]); "
        "__xonsh__.shell = SimpleNamespace(shell=shell); "
        "state = {'invalidated': False}; "
        "app = SimpleNamespace(invalidate=lambda: state.__setitem__('invalidated', True)); "
        "event = SimpleNamespace(current_buffer=Buffer(), app=app); "
        "$XONSH_AI_AUTOSUGGEST = True; handler(event); "
        "assert $XONSH_AI_AUTOSUGGEST is False; "
        "assert prompter.message == [('prompt', 'without snout')]; "
        "assert state['invalidated']"
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
