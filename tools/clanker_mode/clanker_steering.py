"""Same-terminal steering while an asynchronous model request is in flight."""

from __future__ import annotations

import asyncio
from contextlib import suppress

from prompt_toolkit import PromptSession
from prompt_toolkit.formatted_text import HTML


class TerminalSteering:
    """Collect complete lines until the model reaches its next response boundary."""

    def __init__(self):
        self.session = PromptSession()
        self.exit_requested = False
        self.unsent_text = ""
        self.loop = asyncio.new_event_loop()

    def invoke(self, model, messages):
        return self.loop.run_until_complete(self._invoke(model, messages))

    def close(self):
        if not self.loop.is_closed():
            self.loop.close()

    async def _invoke(self, model, messages):
        model_task = asyncio.create_task(model.ainvoke(messages))
        queued = []
        try:
            while not model_task.done():
                prompt_task = asyncio.create_task(
                    self.session.prompt_async(
                        HTML("<ansicyan>steer › </ansicyan>"),
                        multiline=False,
                        default=self.unsent_text,
                    )
                )
                self.unsent_text = ""
                done, _ = await asyncio.wait(
                    {model_task, prompt_task}, return_when=asyncio.FIRST_COMPLETED
                )
                if prompt_task in done:
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
            model_task.cancel()
            with suppress(asyncio.CancelledError):
                await model_task
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
    items = "\n".join(f"{index}. {message}" for index, message in enumerate(messages, 1))
    return f"Steering received while you were working, in order:\n\n{items}"
