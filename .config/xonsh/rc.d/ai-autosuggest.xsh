"""Streaming AI command-line autosuggestions for Xonsh/Prompt Toolkit."""

import asyncio
import itertools
import json
import os
import platform
import sys
import time
from pathlib import Path

from prompt_toolkit.application import get_app
from prompt_toolkit.auto_suggest import AutoSuggest, AutoSuggestFromHistory, Suggestion
from prompt_toolkit.input import ansi_escape_sequences
from prompt_toolkit.input.vt100_parser import _IS_PREFIX_OF_LONGER_MATCH_CACHE
from prompt_toolkit.keys import Keys


_ai_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_ai_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_ai_xonsh_lib))

from wes_logging import DEFAULT_LOG_PATH, configure_logging, get_logger
from wes_semantic_history import InferenceClient, SemanticHistoryRetriever


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
${...}.setdefault("XONSH_AI_SEMANTIC_HISTORY", True)
${...}.setdefault("XONSH_AI_SEMANTIC_HISTORY_HOST", "build21.lan")
${...}.setdefault("XONSH_AI_SEMANTIC_HISTORY_PORT", 8015)
${...}.setdefault("XONSH_LOG", str(DEFAULT_LOG_PATH))
configure_logging(
    str(${...}["XONSH_LOG"]),
    clear_iterm_scrollback=True,
    rich_output=${...}.get("XONSH_LOG_RICH", True),
)
_ai_log = get_logger("ai_autosuggest")
_ai_request_ids = itertools.count(1)


_AI_AUTOSUGGEST_SYSTEM_PROMPT = """\
You are an inline command-line autosuggester for an expert shell user.
Infer the intended complete command from the shell context and current buffer.
Output ONLY the exact characters that should be appended after the cursor.
Never repeat the command prefix. Never explain. No quotes, markdown, or newline.
Prefer a short, likely completion over inventing a long command.
If no useful completion is clear, output nothing."""


