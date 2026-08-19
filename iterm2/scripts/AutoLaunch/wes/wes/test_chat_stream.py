from chat_stream import ask_openai_async_type_response

messages = [{"role": "user", "content": "test"}]


async def on_chunk(chunk):
    print(chunk)


async def clear_line():
    pass


async def main():
    await ask_openai_async_type_response(messages, on_chunk, clear_line)


import asyncio
asyncio.run(main())
