"""Persist Xonsh AI requests in the existing ask-openai trace schema."""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any


DEFAULT_XONSH_TRACE_DIR = Path.home() / ".local/state/nvim/ask-openai/xonsh"


def build_chat_trace(
    *,
    messages: list[dict[str, Any]],
    full_content: str,
    model: str,
    service: str,
    last_sse: dict[str, Any] | None,
    reasoning_content: str = "",
    session_id: int | None = None,
) -> dict[str, Any]:
    """Build the same top-level shape used by the existing shell traces."""
    if session_id is None:
        session_id = int(time.time())

    finish_reason = None
    if last_sse:
        choices = last_sse.get("choices") or []
        if choices:
            finish_reason = choices[-1].get("finish_reason")
        finish_reason = last_sse.get("finish_reason", finish_reason)

    assistant: dict[str, Any] = {"role": "assistant", "content": full_content}
    if finish_reason is not None:
        assistant["finish_reason"] = finish_reason
    if reasoning_content:
        assistant["reasoning_content"] = reasoning_content

    response: dict[str, Any] = {
        "model": model,
        "service": service,
    }
    if last_sse:
        for key in (
            "finish_reason",
            "model_name",
            "model_provider",
            "system_fingerprint",
            "usage",
            "timings",
        ):
            if key in last_sse:
                response[key] = last_sse[key]
    if finish_reason is not None:
        response["finish_reason"] = finish_reason

    trace: dict[str, Any] = {
        "session_id": session_id,
        "messages": [*messages, assistant],
        "response": response,
    }
    if last_sse is not None:
        trace["last_sse"] = last_sse
    return trace


def save_chat_trace(
    trace: dict[str, Any],
    trace_dir: str | Path = DEFAULT_XONSH_TRACE_DIR,
) -> Path:
    """Write a collision-safe ``*-trace.json`` file and return its path."""
    directory = Path(trace_dir).expanduser()
    directory.mkdir(parents=True, exist_ok=True)
    session_id = trace["session_id"]
    path = directory / f"{session_id}-trace.json"
    collision = 2
    while path.exists():
        path = directory / f"{session_id}-{collision}-trace.json"
        collision += 1
    path.write_text(
        json.dumps(trace, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return path
