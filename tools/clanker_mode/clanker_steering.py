"""Same-terminal steering while an asynchronous model request is in flight."""

from __future__ import annotations

import asyncio
import weakref
from contextlib import suppress

from prompt_toolkit import PromptSession
from prompt_toolkit.formatted_text import ANSI, HTML, to_formatted_text

from clanker_voice import PrivateDictation


class _PromptInterrupt(Exception):
    """Keep Ctrl+C inside the prompt task until both tasks have unwound."""


class TerminalSteering:
    """Collect complete lines until the model reaches its next response boundary."""

    def __init__(self, loop=None, **prompt_io):
        self.voice = PrivateDictation()
        self.session = PromptSession(
            erase_when_done=True,
            key_bindings=self.voice.bindings(),
            bottom_toolbar=self.voice.toolbar,
            interrupt_exception=_PromptInterrupt,
            **prompt_io,
        )
        self.preview = ""
        self.exit_requested = False
        self.unsent_text = ""
        self.owns_loop = loop is None
        self.loop = loop or asyncio.new_event_loop()

    @classmethod
    def for_session(cls, session, **prompt_io):
        loop = getattr(session, "_clanker_steering_loop", None)
        if loop is None or loop.is_closed():
            loop = asyncio.new_event_loop()
            session._clanker_steering_loop = loop
            weakref.finalize(session, loop.close)
        return cls(loop=loop, **prompt_io)

    def invoke(self, model, messages):
        task = self.loop.create_task(self._invoke(model, messages))
        try:
            return self.loop.run_until_complete(task)
        except _PromptInterrupt:
            raise KeyboardInterrupt from None
        except KeyboardInterrupt:
            task.cancel()
            with suppress(asyncio.CancelledError):
                self.loop.run_until_complete(task)
            raise

    def update_preview(self, rendered):
        self.preview = rendered
        self.session.app.invalidate()

    def prompt_message(self):
        return [
            *to_formatted_text(ANSI(self.preview)),
            *to_formatted_text(HTML("<ansicyan>steer › </ansicyan>")),
        ]

    def close(self):
        if not self.loop.is_closed():
            self.loop.run_until_complete(self.voice.close())
            if self.owns_loop:
                self.loop.close()

    async def _invoke(self, model, messages):
        if self.exit_requested:
            return await model.ainvoke(messages), []
        model_task = asyncio.create_task(model.ainvoke(messages))
        queued = []
        prompt_task = None
        try:
            while not model_task.done():
                prompt_task = asyncio.create_task(
                    self.session.prompt_async(
                        self.prompt_message,
                        multiline=False,
                        default=self.unsent_text,
                    )
                )
                self.unsent_text = ""
                done, _ = await asyncio.wait(
                    {model_task, prompt_task}, return_when=asyncio.FIRST_COMPLETED
                )
                if model_task in done and prompt_task not in done:
                    # The current buffer owns private dictation. Give its final
                    # transcript time to arrive before copying the draft.
                    finished = self.voice.finished
                    if (
                        finished is not None
                        and not finished.done()
                        and model_task.exception() is None
                    ):
                        await asyncio.wait(
                            {prompt_task, finished}, return_when=asyncio.FIRST_COMPLETED
                        )
                if prompt_task.done():
                    try:
                        text = prompt_task.result().strip()
                    except EOFError:
                        self.exit_requested = True
                        return await model_task, queued
                    if text:
                        queued.append(text)
                else:
                    self.unsent_text = self._current_buffer_text()
                    prompt_task.cancel()
                    with suppress(asyncio.CancelledError):
                        await prompt_task
                if model_task in done:
                    break
            return await model_task, queued
        except BaseException:
            if prompt_task is not None and not prompt_task.done():
                self.unsent_text = self._current_buffer_text()
                prompt_task.cancel()
            self.unsent_text = "\n".join(filter(None, [*queued, self.unsent_text]))
            model_task.cancel()
            tasks = [model_task] if prompt_task is None else [model_task, prompt_task]
            await asyncio.gather(*tasks, return_exceptions=True)
            raise

    def _current_buffer_text(self):
        """Read unfinished input before cancelling prompt_toolkit's prompt."""
        try:
            return self.session.app.current_buffer.text
        except (AttributeError, RuntimeError):
            return ""


def steering_message(messages):
    """Combine ordered submissions into one unambiguous user update."""
    if len(messages) == 1:
        return f"Steering received while you were working:\n\n{messages[0]}"
    items = "\n".join(
        f"{index}. {message}" for index, message in enumerate(messages, 1)
    )
    return f"Steering received while you were working, in order:\n\n{items}"
