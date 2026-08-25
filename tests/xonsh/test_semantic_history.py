import asyncio
import math
import sys
from pathlib import Path

import msgpack


XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))

from wes_semantic_history import (  # noqa: E402
    InferenceClient,
    SemanticHistoryRetriever,
    cosine_similarity,
    pack_message,
    rank_by_embedding,
    unpack_message,
)


def test_messagepack_codec_matches_backend_protocol_types():
    message = {
        "type": "embed",
        "texts": ["git status", "docker ps"],
        "enabled": True,
        "limit": 12,
        "temperature": 0.25,
    }

    encoded = pack_message(message)

    assert msgpack.unpackb(encoded, raw=False) == message
    assert unpack_message(msgpack.packb(message, use_bin_type=True)) == message


def test_cosine_similarity_and_ranking_are_plain_dot_product_math():
    query = [1.0, 1.0]
    commands = [
        ("git status", [1.0, 0.9]),
        ("docker ps", [-1.0, 0.0]),
        ("git log", [0.8, 1.0]),
    ]

    assert math.isclose(cosine_similarity(query, [1.0, 0.0]), 2**-0.5)
    assert rank_by_embedding(query, commands, limit=2) == ["git status", "git log"]


def test_async_client_speaks_length_prefixed_messagepack():
    async def scenario():
        requests = []

        async def handle(reader, writer):
            size = int.from_bytes(await reader.readexactly(4), "big")
            request = unpack_message(await reader.readexactly(size))
            requests.append(request)
            response = {"embeddings": [[0.25, -0.5]]}
            payload = pack_message(response)
            writer.write(len(payload).to_bytes(4, "big") + payload)
            await writer.drain()
            writer.close()
            await writer.wait_closed()

        server = await asyncio.start_server(handle, "127.0.0.1", 0)
        port = server.sockets[0].getsockname()[1]
        async with server:
            result = await InferenceClient("127.0.0.1", port).embed(["git status"])

        assert requests == [{"type": "embed", "texts": ["git status"]}]
        assert result == [[0.25, -0.5]]

    asyncio.run(scenario())


def test_semantic_retriever_caches_command_vectors_and_reranks_shortlist():
    class FakeClient:
        def __init__(self):
            self.embed_calls = []
            self.rerank_docs = []

        async def embed(self, texts):
            self.embed_calls.append(texts)
            vectors = {
                "git status": [1.0, 0.0],
                "git log": [0.9, 0.1],
                "docker ps": [0.0, 1.0],
            }
            return [vectors.get(text, [1.0, 0.0]) for text in texts]

        async def rerank(self, request):
            self.rerank_docs.append(request.docs)
            scores = {"git log": 0.9, "git status": 0.7, "docker ps": 0.1}
            return [scores[doc] for doc in request.docs]

    async def scenario():
        client = FakeClient()
        retriever = SemanticHistoryRetriever(client, candidate_limit=3)
        history = ["git status", "docker ps", "git status", "git log"]

        first = await retriever.retrieve("git show", history, limit=2)
        second = await retriever.retrieve("git inspect", history, limit=2)

        assert first == ["git log", "git status"]
        assert second == ["git log", "git status"]
        assert client.embed_calls[0] == ["git log", "git status", "docker ps"]
        assert client.embed_calls[1][0].startswith("Instruct:")
        assert client.embed_calls[2][0].startswith("Instruct:")
        assert len(client.embed_calls) == 3

    asyncio.run(scenario())


def test_semantic_retriever_skips_backend_for_empty_history():
    class BackendMustNotRun:
        async def embed(self, _texts):
            raise AssertionError("empty history should not be embedded")

    result = asyncio.run(
        SemanticHistoryRetriever(BackendMustNotRun()).retrieve("git", [])
    )

    assert result == []
