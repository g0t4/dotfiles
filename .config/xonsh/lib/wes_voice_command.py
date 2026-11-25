"""Model-backed conversion for explicit voice-command requests."""

import asyncio
import itertools
import json
import os
import platform
import time

from prompt_toolkit.application import get_app
from prompt_toolkit.filters import Condition
from prompt_toolkit.layout.containers import (
    ConditionalContainer,
    FloatContainer,
    HSplit,
    Window,
)
from prompt_toolkit.layout.controls import FormattedTextControl
from wes_ai_traces import build_chat_trace, save_chat_trace
from wes_logging import get_wes_logger
from xonsh.built_ins import XSH

log = get_wes_logger("voice_command")
_request_ids = itertools.count(1)

_AI_VOICE_COMMAND_SYSTEM_PROMPT = """\
You produce commands specifically for Xonsh, a Python-powered shell, for an expert user.
Every answer must be valid Xonsh syntax or an external command that Xonsh can run.
The complete command may span multiple lines.
Do not substitute Bash, Zsh, Fish, or Readline built-ins such as `bind` for Xonsh features.
For shell-internal behavior, use Xonsh syntax or its Python APIs.
Output ONLY the command to place in the shell buffer.
Never explain, use markdown, or add surrounding quotes.
Use an existing command prefix when it contains exact filenames or arguments."""


