"""Explicit frame attachments and traced multi-turn LangChain chat."""

import asyncio
import base64
import os
from io import BytesIO
from pathlib import Path
from threading import Event

from ai_shared.models import connect
from ai_shared.session import Session
from langchain_core.messages import HumanMessage, SystemMessage
from PIL import Image

SYSTEM = """You are Slop Reel, a collaborative video inspection assistant.
Only attached images are visible to you; you cannot hear the source audio.
Frames are individually labeled with source presentation timestamps and zero-based
frame indices. Describe observations and uncertainty honestly. Nearby frames are
consecutive decoded frames, not a uniformly sampled video clip. Do not claim to
have inspected frames or audio that were not supplied. You cannot control playback
or execute code. Discuss anomalies and their labeled positions when asked.
"""


def request_content(text, frames=(), center=None):
    command, _, question = text.partition(" ")
    if command not in ("/frame", "/frames"):
        if text.startswith("/"):
            raise ValueError(
                "Unknown command. Use /frame [question] or /frames [question]."
            )
        return text
    if not frames:
        raise ValueError("No frames are available yet")
    content = []
    for frame in frames:
        image = Image.open(BytesIO(frame.jpeg))
        image.thumbnail((640, 640))
        output = BytesIO()
        image.save(output, "JPEG", quality=85)
        content.extend(
            [
                {
                    "type": "text",
                    "text": f"Source frame {frame.index}, timestamp {frame.seconds:.6f}s, offset {frame.index - center:+d} frames",
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "data:image/jpeg;base64,"
                        + base64.b64encode(output.getvalue()).decode()
                    },
                },
            ]
        )
    content.append(
        {
            "type": "text",
            "text": question.strip()
            or (
                "Describe this frame."
                if command == "/frame"
                else "Describe the sequence and any visible discontinuities, citing frame labels."
            ),
        }
    )
    return content


class Chat:
    def __init__(self, directory=None, model=None):
        self.session = Session(
            directory or Path.home() / ".local/state/nvim/ask-openai/slop_reel",
            trace_type="slop_reel",
        )
        self.model = model
        self.runner = None
        self.cancelled = Event()

    def ask(self, content, media_metadata=None):
        session = self.session
        session.turn += 1
        session.active = True
        status = "error"
        session.append("turn_start", turn_id=session.turn)
        try:
            if not session.messages:
                session.add_message(SystemMessage(SYSTEM))
            session.add_message(HumanMessage(content), media=media_metadata or {})
            if self.model is None:
                self.model = connect(
                    os.getenv("SLOP_REEL_BASE_URL", "http://build21.lan:8011/v1"),
                    os.getenv("SLOP_REEL_MODEL"),
                    os.getenv("SLOP_REEL_API_KEY", "none"),
                    "$SLOP_REEL_MODEL",
                )

            async def invoke():
                task = asyncio.create_task(self.model.ainvoke(session.outbound()))
                try:
                    while not task.done():
                        if self.cancelled.is_set():
                            task.cancel()
                            try:
                                await task
                            except asyncio.CancelledError:
                                pass
                            return None
                        await asyncio.sleep(0.025)
                    return await task
                finally:
                    if not task.done():
                        task.cancel()

            if self.runner is None:
                self.runner = asyncio.Runner()
            response = self.runner.run(invoke())
            if response is None:
                status = "interrupted"
                session.append(
                    "error",
                    turn_id=session.turn,
                    error={
                        "class": "CancelledError",
                        "message": "User cancelled inference",
                    },
                )
                return None
            session.add_message(response)
            if self.cancelled.is_set():
                status = "interrupted"
                session.append(
                    "error",
                    turn_id=session.turn,
                    error={
                        "class": "CancelledError",
                        "message": "User cancelled inference",
                    },
                )
                return None
            status = "success"
            return response.text
        except Exception as exc:
            session.append(
                "error",
                turn_id=session.turn,
                error={"class": type(exc).__name__, "message": str(exc)},
            )
            raise
        finally:
            session.active = False
            session.append("turn_end", turn_id=session.turn, status=status)

    def close(self):
        """Run on the same chat worker after its final request finishes."""
        if self.runner is not None:
            if self.model is not None and getattr(
                self.model, "root_async_client", None
            ):
                self.runner.run(self.model.root_async_client.close())
            self.runner.close()
            self.runner = None
