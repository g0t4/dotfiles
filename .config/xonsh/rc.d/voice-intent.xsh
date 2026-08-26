"""Native push-to-talk voice input for the Xonsh command buffer."""

import asyncio
import sys
from pathlib import Path

from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.filters import Condition
from prompt_toolkit.keys import Keys
from prompt_toolkit.layout.containers import (
    ConditionalContainer,
    Float,
    FloatContainer,
    Window,
)
from prompt_toolkit.layout.controls import FormattedTextControl


_voice_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_voice_lib) not in sys.path:
    sys.path.insert(0, str(_voice_lib))

from wes_live_voice import LiveVoice, bounded_command_result
from wes_voice_intent import DEFAULT_MODEL, VoiceIntent, insert_transcript, resolve_executable


${...}.setdefault("XONSH_VOICE_AUDIO_DEVICE", "0")
${...}.setdefault("XONSH_VOICE_MODEL", str(DEFAULT_MODEL))
${...}.setdefault(
    "XONSH_LIVE_VOICE_PYTHON",
    str(Path.home() / "repos/github/g0t4/auto-edit-suggests/.venv/bin/python"),
)
${...}.setdefault(
    "XONSH_LIVE_VOICE_MODEL",
    str(Path.home() / "repos/github/ggml-org/whisper.cpp/models/ggml-tiny.en.bin"),
)
${...}.setdefault("XONSH_LIVE_VOICE_INTERVAL_MS", 500)
_voice_intent = VoiceIntent(
    audio_device=str(${...}["XONSH_VOICE_AUDIO_DEVICE"]),
    model=Path(${...}["XONSH_VOICE_MODEL"]),
)
_live_voice_state = {
    "transcript": "",
    "command": "",
    "status": "",
    "phase": "idle",
}
_live_voice = None
_live_voice_ai_task = None
_persistent_voice_enabled = False
_persistent_last_result = None
_persistent_capture_settings = None


def _set_persistent_capture(enabled):
    global _persistent_capture_settings
    names = ("XONSH_CAPTURE_ALWAYS", "XONSH_STORE_STDOUT")
    if enabled:
        _persistent_capture_settings = {
            name: (name in ${...}, ${...}.get(name)) for name in names
        }
        for name in names:
            ${...}[name] = True
        return
    if _persistent_capture_settings is None:
        return
    for name, (existed, value) in _persistent_capture_settings.items():
        if existed:
            ${...}[name] = value
        elif name in ${...}:
            del ${...}[name]
    _persistent_capture_settings = None


@events.on_postcommand
def _wes_voice_remember_command_result(cmd, rtn, out=None, **_):
    global _persistent_last_result
    if not _persistent_voice_enabled:
        return
    _persistent_last_result = bounded_command_result(cmd, rtn, out)
    if _live_voice is not None and _live_voice.running:
        _live_voice.reset_nowait()
    _live_voice_state.update(
        status="listening — speak your next command",
        transcript="",
        command="",
        phase="transcribing",
    )


def _live_voice_preview_text():
    status = _live_voice_state["status"]
    transcript = _live_voice_state["transcript"]
    command = _live_voice_state["command"]
    if not status:
        return ""
    if command:
        return f"❯ {command}  │ 🎙 {transcript}"
    if transcript:
        return f"🎙 {status}  │ {transcript}"
    return f"🎙 {status}"


def _live_voice_preview_fragments():
    phase = _live_voice_state["phase"]
    text = _live_voice_preview_text()
    if phase == "ready":
        return [("bg:#12351d #87ffaf bold", f" ✓ {text} ")]
    if phase == "error":
        return [("bg:#4a1111 #ff8787 bold", f" × {text} ")]
    if phase in {"loading", "finalizing"}:
        return [("bg:#241744 #d7afff bold", f" … {text} ")]
    return [("bg:#3a2d00 #ffd75f bold", f" ● {text} ")]


async def _voice_notice(message):
    await run_in_terminal(lambda: print(message))


async def _voice_finish(buffer, task, app):
    try:
        transcript = await task
    except asyncio.CancelledError:
        return
    except Exception as error:
        await _voice_notice(f"voice: {error}")
        return
    if not transcript:
        await _voice_notice("voice: no speech detected")
        return
    insert_transcript(buffer, transcript)
    app.invalidate()


