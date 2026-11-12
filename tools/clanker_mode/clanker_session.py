"""Append-only session records and a separate, disposable model-input view."""

from __future__ import annotations

import json
import os
from copy import deepcopy
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4

from langchain_core.messages import convert_to_messages


def timestamp():
    return datetime.now(UTC).isoformat()


def serialize_message(message):
    """Separate conversation content from local inference diagnostics."""
    roles = {"human": "user", "ai": "assistant", "system": "system", "tool": "tool"}
    body = {"role": roles[message.type], "content": deepcopy(message.content)}
    metadata = {"finished_at": timestamp()}
    if message.type == "ai":
        body.update(deepcopy(message.additional_kwargs))
        # Preserve raw argument strings when available, rather than repeatedly
        # parsing/reformatting them. Malformed calls remain diagnostic metadata.
        raw_calls = body.pop("tool_calls", None)
        if message.tool_calls:
            valid_ids = {call["id"] for call in message.tool_calls}
            body["tool_calls"] = (
                [call for call in raw_calls if call.get("id") in valid_ids]
                if raw_calls
                else [
                    {
                        "id": call["id"],
                        "type": "function",
                        "function": {
                            "name": call["name"],
                            "arguments": json.dumps(call["args"]),
                        },
                    }
                    for call in message.tool_calls
                ]
            )
        metadata.update(
            response=deepcopy(message.response_metadata),
            usage=deepcopy(message.usage_metadata),
        )
        if message.invalid_tool_calls:
            metadata["invalid_tool_calls"] = deepcopy(message.invalid_tool_calls)
        if raw_calls and message.invalid_tool_calls:
            metadata["raw_tool_calls"] = raw_calls
    if message.type == "tool":
        body["tool_call_id"] = message.tool_call_id
        if message.name:
            body["name"] = message.name
    if message.id:
        metadata["provider_message_id"] = message.id
    return body, metadata


def _create_trace_file(directory, local_start):
    """Readable local minute plus a sortable microsecond offset, not a hash."""
    prefix = local_start.strftime("%Y-%m-%d_%H%M")
    offset = local_start.second * 1_000_000 + local_start.microsecond
    while True:
        path = directory / f"{prefix}-{offset:07x}.jsonl"
        try:
            descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        except FileExistsError:
            # Same clock tick (or repeated local time): never replace a trace.
            offset += 1
            continue
        os.close(descriptor)
        return path


class Session:
    """One writer and one JSONL file for this Xonsh process's lifetime."""

    def __init__(self, directory, owner_ctx):
        self.owner_ctx = owner_ctx
        self.pid = os.getpid()
        self.id = uuid4().hex
        self.sequence = 0
        self.turn = 0
        self.messages = []
        self.active = False
        directory = Path(directory).expanduser()
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.path = _create_trace_file(directory, datetime.now().astimezone())
        self.append(
            "session",
            schema_version=1,
            session_id=self.id,
            trace_type="clanker_mode",
            pid=self.pid,
        )

    def append(self, kind, **fields):
        record = {
            "type": kind,
            "sequence": self.sequence,
            "timestamp": timestamp(),
            **fields,
        }
        # One flushed, newline-terminated record per append: tail -f consumers
        # can render it immediately. No previous bytes are read or rewritten.
        line = (
            json.dumps(record, ensure_ascii=False, default=str, separators=(",", ":"))
            + "\n"
        )
        with os.fdopen(os.open(self.path, os.O_WRONLY | os.O_APPEND), "w") as stream:
            stream.write(line)
        self.sequence += 1
        return record

    def add_message(self, message, **local_metadata):
        body, metadata = serialize_message(message)
        metadata.update(local_metadata)
        record = self.append(
            "message", turn_id=self.turn, message=body, metadata=metadata
        )
        self.messages.append(record)

    def outbound(self):
        messages = []
        for record in self.messages:
            body = deepcopy(record["message"])
            if record["turn_id"] < self.turn:
                body.pop("reasoning_content", None)
            messages.append(body)
        # Our event envelope and metadata never enter the inference request.
        return convert_to_messages(messages)

    def clear(self):
        if self.active:
            raise RuntimeError("Cannot clear a conversation during an active turn")
        self.append("context_reset", after_turn_id=self.turn)
        self.messages.clear()


def get_session(xsh, directory):
    session = getattr(xsh, "_clanker_mode_session", None)
    if (
        session is None
        or session.owner_ctx is not xsh.ctx
        or session.pid != os.getpid()
    ):
        session = Session(directory, xsh.ctx)
        xsh._clanker_mode_session = session
    return session
