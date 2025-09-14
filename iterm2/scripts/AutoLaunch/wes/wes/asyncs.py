import re
from client import get_ask_client
from logs import log

async def ask_openai_async_type_response(session, messages):
    use, client = get_ask_client()
    log(f"using {use.log_safe_string()}")

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
        log(f"Error contacting API: {e}")
        await session.async_send_text(f"Error contacting API endpoint: {e}")
        return

    # *** stream the reponse chunks
    # TODO write some tests for sanitizing and use a seam here

    # ! TODO... what actually differs here vs OpenAI...  can I just merge this logic into one handler, is it a diff field in response or?
    first_chunk = True
    async for chunk in response_stream:
        try:

            if not chunk.choices \
                or len(chunk.choices) == 0 \
                or chunk.choices[0].delta is None \
                or chunk.choices[0].delta.content is None:
                # FYI llama-server, last SSE doesn't have any choices, and that's normal
                log(f"no chunk choices: {chunk}")
                continue

            # strip new lines to avoid submitting commands prematurely, is there an alternate char I could use to split the lines still w/o submitting (would have to check what the shell supports, if anything is possible)... one downside to not being a part of the line editor.. unless there is a workaround? not that I care much b/c multi line commands are not often necessary...
            sanitized = chunk.choices[0].delta.content.replace("\n", " ")  # TODO oh man this is not good.. I wanna keep new lines... I also might need to use semicolon (or shell specific separator to do this)
            if first_chunk:
                log(f"first_chunk: {sanitized}")
                sanitized = re.sub(r'```', '', sanitized).lstrip()
                log(f"sanitized: {sanitized}")
                log(f"sanitized hex: {sanitized.encode('utf-8').hex()}")
                first_chunk = sanitized == ""  # stay in "first_chunk" mode until first non-empty chunk
                await session.async_send_text(sanitized)
            else:
                await session.async_send_text(sanitized)

            # if is_last_chunk:
            #    strip trailing "```" => how often does this happen though?
            # TODO is there a way to detect last chunk? => actually IIRC yes... there is a stop reason on each chunk, IIRC
            # after last chunk, can I remove ending ``` and spaces? it might span multiple last chunks btw so wouldn't just be able to keep track of last chunk, would need entire response and then detect if ends with ``` and spaces and then delete those chars?

        except Exception as e:
            log(f"Error processing chunk: {e}\n chunk: {chunk}")
            await session.async_send_text(f"Error processing chunk: {e}")
            return