async def _voice_finish_as_command(buffer, task, app):
    try:
        transcript = await task
    except asyncio.CancelledError:
        return
    except Exception as error:
        await _voice_notice(f"voice: {error}")
        return
    if not transcript:
        await _voice_notice("voice: no speech detected")
        return
    await _voice_notice(f"voice: {transcript}\n🤖 generating command…")
    try:
        command = await _ai_autosuggester.command_from_intent(buffer, transcript)
    except asyncio.CancelledError:
        return
    except Exception as error:
        await _voice_notice(f"voice AI: {error}")
        return
    if not command:
        await _voice_notice("voice AI: no command generated")
        return
    buffer.save_to_undo_stack()
    buffer.text = command
    buffer.cursor_position = len(command)
    app.invalidate()


@events.on_ptk_create
def _wes_voice_keybinding(bindings, prompter=None, **_):
    if prompter is not None and not getattr(
        prompter.app.layout, "_wes_live_voice_preview", False
    ):
        preview = ConditionalContainer(
            Window(
                FormattedTextControl(_live_voice_preview_fragments),
                dont_extend_width=True,
                wrap_lines=True,
                style="bg:#202020 #f8f8f2",
            ),
            filter=Condition(lambda: bool(_live_voice_state["status"])),
        )
        prompter.app.layout.container = FloatContainer(
            content=prompter.app.layout.container,
            floats=[
                Float(
                    xcursor=True,
                    ycursor=True,
                    content=preview,
                    transparent=False,
                    z_index=20,
                )
            ],
        )
        prompter.app.layout._wes_live_voice_preview = True

    voice_mode = {"value": "text"}

    def toggle(event, mode):
        if _voice_intent.recording:
            selected_mode = voice_mode["value"]
            task = _voice_intent.stop_and_transcribe()
            asyncio.create_task(_voice_notice("🎙 transcribing…"))
            finish = (
                _voice_finish_as_command
                if selected_mode == "command"
                else _voice_finish
            )
            asyncio.create_task(finish(event.current_buffer, task, event.app))
            return
        if _voice_intent.transcribing:
            asyncio.create_task(_voice_notice("voice: transcription already running"))
            return
        try:
            _voice_intent.start()
        except Exception as error:
            asyncio.create_task(_voice_notice(f"voice: {error}"))
            return
        voice_mode["value"] = mode
        label = " → AI command" if mode == "command" else ""
        stop_key = "Shift-F8" if mode == "command" else "Shift-F7"
        asyncio.create_task(
            _voice_notice(f"🎙 recording{label} — {stop_key} to stop")
        )

    # Prompt Toolkit maps Shift-F7 to F19, alongside Shift-F6/F18 for the AI
    # autosuggest toggle. Terminals do not normally report key release, so the
    # portable baseline is press once to record and press again to transcribe.
    @bindings.add(Keys.F19, eager=True, save_before=lambda event: False)
    def _toggle_voice(event):
        toggle(event, "text")

    @bindings.add(Keys.F20, eager=True, save_before=lambda event: False)
    def _toggle_voice_command(event):
        # Shift-F8: persistent conversational mode. The model and microphone
        # remain active across submitted commands until Shift-F8 is pressed
        # again; Enter executes the green preview directly.
        global _live_voice, _live_voice_ai_task, _persistent_voice_enabled

        async def generate_persistent(buffer, transcript, app):
            global _live_voice_ai_task
            try:
                await asyncio.sleep(0.35)
                command = await _ai_autosuggester.command_from_intent(
                    buffer,
                    transcript,
                    service="xonsh_persistent_voice_command",
                    execution_context=_persistent_last_result,
                )
            except asyncio.CancelledError:
                return
            except Exception as error:
                _live_voice_state.update(
                    status=f"AI error: {error}", phase="error"
                )
                app.invalidate()
                return
            if _live_voice_state["transcript"] == transcript:
                _live_voice_state["command"] = command
                _live_voice_state["phase"] = "ready" if command else "transcribing"
                app.invalidate()

        def on_persistent_partial(transcript):
            global _live_voice_ai_task
            _live_voice_state.update(
                transcript=transcript,
                command="",
                status="persistent voice — Shift-F8 to stop",
                phase="transcribing",
            )
            if _live_voice_ai_task is not None and not _live_voice_ai_task.done():
                _live_voice_ai_task.cancel()
            _live_voice_ai_task = event.app.create_background_task(
                generate_persistent(event.app.current_buffer, transcript, event.app)
            )
            event.app.invalidate()

        async def start_persistent():
            global _live_voice, _persistent_voice_enabled
            worker = Path($XONSH_CONFIG_DIR) / "lib/wes_voice_stream_worker.py"
            command = [
                str(${...}["XONSH_LIVE_VOICE_PYTHON"]),
                str(worker),
                "--model",
                str(${...}["XONSH_LIVE_VOICE_MODEL"]),
                "--ffmpeg",
                resolve_executable("ffmpeg"),
                "--audio-device",
                str(${...}["XONSH_VOICE_AUDIO_DEVICE"]),
                "--interval-ms",
                str(${...}["XONSH_LIVE_VOICE_INTERVAL_MS"]),
            ]
            _set_persistent_capture(True)
            _persistent_voice_enabled = True
            _live_voice = LiveVoice(command, on_persistent_partial)
            _live_voice_state.update(
                status="loading persistent Tiny…",
                transcript="",
                command="",
                phase="loading",
            )
            event.app.invalidate()
            try:
                await _live_voice.start()
            except Exception as error:
                _persistent_voice_enabled = False
                _set_persistent_capture(False)
                _live_voice_state.update(status=f"voice error: {error}", phase="error")
                event.app.invalidate()
                return
            _live_voice_state.update(
                status="persistent voice — Shift-F8 to stop",
                phase="transcribing",
            )
            event.app.invalidate()

        async def stop_persistent():
            global _live_voice_ai_task, _persistent_voice_enabled
            _persistent_voice_enabled = False
            if _live_voice_ai_task is not None and not _live_voice_ai_task.done():
                _live_voice_ai_task.cancel()
            try:
                await _live_voice.stop()
            except Exception as error:
                await _voice_notice(f"persistent voice cleanup: {error}")
            finally:
                _set_persistent_capture(False)
                _live_voice_state.update(
                    status="", transcript="", command="", phase="idle"
                )
                event.app.invalidate()

        if _persistent_voice_enabled:
            event.app.create_background_task(stop_persistent())
        elif _live_voice is not None and _live_voice.running:
            asyncio.create_task(_voice_notice("voice: stop Shift-F9 mode first"))
        else:
            event.app.create_background_task(start_persistent())

    @bindings.add(Keys.F21, eager=True, save_before=lambda event: False)
    def _toggle_live_voice_command(event):
        # Shift-F9: experimental live transcript + speculative command preview.
        global _live_voice, _live_voice_ai_task

        async def generate_partial(buffer, transcript, app):
            global _live_voice_ai_task
            try:
                await asyncio.sleep(0.35)
                command = await _ai_autosuggester.command_from_intent(
                    buffer,
                    transcript,
                    service="xonsh_live_voice_command",
                )
            except asyncio.CancelledError:
                return
            except Exception as error:
                _live_voice_state["status"] = f"AI error: {error}"
                _live_voice_state["phase"] = "error"
                app.invalidate()
                return
            if _live_voice_state["transcript"] == transcript:
                _live_voice_state["command"] = command
                _live_voice_state["phase"] = "ready" if command else "transcribing"
                app.invalidate()

        def on_partial(transcript):
            global _live_voice_ai_task
            _live_voice_state["transcript"] = transcript
            _live_voice_state["status"] = "listening live — Shift-F9 to finish"
            _live_voice_state["phase"] = "transcribing"
            if _live_voice_ai_task is not None and not _live_voice_ai_task.done():
                _live_voice_ai_task.cancel()
            _live_voice_ai_task = event.app.create_background_task(
                generate_partial(event.current_buffer, transcript, event.app)
            )
            event.app.invalidate()

        async def start_live():
            global _live_voice
            worker = Path($XONSH_CONFIG_DIR) / "lib/wes_voice_stream_worker.py"
            command = [
                str(${...}["XONSH_LIVE_VOICE_PYTHON"]),
                str(worker),
                "--model",
                str(${...}["XONSH_LIVE_VOICE_MODEL"]),
                "--ffmpeg",
                resolve_executable("ffmpeg"),
                "--audio-device",
                str(${...}["XONSH_VOICE_AUDIO_DEVICE"]),
                "--interval-ms",
                str(${...}["XONSH_LIVE_VOICE_INTERVAL_MS"]),
            ]
            _live_voice = LiveVoice(command, on_partial)
            _live_voice_state.update(
                status="loading Tiny…",
                transcript="",
                command="",
                phase="loading",
            )
            event.app.invalidate()
            try:
                await _live_voice.start()
            except Exception as error:
                _live_voice_state["status"] = f"voice error: {error}"
                _live_voice_state["phase"] = "error"
                event.app.invalidate()
                return
            _live_voice_state["status"] = "listening live — Shift-F9 to finish"
            _live_voice_state["phase"] = "transcribing"
            event.app.invalidate()

        async def stop_live():
            global _live_voice_ai_task
            _live_voice_state["status"] = "finalizing transcript…"
            _live_voice_state["phase"] = "finalizing"
            event.app.invalidate()
            try:
                transcript = await _live_voice.stop()
                if _live_voice_ai_task is not None and not _live_voice_ai_task.done():
                    _live_voice_ai_task.cancel()
                if not transcript:
                    await _voice_notice("live voice: no speech detected")
                    return
                _live_voice_state["status"] = "generating final command…"
                _live_voice_state["phase"] = "finalizing"
                event.app.invalidate()
                buffer = event.app.current_buffer
                command = await _ai_autosuggester.command_from_intent(
                    buffer,
                    transcript,
                    service="xonsh_live_voice_command_final",
                )
                if command:
                    buffer.save_to_undo_stack()
                    buffer.text = command
                    buffer.cursor_position = len(command)
            except Exception as error:
                await _voice_notice(f"live voice: {error}")
            finally:
                _live_voice_state.update(
                    status="", transcript="", command="", phase="idle"
                )
                event.app.invalidate()

        if _live_voice is not None and _live_voice.running:
            event.app.create_background_task(stop_live())
        else:
            event.app.create_background_task(start_live())

    def live_voice_has_command():
        return bool(
            _live_voice is not None
            and _live_voice.running
            and not _persistent_voice_enabled
            and _live_voice_state["command"]
        )

    def persistent_voice_has_command():
        return bool(
            _persistent_voice_enabled
            and _live_voice is not None
            and _live_voice.running
            and _live_voice_state["command"]
        )

    @bindings.add(
        "c-m",
        filter=Condition(persistent_voice_has_command),
        eager=True,
        save_before=lambda event: False,
    )
    @bindings.add(
        "c-j",
        filter=Condition(persistent_voice_has_command),
        eager=True,
        save_before=lambda event: False,
    )
    def _run_persistent_voice_command(event):
        command = _live_voice_state["command"]
        buffer = event.app.current_buffer
        buffer.save_to_undo_stack()
        buffer.text = command
        buffer.cursor_position = len(command)
        _live_voice_state.update(status="executing…", command="", phase="loading")
        event.app.invalidate()
        buffer.validate_and_handle()

    async def stop_after_accept(app):
        global _live_voice_ai_task
        if _live_voice_ai_task is not None and not _live_voice_ai_task.done():
            _live_voice_ai_task.cancel()
        try:
            await _live_voice.stop()
        except Exception as error:
            await _voice_notice(f"live voice cleanup: {error}")
        finally:
            _live_voice_state.update(
                status="", transcript="", command="", phase="idle"
            )
            app.invalidate()

    @bindings.add(
        "c-m",
        filter=Condition(live_voice_has_command),
        eager=True,
        save_before=lambda event: False,
    )
    @bindings.add(
        "c-j",
        filter=Condition(live_voice_has_command),
        eager=True,
        save_before=lambda event: False,
    )
    def _accept_live_voice_command(event):
        # Accept exactly what the user can see. Do this synchronously against
        # the application's current buffer, then stop capture in background.
        command = _live_voice_state["command"]
        buffer = event.app.current_buffer
        buffer.save_to_undo_stack()
        buffer.text = command
        buffer.cursor_position = len(command)
        _live_voice_state["status"] = "accepted"
        _live_voice_state["phase"] = "ready"
        event.app.create_background_task(stop_after_accept(event.app))
        event.app.invalidate()
