import asyncio
import math
import msgpack
import test_setup

from wes_semantic_history import (  # noqa: E402
    InferenceClient,
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
