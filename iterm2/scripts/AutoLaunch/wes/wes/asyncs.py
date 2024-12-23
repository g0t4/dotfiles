import re
from client import get_ask_client
from logs import log


async def ask_openai_async_type_response(session, messages):
    use, client = get_ask_client()

    if use.name == "anthropic":
        # PRN impl streaming anthropic here based on httpx only
        # TODO impl it elsewhere and plug it in here, testing by restarting wes.py is a PITA
        # TODO I MOVED anthropic impl when I redid single.py... needs redone here too
        # from single import get_anthropic_suggestion
        # command = get_anthropic_suggestion(current_command, use)
        # await session.async_send_text(command)
        log("anthropic impl not redone since moving it in single.py")
        return

    # *** request completion
    try:
        response_stream = await client.chat.completions.create(
            model=use.model,
            messages=messages,
            max_tokens=200,
            # TODO temperature?
            stream=True)
    except Exception as e:
        # TODO test timeouts?
        log(f"Error contacting OpenAI: {e}")
        await session.async_send_text(f"Error contacting API endpoint: {e}")
        return

    # *** stream the reponse chunks
    # TODO write some tests for sanitizing and use a seam here

    first_chunk = True
    async for chunk in response_stream:
        # FYI w.r.t ``` ... deepseek-chat listens to request to not use ``` and ``` but deepseek-coder always returns ```... that actually makes sense for the coder...
        if chunk.choices[0].delta.content is not None:
            # strip new lines to avoid submitting commands prematurely, is there an alternate char I could use to split the lines still w/o submitting (would have to check what the shell supports, if anything is possible)... one downside to not being a part of the line editor.. unless there is a workaround? not that I care much b/c multi line commands are not often necessary...
            sanitized = chunk.choices[0].delta.content.replace("\n", " ")
            if first_chunk:
                print(f"first_chunk: {sanitized}")
                sanitized = re.sub(r'```', '', sanitized).lstrip()
                print(f"sanitized: {sanitized}")
                print(f"sanitized hex: {sanitized.encode('utf-8').hex()}")
                first_chunk = sanitized == ""  # stay in "first_chunk" mode until first non-empty chunk
                await session.async_send_text(sanitized)
            else:
                await session.async_send_text(sanitized)
            # TODO is there a way to detect last chunk?
    # after last chunk, can I remove ending ``` and spaces? it might span multiple last chunks btw so wouldn't just be able to keep track of last chunk, would need entire response and then detect if ends with ``` and spaces and then delete those chars?
    # ideally I would have some sort of streaming mechanism that would detect leading/trailing ``` and spaces... and then no correction is needed to delete chars`
