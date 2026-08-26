import asyncio
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
LIB = ROOT / ".config/xonsh/lib"
sys.path.insert(0, str(LIB))

from wes_voice_stream_worker import transcript_text  # noqa: E402


def test_transcript_text_normalizes_segments():
    class Segment:
        def __init__(self, text):
            self.text = text

    assert transcript_text([Segment(" hello   there "), Segment(" world")]) == (
        "hello there world"
    )
    assert transcript_text([Segment(" [BLANK_AUDIO] ")]) == ""


def test_live_voice_client_reads_partial_and_final():
    from wes_live_voice import LiveVoice

    script = (
        "import json; "
        "print(json.dumps({'type':'ready'}), flush=True); "
        "print(json.dumps({'type':'partial','text':'git sta'}), flush=True); "
        "print(json.dumps({'type':'final','text':'git status'}), flush=True)"
    )
    partials = []
    voice = LiveVoice([sys.executable, "-c", script], partials.append)

    async def run():
        await voice.start()
        await voice.process.wait()
        await voice.reader_task

    asyncio.run(run())
    assert partials == ["git sta"]
    assert voice.final_text == "git status"


def test_shift_f9_binding_is_registered():
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    voice = ROOT / ".config/xonsh/rc.d/voice-intent.xsh"
    command = (
        f"source {ai}; source {voice}; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.keys import Keys; "
        "bindings = KeyBindings(); events.on_ptk_create.fire(bindings=bindings); "
        "assert any(binding.keys == (Keys.F21,) for binding in bindings.bindings)"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )
    assert completed.returncode == 0, completed.stderr


def test_live_preview_puts_command_first():
    config = ROOT / ".config/xonsh/rc.d/voice-intent.xsh"
    command = (
        f"source {config}; "
        "_live_voice_state.update(status='listening', transcript='cut the video', "
        "command='ffmpeg -i test.mp4 out.mp4'); "
        "rendered = _live_voice_preview_text(); "
        "assert rendered.index('ffmpeg') < rendered.index('cut the video')"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )
    assert completed.returncode == 0, completed.stderr


def test_live_preview_changes_color_when_command_is_ready():
    config = ROOT / ".config/xonsh/rc.d/voice-intent.xsh"
    command = (
        f"source {config}; "
        "_live_voice_state.update(status='listening', transcript='cut video', "
        "command='', phase='transcribing'); "
        "working = _live_voice_preview_fragments(); "
        "_live_voice_state.update(command='ffmpeg -i in.mp4 out.mp4', phase='ready'); "
        "ready = _live_voice_preview_fragments(); "
        "assert '#ffd75f' in working[0][0]; "
        "assert '#87ffaf' in ready[0][0]; "
        "assert '✓' in ready[0][1]"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )
    assert completed.returncode == 0, completed.stderr


def test_live_preview_wraps_prompt_layout_in_cursor_float():
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    voice = ROOT / ".config/xonsh/rc.d/voice-intent.xsh"
    command = (
        f"source {ai}; source {voice}; "
        "from prompt_toolkit import PromptSession; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.layout.containers import FloatContainer; "
        "session = PromptSession(); bindings = KeyBindings(); "
        "events.on_ptk_create.fire(bindings=bindings, prompter=session); "
        "assert isinstance(session.app.layout.container, FloatContainer); "
        "assert session.app.layout.container.floats[-1].xcursor; "
        "assert session.app.layout.container.floats[-1].ycursor"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )
    assert completed.returncode == 0, completed.stderr


def test_enter_accepts_visible_live_command_without_submitting():
    ai = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    voice = ROOT / ".config/xonsh/rc.d/voice-intent.xsh"
    command = (
        f"source {ai}; source {voice}; "
        "from prompt_toolkit import PromptSession; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.keys import Keys; "
        "from types import SimpleNamespace; "
        "session = PromptSession(); bindings = KeyBindings(); "
        "events.on_ptk_create.fire(bindings=bindings, prompter=session); "
        "accept = next(binding.handler for binding in bindings.bindings "
        "if binding.keys == (Keys.ControlM,) and binding.eager()); "
        "_live_voice = SimpleNamespace(running=True); "
        "_live_voice_state['command'] = 'du -ah . | sort -rh'; "
        "buffer = Buffer(); app = SimpleNamespace(current_buffer=buffer, "
        "create_background_task=lambda task: task.close(), invalidate=lambda: None); "
        "accept(SimpleNamespace(app=app)); "
        "assert buffer.text == 'du -ah . | sort -rh'"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )
    assert completed.returncode == 0, completed.stderr
