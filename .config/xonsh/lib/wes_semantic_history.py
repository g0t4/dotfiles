"""Small dependency-free client and vector search for semantic shell history."""

from __future__ import annotations

import asyncio
import math
import struct
import time
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from typing import Any


def pack_message(value: Any) -> bytes:
    """Encode the MessagePack subset used by the inference server."""
    if value is None:
        return b"\xc0"
    if value is False:
        return b"\xc2"
    if value is True:
        return b"\xc3"
    if isinstance(value, int):
        if 0 <= value <= 0x7F:
            return bytes((value,))
        if -32 <= value < 0:
            return bytes((value & 0xFF,))
        if 0 <= value <= 0xFF:
            return b"\xcc" + struct.pack("!B", value)
        if 0 <= value <= 0xFFFF:
            return b"\xcd" + struct.pack("!H", value)
        if 0 <= value <= 0xFFFFFFFF:
            return b"\xce" + struct.pack("!I", value)
        if value >= 0:
            return b"\xcf" + struct.pack("!Q", value)
        if value >= -0x80:
            return b"\xd0" + struct.pack("!b", value)
        if value >= -0x8000:
            return b"\xd1" + struct.pack("!h", value)
        if value >= -0x80000000:
            return b"\xd2" + struct.pack("!i", value)
        return b"\xd3" + struct.pack("!q", value)
    if isinstance(value, float):
        return b"\xcb" + struct.pack("!d", value)
    if isinstance(value, str):
        payload = value.encode()
        size = len(payload)
        if size <= 31:
            return bytes((0xA0 | size,)) + payload
        if size <= 0xFF:
            return b"\xd9" + struct.pack("!B", size) + payload
        if size <= 0xFFFF:
            return b"\xda" + struct.pack("!H", size) + payload
        return b"\xdb" + struct.pack("!I", size) + payload
    if isinstance(value, (bytes, bytearray)):
        payload = bytes(value)
        size = len(payload)
        if size <= 0xFF:
            return b"\xc4" + struct.pack("!B", size) + payload
        if size <= 0xFFFF:
            return b"\xc5" + struct.pack("!H", size) + payload
        return b"\xc6" + struct.pack("!I", size) + payload
    if isinstance(value, (list, tuple)):
        size = len(value)
        header = (
            bytes((0x90 | size,))
            if size <= 15
            else b"\xdc" + struct.pack("!H", size)
            if size <= 0xFFFF
            else b"\xdd" + struct.pack("!I", size)
        )
        return header + b"".join(pack_message(item) for item in value)
    if isinstance(value, dict):
        size = len(value)
        header = (
            bytes((0x80 | size,))
            if size <= 15
            else b"\xde" + struct.pack("!H", size)
            if size <= 0xFFFF
            else b"\xdf" + struct.pack("!I", size)
        )
        return header + b"".join(
            pack_message(key) + pack_message(item) for key, item in value.items()
        )
    raise TypeError(f"cannot MessagePack encode {type(value).__name__}")


class _Unpacker:
    def __init__(self, payload: bytes):
        self.payload = payload
        self.offset = 0

    def take(self, size: int) -> bytes:
        end = self.offset + size
        if end > len(self.payload):
            raise ValueError("truncated MessagePack payload")
        value = self.payload[self.offset : end]
        self.offset = end
        return value

    def number(self, fmt: str):
        return struct.unpack(fmt, self.take(struct.calcsize(fmt)))[0]

    def unpack(self):
        prefix = self.take(1)[0]
        if prefix <= 0x7F:
            return prefix
        if prefix >= 0xE0:
            return prefix - 0x100
        if 0xA0 <= prefix <= 0xBF:
            return self.take(prefix & 0x1F).decode()
        if 0x90 <= prefix <= 0x9F:
            return [self.unpack() for _ in range(prefix & 0x0F)]
        if 0x80 <= prefix <= 0x8F:
            return {self.unpack(): self.unpack() for _ in range(prefix & 0x0F)}
        if prefix == 0xC0:
            return None
        if prefix in (0xC2, 0xC3):
            return prefix == 0xC3
        if prefix == 0xCA:
            return self.number("!f")
        if prefix == 0xCB:
            return self.number("!d")
        number_formats = {
            0xCC: "!B",
            0xCD: "!H",
            0xCE: "!I",
            0xCF: "!Q",
            0xD0: "!b",
            0xD1: "!h",
            0xD2: "!i",
            0xD3: "!q",
        }
        if prefix in number_formats:
            return self.number(number_formats[prefix])
        length_formats = {
            0xC4: ("!B", "bytes"),
            0xC5: ("!H", "bytes"),
            0xC6: ("!I", "bytes"),
            0xD9: ("!B", "str"),
            0xDA: ("!H", "str"),
            0xDB: ("!I", "str"),
            0xDC: ("!H", "array"),
            0xDD: ("!I", "array"),
            0xDE: ("!H", "map"),
            0xDF: ("!I", "map"),
        }
        if prefix not in length_formats:
            raise ValueError(f"unsupported MessagePack prefix 0x{prefix:02x}")
        fmt, kind = length_formats[prefix]
        size = self.number(fmt)
        if kind == "bytes":
            return self.take(size)
        if kind == "str":
            return self.take(size).decode()
        if kind == "array":
            return [self.unpack() for _ in range(size)]
        return {self.unpack(): self.unpack() for _ in range(size)}


