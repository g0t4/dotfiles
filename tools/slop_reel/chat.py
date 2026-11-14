"""Explicit frame attachments and traced multi-turn LangChain chat."""

import asyncio
import base64
import os
from io import BytesIO
from pathlib import Path
from threading import Event

from ai_shared.models import connect
from ai_shared.session import Session
from langchain_core.messages import HumanMessage, SystemMessage, ToolMessage
from PIL import Image

SYSTEM = """You are Sloppy, the collaborative video inspection agent in Slop Reel.
Your name is an affectionate jab at anti-AI "slop" rhetoric, not a criticism of
you or your work. Wear it with pride; bring care and good judgment to the review.
You have read-only access to the open video through inspect_video. Use it proactively
when asked about the video; the user need not attach frames. Start with info for
bounds/playhead. Inspect current, inclusive frame ranges, time ranges, or material
changes. For whole-video anomaly checks, paginate changes across the entire video
(including frame zero), then inspect neighboring exact frames to confirm anomalies.
Continue with next_offset using the same selection bounds; never equate one page
with the entire video. Complete the requested inspection autonomously: do not ask
permission to fetch remaining pages or confirm neighboring frames. For whole-video
questions, finish all candidate pages before your final answer (within the budget). Tool-selected images arrive automatically in a following
user-role message; these are tool observations, not a new user request.
Frames carry source timestamps and zero-based indices. Cite these in findings.
Each tool result includes measured mean luma (0..255) and near-black pixel fraction
(luma below 12). For black-frame questions, consult these measurements as well as
images; a fraction near 1 is strong evidence of a black or nearly black frame.
Verify such candidates with their immediately preceding/following source frames.
Dark content can be intentional; distinguish observations from editing judgments.
Change detection is a heuristic: candidates can miss subtle differences. Distinguish
candidate coverage from exhaustive frame inspection; do not promise no black frames
or other defects based on incomplete coverage. Only supplied images are visible;
you cannot hear source audio, control playback, or execute code. Be candid about
uncertainty and report any uninspected remainder if you reach the tool-call budget.
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
    def __init__(
        self, directory=None, model=None, video=None, notify=lambda text: None
    ):
        self.session = Session(
            directory or Path.home() / ".local/state/nvim/ask-openai/slop_reel",
            trace_type="slop_reel",
        )
        self.model = model
        self.video = video
        self.notify = notify
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

            bound = (
                self.model.bind_tools(self.video.tools()) if self.video else self.model
            )
            if self.video and not self.cancelled.is_set():
                self.video.prepare()
                self.video.position = (media_metadata or {}).get("playhead_seconds", 0)

            async def invoke():
                task = asyncio.create_task(bound.ainvoke(session.outbound()))
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
            observations = []
            for step in range(25):
                response = self.runner.run(invoke())
                if response is None:
                    break
                session.add_message(response)
                if response.invalid_tool_calls:
                    raise ValueError(
                        f"Malformed tool calls: {response.invalid_tool_calls}"
                    )
                if not response.tool_calls:
                    break
                for call in response.tool_calls:
                    images = []
                    try:
                        if self.cancelled.is_set():
                            raise RuntimeError("Inspection cancelled")
                        if step == 24:
                            raise RuntimeError(
                                "Tool-call budget reached. Report inspected coverage and remaining work."
                            )
                        if not self.video or call["name"] != "inspect_video":
                            raise ValueError("Unknown tool")
                        self.notify(f"Tool: {call['name']} {call['args']}")
                        result, images = self.video.execute(call["args"])
                    except Exception as exc:
                        result = f"Inspection error: {type(exc).__name__}: {exc}"
                    session.add_message(
                        ToolMessage(result, tool_call_id=call["id"], name=call["name"])
                    )
                    # Gemma templates accept images in user messages, not tool text.
                    # Close every call first, then append the associated observations.
                    if images:
                        observations.append((call["id"], images))
                for call_id, images in observations:
                    session.add_message(HumanMessage(images), tool_observation=call_id)
                observations.clear()
                if self.cancelled.is_set():
                    response = None
                    break
            else:
                raise RuntimeError(
                    "Agent exceeded 25 inference steps; inspected frames remain in the trace"
                )
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
