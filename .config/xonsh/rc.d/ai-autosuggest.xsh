"""Streaming AI command-line autosuggestions for Xonsh/Prompt Toolkit."""

import asyncio
import json
import os
import platform

from prompt_toolkit.application import get_app
from prompt_toolkit.auto_suggest import AutoSuggest, AutoSuggestFromHistory, Suggestion
from prompt_toolkit.input import ansi_escape_sequences
from prompt_toolkit.input.vt100_parser import _IS_PREFIX_OF_LONGER_MATCH_CACHE


${...}.setdefault("XONSH_AI_AUTOSUGGEST", True)
${...}.setdefault(
    "XONSH_AI_AUTOSUGGEST_URL",
    "http://build21.lan:8013/v1/chat/completions",
)
${...}.setdefault(
    "XONSH_AI_AUTOSUGGEST_MODEL",
    "ggml-org/gpt-oss-120b-GGUF",
)
${...}.setdefault("XONSH_AI_AUTOSUGGEST_DEBUG", False)


_AI_AUTOSUGGEST_SYSTEM_PROMPT = """\
You are an inline command-line autosuggester for an expert shell user.
Infer the intended complete command from the shell context and current buffer.
Output ONLY the exact characters that should be appended after the cursor.
Never repeat the command prefix. Never explain. No quotes, markdown, or newline.
Prefer a short, likely completion over inventing a long command.
If no useful completion is clear, output nothing."""


# Prompt Toolkit 3.0 has no enum value for modified Tab. Give enhanced-keyboard
# terminal encodings a private single-character slot, as Xonsh does for
# Shift-Enter. Modifiers 3 and 7 cover Alt-Tab and Alt-Ctrl-I; Tab is Ctrl-I.
_AI_REGENERATE_KEY = "\x81"
for _ai_regenerate_sequence in (
    "\x1b[27;3;9~",  # xterm modifyOtherKeys: Alt-Tab
    "\x1b[27;7;9~",  # xterm modifyOtherKeys: Alt-Ctrl-I
    "\x1b[9;3u",  # Kitty keyboard protocol: Alt-Tab
    "\x1b[9;7u",  # Kitty keyboard protocol: Alt-Ctrl-I
):
    ansi_escape_sequences.ANSI_SEQUENCES[_ai_regenerate_sequence] = (
        _AI_REGENERATE_KEY
    )
ansi_escape_sequences.REVERSE_ANSI_SEQUENCES[_AI_REGENERATE_KEY] = "\x1b[9;3u"
# Xonsh creates Prompt Toolkit's input parser before rc.d finishes loading.
# It may therefore have cached these prefixes as non-matches already.
_IS_PREFIX_OF_LONGER_MATCH_CACHE.clear()