def unpack_message(payload: bytes) -> Any:
    unpacker = _Unpacker(payload)
    value = unpacker.unpack()
    if unpacker.offset != len(payload):
        raise ValueError("trailing data after MessagePack value")
    return value


@dataclass(frozen=True)
class RerankRequest:
    instruct: str
    query: str
    docs: list[str]


class InferenceClient:
    def __init__(self, host: str = "build21.lan", port: int = 8015, timeout=3.0):
        self.host = host
        self.port = port
        self.timeout = timeout

    async def _request(self, message: dict[str, Any]) -> dict[str, Any]:
        async with asyncio.timeout(self.timeout):
            reader, writer = await asyncio.open_connection(self.host, self.port)
            try:
                payload = pack_message(message)
                writer.write(struct.pack("!I", len(payload)) + payload)
                await writer.drain()
                size = struct.unpack("!I", await reader.readexactly(4))[0]
                response = unpack_message(await reader.readexactly(size))
                if not isinstance(response, dict):
                    raise TypeError("inference response must be a map")
                return response
            finally:
                writer.close()
                await writer.wait_closed()

    async def embed(self, texts: list[str]) -> list[list[float]]:
        response = await self._request({"type": "embed", "texts": texts})
        return response["embeddings"]

    async def rerank(self, request: RerankRequest) -> list[float]:
        response = await self._request(
            {
                "type": "rerank",
                "instruct": request.instruct,
                "query": request.query,
                "docs": request.docs,
            }
        )
        return response["scores"]


def cosine_similarity(left: Sequence[float], right: Sequence[float]) -> float:
    if len(left) != len(right):
        raise ValueError("vectors must have the same dimensions")
    dot = sum(a * b for a, b in zip(left, right, strict=True))
    left_norm = math.sqrt(sum(value * value for value in left))
    right_norm = math.sqrt(sum(value * value for value in right))
    return dot / (left_norm * right_norm) if left_norm and right_norm else 0.0


def rank_by_embedding(
    query: Sequence[float],
    commands: Iterable[tuple[str, Sequence[float]]],
    *,
    limit: int,
) -> list[str]:
    scored = ((cosine_similarity(query, vector), command) for command, vector in commands)
    return [command for _score, command in sorted(scored, reverse=True)[:limit]]


class SemanticHistoryRetriever:
    INSTRUCTION = (
        "Find shell history commands useful for completing the current command line."
    )

    def __init__(
        self,
        client: InferenceClient,
        *,
        history_limit: int = 500,
        candidate_limit: int = 20,
        on_timing=None,
    ):
        self.client = client
        self.history_limit = history_limit
        self.candidate_limit = candidate_limit
        self.on_timing = on_timing
        self.vectors: dict[str, list[float]] = {}

    def _timing(self, stage: str, count: int, started_at: float) -> None:
        if self.on_timing is not None:
            self.on_timing(stage, count, (time.monotonic() - started_at) * 1000)

    def _unique_recent(self, history: Iterable[str]) -> list[str]:
        newest_first = reversed(list(history))
        commands = []
        seen = set()
        for value in newest_first:
            command = value.strip()
            if not command or command in seen:
                continue
            seen.add(command)
            commands.append(command)
            if len(commands) == self.history_limit:
                break
        return commands

    async def retrieve(
        self, query: str, history: Iterable[str], *, limit: int = 8
    ) -> list[str]:
        commands = self._unique_recent(history)
        if not commands:
            return []
        missing = [command for command in commands if command not in self.vectors]
        if missing:
            started_at = time.monotonic()
            vectors = await self.client.embed(missing)
            self.vectors.update(zip(missing, vectors, strict=True))
            self._timing("embed_new", len(missing), started_at)

        formatted_query = f"Instruct: {self.INSTRUCTION}\nQuery:{query}"
        started_at = time.monotonic()
        query_vector = (await self.client.embed([formatted_query]))[0]
        self._timing("embed_query", 1, started_at)
        started_at = time.monotonic()
        shortlist = rank_by_embedding(
            query_vector,
            ((command, self.vectors[command]) for command in commands),
            limit=min(self.candidate_limit, len(commands)),
        )
        self._timing("dot", len(commands), started_at)
        if not shortlist:
            return []
        started_at = time.monotonic()
        scores = await self.client.rerank(
            RerankRequest(self.INSTRUCTION, query, shortlist)
        )
        self._timing("rerank", len(shortlist), started_at)
        ranked = sorted(zip(scores, shortlist, strict=True), reverse=True)
        return [command for _score, command in ranked[:limit]]