class VoiceCommand:
    def __init__(self):
        self._reasoning_request_id = None
        self._reasoning_content = ""

    def _reasoning_display(self):
        if self._reasoning_request_id is None:
            return []
        text = (
            f"thinking › {self._reasoning_content}"
            if self._reasoning_content
            else "prefill…"
        )
        return [("fg:#888888 italic", text)]

    def _start_reasoning(self, request_id):
        self._reasoning_request_id = request_id
        self._reasoning_content = ""
        get_app().invalidate()

    def _append_reasoning(self, request_id, content):
        if self._reasoning_request_id != request_id:
            return
        self._reasoning_content += content
        get_app().invalidate()

    def _finish_reasoning(self, request_id):
        if self._reasoning_request_id != request_id:
            return
        self._reasoning_request_id = None
        self._reasoning_content = ""
        get_app().invalidate()

    def _recent_commands(self, buffer, limit=10):
        try:
            entries = list(buffer.history.get_strings())
            return [entry for entry in entries if entry.strip()][-limit:]
        except (AttributeError, OSError):
            return []

    def _clean_command(self, value):
        value = value.replace("```xonsh", "").replace("```sh", "").replace("```", "")
        return value.strip()[:4000] if value.strip() else ""

    def _voice_command_context(self, buffer, transcript, execution_context=None):
        context = "\n".join(
            [
                f"I am working in Xonsh on {platform.system()}.",
                f"My current working directory is {json.dumps(os.getcwd())}.",
                f"Here is the command I am working on: {json.dumps(buffer.text, ensure_ascii=False)}",
                "",
                "Here's my recent command history from oldest to newest (serialized with json to clearly identify each command):",
                f"{json.dumps(self._recent_commands(buffer), ensure_ascii=False, indent=2)}.",
                "",
                f"Here's what I need help with:\n>{json.dumps(transcript, ensure_ascii=False)}.",
            ]
        )
        if execution_context is not None:
            context += (
                "\nThe previous command and its bounded result were "
                + json.dumps(execution_context, ensure_ascii=False)
                + "."
            )
        return context

    async def command_from_intent(
        self,
        buffer,
        transcript,
        service="xonsh_voice_command",
        execution_context=None,
    ):
        """Turn spoken intent into a complete, inspectable command."""
        request_id = next(_request_ids)
        started_at = time.monotonic()
        accumulated = ""
        context = self._voice_command_context(buffer, transcript, execution_context)
        body = {
            "model": XSH.env.get(
                "XONSH_VOICE_COMMAND_MODEL",
                "ggml-org/DeepSeek-V4-Flash-Vision-Exp-GGUF",
            ),
            "stream": True,
            "temperature": 0,
            "max_tokens": 256,
            "chat_template_kwargs": {"reasoning_effort": "low"},
            "messages": [
                {"role": "system", "content": _AI_VOICE_COMMAND_SYSTEM_PROMPT},
                {"role": "user", "content": context},
            ],
        }

        def collect(content):
            nonlocal accumulated
            accumulated += content

        log.info(
            "voice_command_start id=%s existing=%r transcript=%r",
            request_id,
            buffer.text,
            transcript,
        )
        self._start_reasoning(request_id)
        try:
            return_code, last_sse, reasoning_content = await self._stream_request(
                request_id,
                body,
                collect,
                lambda content: self._append_reasoning(request_id, content),
            )
        finally:
            self._finish_reasoning(request_id)
        command = self._clean_command(accumulated)
        if return_code == 0:
            try:
                trace = build_chat_trace(
                    messages=body["messages"],
                    full_content=accumulated,
                    reasoning_content=reasoning_content,
                    model=body["model"],
                    service=service,
                    last_sse=last_sse,
                )
                trace_path = save_chat_trace(trace)
                log.info(
                    "voice_command_trace_saved id=%s path=%r",
                    request_id,
                    str(trace_path),
                )
            except OSError as error:
                log.warning(
                    "voice_command_trace_save_failed id=%s error=%r",
                    request_id,
                    error,
                )
        log.info(
            "voice_command_complete id=%s status=%s elapsed_ms=%d command=%r",
            request_id,
            return_code,
            (time.monotonic() - started_at) * 1000,
            command,
        )
        return command if return_code == 0 else ""

    async def _stream_request(self, request_id, body, on_content, on_reasoning=None):
        last_sse = None
        reasoning_content = ""
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
            XSH.env.get(
                "XONSH_VOICE_COMMAND_URL", "http://paxy:8014/v1/chat/completions"
            ),
            "-H",
            "Content-Type: application/json",
            "--data-binary",
            "@-",
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL,
        )
        log.info("curl_started id=%s pid=%s", request_id, process.pid)

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
                    last_sse = event
                    delta = event["choices"][0].get("delta", {})
                    content = delta.get("content") or ""
                    reasoning = (
                        delta.get("reasoning_content") or delta.get("reasoning") or ""
                    )
                    reasoning_content += reasoning
                except (KeyError, IndexError, TypeError, json.JSONDecodeError):
                    continue
                if content:
                    on_content(content)
                if reasoning and on_reasoning is not None:
                    on_reasoning(reasoning)

            return await process.wait(), last_sse, reasoning_content
        except asyncio.CancelledError:
            log.info("curl_cancelled id=%s", request_id)
            if process.returncode is None:
                process.terminate()
                try:
                    await asyncio.wait_for(process.wait(), timeout=0.2)
                except TimeoutError:
                    process.kill()
                    await process.wait()
            raise
        finally:
            if process.returncode is None:
                process.terminate()


def _find_prompt_float(container):
    if isinstance(container, FloatContainer) and isinstance(container.content, HSplit):
        return container
    for child in getattr(container, "children", ()):
        found = _find_prompt_float(child)
        if found is not None:
            return found
    return None


def install_reasoning_window(prompter, voice):
    if prompter is None:
        return False
    app = getattr(prompter, "app", None)
    if app is None:
        return False
    if getattr(prompter, "_voice_reasoning_installed", False):
        return False
    root = app.layout.container
    prompt_container = _find_prompt_float(root)
    if prompt_container is None:
        return False
    reasoning_window = ConditionalContainer(
        Window(
            FormattedTextControl(voice._reasoning_display),
            wrap_lines=True,
            dont_extend_height=True,
            always_hide_cursor=True,
        ),
        Condition(lambda: voice._reasoning_request_id is not None),
    )
    prompt_container.content.children.append(reasoning_window)
    prompter._voice_reasoning_installed = True
    return True
