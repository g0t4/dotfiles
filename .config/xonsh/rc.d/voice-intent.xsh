"""Native push-to-talk voice input for the Xonsh command buffer."""

import asyncio
import sys
from pathlib import Path

from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.keys import Keys


_voice_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_voice_lib) not in sys.path:
    sys.path.insert(0, str(_voice_lib))

from wes_voice_intent import DEFAULT_MODEL, VoiceIntent, insert_transcript


${...}.setdefault("XONSH_VOICE_AUDIO_DEVICE", "0")
${...}.setdefault("XONSH_VOICE_MODEL", str(DEFAULT_MODEL))
_voice_intent = VoiceIntent(
    audio_device=str(${...}["XONSH_VOICE_AUDIO_DEVICE"]),
    model=Path(${...}["XONSH_VOICE_MODEL"]),
)


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
def _wes_voice_keybinding(bindings, **_):
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
        # Shift-F8: speech is intent, and the AI result replaces the buffer.
        toggle(event, "command")
