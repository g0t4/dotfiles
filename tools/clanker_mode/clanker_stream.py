"""Assemble a streamed model round before handing any calls to the shell."""

import json
from contextlib import aclosing, closing
from time import monotonic

from langchain_core.messages import AIMessage


class CompletionStream:
    def __init__(self, on_partial):
        self.on_partial = on_partial
        self.pending = []
        self.message = None
        self.next_preview = 0
        self.phase = None
        self.diagnostics = {}

    def add(self, chunk):
        self.pending.append(chunk)
        for key in ("timings", "metrics", "sglext"):
            if key in chunk.response_metadata:
                self.diagnostics[key] = chunk.response_metadata[key]
        if not self.on_partial:
            return
        if chunk.tool_call_chunks:
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
            if not self.pending:
                raise RuntimeError("Model returned an empty stream")
            self.message = self.pending.pop(0)
        if self.pending:
            self.message = self.message + self.pending
            self.pending.clear()

    def finish(self):
        self.merge()
        message = self.message
        if not message.response_metadata.get("finish_reason"):
            raise RuntimeError("Model stream ended before a finish reason")
        extensions = dict(message.additional_kwargs)
        raw_calls, valid, invalid = [], [], []
        for call in sorted(message.tool_call_chunks, key=lambda c: c["index"] or 0):
            name, args, identifier = call["name"], call["args"], call["id"]
            raw_calls.append(
                {
                    "id": identifier,
                    "type": "function",
                    "function": {"name": name, "arguments": args},
                }
            )
            try:
                parsed = json.loads(args or "")
                if not name or not isinstance(parsed, dict):
                    raise ValueError(
                        "Expected a named function with an argument object"
                    )
                valid.append({"name": name, "args": parsed, "id": identifier})
            except ValueError as error:
                invalid.append(
                    {"name": name, "args": args, "id": identifier, "error": str(error)}
                )
        if raw_calls:
            extensions["tool_calls"] = raw_calls
        return AIMessage(
            content=message.content,
            id=message.id,
            additional_kwargs=extensions,
            tool_calls=valid,
            invalid_tool_calls=invalid,
            response_metadata={**message.response_metadata, **self.diagnostics},
            usage_metadata=message.usage_metadata,
        )


class StreamingRound:
    def __init__(self, model, on_partial):
        self.model = model
        self.on_partial = on_partial

    def invoke(self, messages):
        if not hasattr(self.model, "stream"):
            return self.model.invoke(messages)
        completion = CompletionStream(self.on_partial)
        with closing(self.model.stream(messages)) as chunks:
            for chunk in chunks:
                completion.add(chunk)
        return completion.finish()

    async def ainvoke(self, messages):
        if not hasattr(self.model, "astream"):
            return await self.model.ainvoke(messages)
        completion = CompletionStream(self.on_partial)
        async with aclosing(self.model.astream(messages)) as chunks:
            async for chunk in chunks:
                completion.add(chunk)
        return completion.finish()