class _StreamingAIAutoSuggest(AutoSuggest):
    def __init__(self):
        self._active_task = None
        self._bound_buffer = None
        self._history = AutoSuggestFromHistory()

    def get_suggestion(self, buffer, document):
        # Prompt Toolkit calls the async implementation below.
        return None

    def _bind_cancellation(self, buffer):
        if self._bound_buffer is buffer:
            return
        self._bound_buffer = buffer

        def cancel_stale_request(_):
            task = self._active_task
            if task is not None and not task.done():
                task.cancel()

        buffer.on_text_changed += cancel_stale_request

    def _recent_commands(self, buffer, limit=10):
        try:
            entries = list(buffer.history.get_strings())
            return [entry for entry in entries if entry.strip()][-limit:]
        except Exception:
            pass
        return []

    def _request_body(self, buffer, document):
        before = document.text_before_cursor
        after = document.text_after_cursor
        context = (
            f"shell=xonsh\n"
            f"os={platform.system()}\n"
            f"cwd={os.getcwd()}\n"
            "recent_commands_oldest_to_newest="
            f"{json.dumps(self._recent_commands(buffer), ensure_ascii=False)}\n"
            f"command_before_cursor={before}\n"
            f"command_after_cursor={after}"
        )
        return {
            "model": ${...}["XONSH_AI_AUTOSUGGEST_MODEL"],
            "stream": True,
            "temperature": 0,
            "max_tokens": 96,
            "chat_template_kwargs": {"reasoning_effort": "low"},
            "messages": [
                {"role": "system", "content": _AI_AUTOSUGGEST_SYSTEM_PROMPT},
                {"role": "user", "content": context},
            ],
        }

    def _clean_suffix(self, value):
        # Autosuggestions are intentionally single-line. Preserve meaningful
        # leading spaces because they are often the first missing characters.
        value = value.replace("```xonsh", "").replace("```sh", "").replace("```", "")
        return value.splitlines()[0][:240] if value else ""

    async def regenerate(self, buffer):
        """Discard the current answer and request another for the same buffer."""
        active_task = self._active_task
        if active_task is not None and not active_task.done():
            active_task.cancel()
            try:
                await active_task
            except asyncio.CancelledError:
                pass

        document = buffer.document
        buffer.suggestion = None
        buffer.on_suggestion_set.fire()
        get_app().invalidate()

        suggestion = await self.get_suggestion_async(buffer, document)
        if buffer.document == document and suggestion is not None:
            buffer.suggestion = suggestion
            buffer.on_suggestion_set.fire()
            get_app().invalidate()

    async def _stream_request(self, body, on_content):
        process = await asyncio.create_subprocess_exec(
            "curl",
            "--silent",
            "--show-error",
            "--fail-with-body",
            "--no-buffer",
            "--connect-timeout",
            "1",
            "--max-time",
            "8",
            ${...}["XONSH_AI_AUTOSUGGEST_URL"],
            "-H",
            "Content-Type: application/json",
            "--data-binary",
            "@-",
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL,
        )

        try:
            process.stdin.write(json.dumps(body).encode("utf-8"))
            await process.stdin.drain()
            process.stdin.close()

            async for raw_line in process.stdout:
                line = raw_line.decode("utf-8", errors="replace").strip()
                if not line.startswith("data:"):
                    continue
                data = line[5:].strip()
                if data == "[DONE]":
                    break
                try:
                    event = json.loads(data)
                    delta = event["choices"][0].get("delta", {})
                    content = delta.get("content") or ""
                except (KeyError, IndexError, TypeError, json.JSONDecodeError):
                    continue
                if content:
                    on_content(content)

            return await process.wait()
        except asyncio.CancelledError:
            if process.returncode is None:
                process.terminate()
                try:
                    await asyncio.wait_for(process.wait(), timeout=0.2)
                except asyncio.TimeoutError:
                    process.kill()
                    await process.wait()
            raise
        finally:
            if process.returncode is None:
                process.terminate()

    async def get_suggestion_async(self, buffer, document):
        if not ${...}.get("XONSH_AI_AUTOSUGGEST", True):
            return self._history.get_suggestion(buffer, document)

        # Prompt Toolkit's Suggestion UI can append only at the end of the
        # buffer. It cannot represent a replacement in the middle of a line.
        if not document.is_cursor_at_the_end or not document.text.strip():
            return None

        self._bind_cancellation(buffer)
        self._active_task = asyncio.current_task()
        accumulated = ""

        def show_chunk(content):
            nonlocal accumulated
            accumulated += content
            suffix = self._clean_suffix(accumulated)
            if not suffix or buffer.document != document:
                return
            buffer.suggestion = Suggestion(suffix)
            buffer.on_suggestion_set.fire()
            get_app().invalidate()

        try:
            return_code = await self._stream_request(
                self._request_body(buffer, document), show_chunk
            )
        except asyncio.CancelledError:
            return None
        except Exception as error:
            if ${...}.get("XONSH_AI_AUTOSUGGEST_DEBUG"):
                from xonsh.tools import print_above_prompt

                print_above_prompt(f"AI autosuggest: {type(error).__name__}: {error}")
            return self._history.get_suggestion(buffer, document)
        finally:
            if self._active_task is asyncio.current_task():
                self._active_task = None

        suffix = self._clean_suffix(accumulated)
        if return_code == 0 and suffix:
            return Suggestion(suffix)
        return self._history.get_suggestion(buffer, document)


_ai_autosuggester = _StreamingAIAutoSuggest()


@events.on_ptk_create
def _wes_install_ai_autosuggester(bindings, **_):
    # Xonsh 0.23 constructs AutoSuggestFromHistory inside cmdloop after rc.d
    # has loaded. Replacing that factory lets Xonsh pass our implementation to
    # Prompt Toolkit without changing Xonsh or Prompt Toolkit source files.
    import xonsh.shells.ptk_shell as ptk_shell

    ptk_shell.AutoSuggestFromHistory = lambda: _ai_autosuggester

    @bindings.add(_AI_REGENERATE_KEY, eager=True, save_before=lambda event: False)
    @bindings.add("escape", "c-i", eager=True, save_before=lambda event: False)
    def _regenerate_ai_autosuggestion(event):
        # Alt-Tab normally arrives at terminals as Escape followed by Tab
        # (Control-I). Keep the command buffer untouched and replace only the
        # current streamed suggestion.
        event.app.create_background_task(
            _ai_autosuggester.regenerate(event.current_buffer)
        )