# Prompt Toolkit 3.0 has no enum value for modified Tab. Route enhanced-keyboard
# terminal encodings through an otherwise-unused named key. Modifiers 3 and 7
# cover Alt-Tab and Alt-Ctrl-I; Tab is Ctrl-I.
_AI_REGENERATE_KEY = Keys.F24
for _ai_regenerate_sequence in (
    "\x1b\t",  # iTerm2 Option as Esc+: Alt-Tab
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
        self._active_request_id = None
        self._bound_buffer = None
        self._history = AutoSuggestFromHistory()
        self._choice_buffer_text = None
        self._previous_completions = []
        self._submitting_buffer = None
        semantic_client = InferenceClient(
            str(${...}["XONSH_AI_SEMANTIC_HISTORY_HOST"]),
            int(${...}["XONSH_AI_SEMANTIC_HISTORY_PORT"]),
        )
        self._semantic_history = SemanticHistoryRetriever(
            semantic_client,
            on_timing=lambda stage, count, elapsed_ms: _ai_log.info(
                "semantic_history stage=%s count=%s elapsed_ms=%.1f",
                stage,
                count,
                elapsed_ms,
            ),
        )

    def get_suggestion(self, buffer, document):
        # Prompt Toolkit calls the async implementation below.
        return None

    def _bind_cancellation(self, buffer):
        if self._bound_buffer is buffer:
            return
        self._bound_buffer = buffer

        def cancel_stale_request(_):
            # The next text change after accepting a line is Prompt Toolkit
            # resetting the editor for a fresh prompt.
            if self._submitting_buffer is buffer:
                self._submitting_buffer = None
            self._sync_choice_buffer(buffer.text)
            task = self._active_task
            if task is not None and not task.done():
                _ai_log.info(
                    "request_cancel_for_text_change id=%s", self._active_request_id
                )
                task.cancel()

        buffer.on_text_changed += cancel_stale_request

    def cancel_for_submit(self, buffer):
        """Make command acceptance independent of inference availability."""
        self._submitting_buffer = buffer
        task = self._active_task
        if task is not None and not task.done():
            _ai_log.info(
                "submit_cancel_request id=%s buffer=%r",
                self._active_request_id,
                buffer.text,
            )
            task.cancel()
        buffer.suggestion = None
        buffer.on_suggestion_set.fire()

    def _sync_choice_buffer(self, text):
        if text == self._choice_buffer_text:
            return
        if self._previous_completions:
            _ai_log.info(
                "completion_choices_reset previous_count=%s new_buffer=%r",
                len(self._previous_completions),
                text,
            )
        self._choice_buffer_text = text
        self._previous_completions = []

    def _remember_visible_completion(self, buffer):
        self._sync_choice_buffer(buffer.text)
        suggestion = buffer.suggestion
        suffix = suggestion.text if suggestion is not None else ""
        if suffix:
            self._previous_completions.append(suffix)
            _ai_log.info(
                "completion_choice_rejected choice_count=%s suffix=%r",
                len(self._previous_completions),
                suffix,
            )

    def _recent_commands(self, buffer, limit=10):
        try:
            entries = list(buffer.history.get_strings())
            return [entry for entry in entries if entry.strip()][-limit:]
        except Exception:
            pass
        return []

    def _request_body(self, buffer, document, semantic_commands=()):
        before = document.text_before_cursor
        after = document.text_after_cursor
        context = (
            f"shell=xonsh\n"
            f"os={platform.system()}\n"
            f"cwd={os.getcwd()}\n"
            "recent_commands_oldest_to_newest="
            f"{json.dumps(self._recent_commands(buffer), ensure_ascii=False)}\n"
            "semantic_history_commands_most_relevant_first="
            f"{json.dumps(list(semantic_commands), ensure_ascii=False)}\n"
            f"command_before_cursor={before}\n"
            f"command_after_cursor={after}"
        )
        if self._previous_completions:
            context += (
                "\nuser is requesting another choice, these were requested "
                "previously:\n"
                + json.dumps(self._previous_completions, ensure_ascii=False)
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
        self._remember_visible_completion(buffer)
        _ai_log.info(
            "regenerate_start buffer=%r previous_count=%s",
            buffer.text,
            len(self._previous_completions),
        )
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

    async def _stream_request(self, request_id, body, on_content):
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
        _ai_log.info("curl_started id=%s pid=%s", request_id, process.pid)

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
            _ai_log.info("curl_cancelled id=%s", request_id)
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
        self._sync_choice_buffer(document.text)
        if self._submitting_buffer is buffer:
            _ai_log.info("request_skipped_for_submit buffer=%r", document.text)
            return None
        if not ${...}.get("XONSH_AI_AUTOSUGGEST", True):
            return self._history.get_suggestion(buffer, document)

        # Prompt Toolkit's Suggestion UI can append only at the end of the
        # buffer. It cannot represent a replacement in the middle of a line.
        if not document.is_cursor_at_the_end or not document.text.strip():
            return None

        self._bind_cancellation(buffer)
        self._active_task = asyncio.current_task()
        request_id = next(_ai_request_ids)
        self._active_request_id = request_id
        started_at = time.monotonic()
        accumulated = ""
        recent_count = len(self._recent_commands(buffer))
        semantic_commands = []
        if ${...}.get("XONSH_AI_SEMANTIC_HISTORY", True):
            try:
                history = list(buffer.history.get_strings())
                semantic_commands = await self._semantic_history.retrieve(
                    document.text, history
                )
            except asyncio.CancelledError:
                raise
            except Exception as error:
                _ai_log.info("semantic_history unavailable error=%r", error)
        _ai_log.info(
            "request_start id=%s cwd=%r history_count=%s semantic_count=%s previous_count=%s "
            "before=%r after=%r",
            request_id,
            os.getcwd(),
            recent_count,
            len(semantic_commands),
            len(self._previous_completions),
            document.text_before_cursor,
            document.text_after_cursor,
        )

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
                request_id,
                self._request_body(buffer, document, semantic_commands),
                show_chunk,
            )
        except asyncio.CancelledError:
            _ai_log.info(
                "request_cancelled id=%s elapsed_ms=%d",
                request_id,
                (time.monotonic() - started_at) * 1000,
            )
            return None
        except Exception as error:
            _ai_log.exception(
                "request_error id=%s elapsed_ms=%d error=%r",
                request_id,
                (time.monotonic() - started_at) * 1000,
                error,
            )
            if ${...}.get("XONSH_AI_AUTOSUGGEST_DEBUG"):
                from xonsh.tools import print_above_prompt

                print_above_prompt(f"AI autosuggest: {type(error).__name__}: {error}")
            return self._history.get_suggestion(buffer, document)
        finally:
            if self._active_task is asyncio.current_task():
                self._active_task = None
                self._active_request_id = None

        suffix = self._clean_suffix(accumulated)
        _ai_log.info(
            "request_complete id=%s status=%s elapsed_ms=%d suffix=%r",
            request_id,
            return_code,
            (time.monotonic() - started_at) * 1000,
            suffix,
        )
        if return_code == 0 and suffix:
            return Suggestion(suffix)
        return self._history.get_suggestion(buffer, document)


_ai_autosuggester = _StreamingAIAutoSuggest()


def _cancel_ai_autosuggestion_for_submit(buffer):
    _ai_autosuggester.cancel_for_submit(buffer)


@events.on_ptk_create
def _wes_install_ai_autosuggester(bindings, **_):
    # Xonsh 0.23 constructs AutoSuggestFromHistory inside cmdloop after rc.d
    # has loaded. Replacing that factory lets Xonsh pass our implementation to
    # Prompt Toolkit without changing Xonsh or Prompt Toolkit source files.
    import xonsh.shells.ptk_shell as ptk_shell

    ptk_shell.AutoSuggestFromHistory = lambda: _ai_autosuggester

    @bindings.add(Keys.F24, eager=True, save_before=lambda event: False)
    @bindings.add("escape", "c-i", eager=True, save_before=lambda event: False)
    def _regenerate_ai_autosuggestion(event):
        # Keep the command buffer untouched and replace only the current
        # streamed suggestion.
        _ai_log.info("alt_tab_handler buffer=%r", event.current_buffer.text)
        event.app.create_background_task(
            _ai_autosuggester.regenerate(event.current_buffer)
        )

    @bindings.add(Keys.F18, eager=True, save_before=lambda event: False)
    def _toggle_ai_autosuggestion(event):
        # Prompt Toolkit represents Shift-F6 as F18, matching the standard
        # xterm shifted-function-key sequence CSI 17;2~.
        enabled = not bool(${...}.get("XONSH_AI_AUTOSUGGEST", True))
        ${...}["XONSH_AI_AUTOSUGGEST"] = enabled
        buffer = event.current_buffer

        active_task = _ai_autosuggester._active_task
        if not enabled and active_task is not None and not active_task.done():
            _ai_log.info(
                "toggle_cancel_request id=%s", _ai_autosuggester._active_request_id
            )
            active_task.cancel()

        buffer.suggestion = None
        buffer.on_suggestion_set.fire()
        event.app.invalidate()
        _ai_log.info("autosuggest_toggled enabled=%s buffer=%r", enabled, buffer.text)

        # Toggling on should work immediately without requiring a throwaway
        # edit to trigger Prompt Toolkit's autosuggestion machinery.
        if enabled and buffer.text.strip():
            event.app.create_background_task(_ai_autosuggester.regenerate(buffer))
