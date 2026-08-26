import asyncio
import signal
import subprocess
from pathlib import Path
from types import SimpleNamespace


ROOT = Path(__file__).parents[2]
LIB = ROOT / ".config/xonsh/lib"


def _module():
    import sys

    sys.path.insert(0, str(LIB))
    import wes_voice_intent

    return wes_voice_intent


class FakeRecorder:
    def __init__(self):
        self.returncode = None
        self.stderr = None
        self.signal = None
        self.stdin = SimpleNamespace(
            written=b"",
            write=lambda value: setattr(self.stdin, "written", value),
            flush=lambda: None,
            close=lambda: None,
        )

    def poll(self):
        return self.returncode

    def send_signal(self, value):
        self.signal = value

    def wait(self, _timeout):
        self.returncode = 255
        return self.returncode


def test_voice_intent_records_transcribes_and_removes_audio(tmp_path, monkeypatch):
    voice_module = _module()
    recorder = FakeRecorder()
    model = tmp_path / "model.bin"
    model.touch()
    monkeypatch.setattr(voice_module.tempfile, "NamedTemporaryFile", lambda **_: SimpleNamespace(
        name=str(tmp_path / "voice.wav"), close=lambda: None
    ))
    commands = []

    def transcribe(command, **_):
        commands.append(command)
        return subprocess.CompletedProcess(command, 0, "  cut this from one to two\n", "")

    voice = voice_module.VoiceIntent(
        model=model,
        recorder_factory=lambda *_, **__: recorder,
        transcriber=transcribe,
    )
    audio_path = voice.start()
    audio_path.touch()

    async def finish():
        task = voice.stop_and_transcribe()
        assert recorder.stdin.written == b"q\n"
        assert await task == "cut this from one to two"

    asyncio.run(finish())
    assert not audio_path.exists()
    assert Path(commands[0][0]).name == "whisper-cli"
    assert str(model) in commands[0]


def test_insert_transcript_preserves_existing_command():
    voice_module = _module()

    class Buffer:
        document = SimpleNamespace(text_before_cursor="ffmpeg -i clip.mov")
        inserted = None

        def insert_text(self, value):
            self.inserted = value

    buffer = Buffer()
    voice_module.insert_transcript(buffer, "cut from 1:12 to 1:42")
    assert buffer.inserted == " cut from 1:12 to 1:42"


def test_resolve_executable_finds_homebrew_when_path_does_not(monkeypatch):
    voice_module = _module()
    monkeypatch.setattr(voice_module.shutil, "which", lambda _: None)
    original_is_file = Path.is_file
    monkeypatch.setattr(
        Path,
        "is_file",
        lambda path: str(path) == "/opt/homebrew/bin/ffmpeg" or original_is_file(path),
    )
    monkeypatch.setattr(voice_module.os, "access", lambda *_: True)

    assert voice_module.resolve_executable("ffmpeg") == "/opt/homebrew/bin/ffmpeg"


def test_shift_f7_binding_is_registered():
    config = ROOT / ".config/xonsh/rc.d/voice-intent.xsh"
    command = (
        f"source {config}; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.keys import Keys; "
        "bindings = KeyBindings(); events.on_ptk_create.fire(bindings=bindings); "
        "assert any(binding.keys == (Keys.F19,) for binding in bindings.bindings); "
        "assert any(binding.keys == (Keys.F20,) for binding in bindings.bindings)"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )
    assert completed.returncode == 0, completed.stderr
