"""Assemble a streamed model round before handing any calls to the shell."""

import json
from time import monotonic

from langchain_openai_compatible import acapture_completion, capture_completion


class _Preview:
    def __init__(self, on_partial):
        self.on_partial = on_partial
        self.pending = []
        self.message = None
        self.next_preview = 0
        self.phase = None

    def add(self, chunk):
        if not self.on_partial:
            return
        self.pending.append(chunk.model_copy(update={"response_metadata": {}}))
        if getattr(chunk, "tool_call_chunks", None):
            phase = ("tool", chunk.tool_call_chunks[-1]["index"])
        elif chunk.text:
            phase = "answer"
        elif chunk.additional_kwargs.get("reasoning_content"):
            phase = "reasoning"
        else:
            return
        if phase != self.phase or monotonic() >= self.next_preview:
            self.merge()
            self.on_partial(self.message)
            self.phase = phase
            self.next_preview = monotonic() + 0.09

    def merge(self):
        if self.message is None:
            self.message = self.pending.pop(0)
        if self.pending:
            self.message = self.message + self.pending
            self.pending.clear()


def _validated_answer(completion):
    message = completion.message
    if not message.response_metadata.get("finish_reason"):
        raise RuntimeError("Model stream ended before a finish reason")
    valid, invalid = [], []
    for call in message.additional_kwargs.get("tool_calls", []):
        function = call["function"]
        name, args, identifier = function["name"], function["arguments"], call["id"]
        try:
            parsed = json.loads(args or "")
            if not name or not isinstance(parsed, dict):
                raise ValueError("Expected a named function with an argument object")
            valid.append({"type": "tool_call", "name": name, "args": parsed, "id": identifier})
        except (ValueError, TypeError) as error:
            invalid.append({"type": "invalid_tool_call", "name": name, "args": args, "id": identifier, "error": str(error)})
    # Existing JSONL readers use these fields on the assistant message.
    metadata = dict(message.response_metadata)
    for event in completion.raw_chunks:
        for key in ("timings", "metrics", "sglext"):
            if event.get(key) is not None:
                metadata[key] = event[key]
    updates = {"response_metadata": metadata}
    if message.additional_kwargs.get("tool_calls"):
        updates.update(tool_calls=valid, invalid_tool_calls=invalid)
    return message.model_copy(update=updates)


class StreamingRound:
    def __init__(self, model, on_partial, on_trace=None):
        self.model = model
        self.on_partial = on_partial
        self.on_trace = on_trace

    def invoke(self, messages):
        if not hasattr(self.model, "stream"):
            return self.model.invoke(messages)
        preview = _Preview(self.on_partial)
        stream = None
        try:
            with capture_completion(self.model.stream(messages)) as stream:
                for chunk in stream:
                    preview.add(chunk)
        finally:
            if self.on_trace and stream is not None:
                self.on_trace(stream.get_trace())
        return _validated_answer(stream.get_final_completion())

    async def ainvoke(self, messages):
        if not hasattr(self.model, "astream"):
            return await self.model.ainvoke(messages)
        preview = _Preview(self.on_partial)
        stream = None
        try:
            async with acapture_completion(self.model.astream(messages)) as stream:
                async for chunk in stream:
                    preview.add(chunk)
        finally:
            if self.on_trace and stream is not None:
                self.on_trace(stream.get_trace())
        return _validated_answer(stream.get_final_completion())
