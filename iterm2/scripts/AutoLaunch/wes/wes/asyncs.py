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
            max_tokens=2000,  # TODO pass as another arg to ask_use_*
            # TODO temperature?
            stream=True)
    except Exception as e:
        # TODO test timeouts?
        log(f"Error contacting API: {e}")
        await session.async_send_text(f"Error contacting API endpoint: {e}")
        return

    # *** stream the reponse chunks
    first_chunk = True
    async for chunk in response_stream:
        try:
            if not chunk.choices \
                or len(chunk.choices) == 0 \
                or not chunk.choices[0].delta:

                # * reasoning example (llama-server)
                # choices=[(
                #     delta=(
                #          content=None,
                #          function_call=None,
                #          refusal=None,
                #          role=None,
                #          tool_calls=None,
                #          reasoning_content="'"
                #     ),
                #     finish_reason=None,
                # )],
                log(f"no chunk choices/delta: {chunk}")
                continue

            choice0 = chunk.choices[0]
            if hasattr(choice0, "finish_reason") and choice0.finish_reason:
                # * llama server stop on max_tokens (length)
                # (choices=[(
                #    delta= (content=None, function_call=None, refusal=None, role=None, tool_calls=None),
                #    finish_reason='length')],
                #    timings={'cache_n': 79, 'prompt_n': 65, 'prompt_ms': 54.432, 'prompt_per_token_ms': 0.8374153846153847,
                #        'prompt_per_second': 1194.1504997060551, 'predicted_n': 200, 'predicted_ms': 766.16,
                #        'predicted_per_token_ms': 3.8308, 'predicted_per_second': 261.0420799832933})
                log(f"finish_reason: {choice0.finish_reason}")
                if choice0.finish_reason == "stop":
                    break
                if choice0.finish_reason == "length":
                    await session.async_send_text(f"ran out off tokens, increase max_tokens...")
                    break
                else:
                    log(f"Unhandled finish_reason: {choice0.finish_reason}, stopping")
                    break

            delta = choice0.delta
            if hasattr(delta, "reasoning_content"):
                log(f"[SKIP] reasoning_content: {delta.reasoning_content}")
                continue
            # TODO delta.reasoning field too? ollama?

            if delta.content is None:
                # FYI llama-server, last SSE doesn't have any choices, and that's normal
                log(f"[SKIP] no reasoning, no content: {chunk}")
                continue

            # strip new lines to avoid submitting commands prematurely, is there an alternate char I could use to split the lines still w/o submitting (would have to check what the shell supports, if anything is possible)... one downside to not being a part of the line editor.. unless there is a workaround? not that I care much b/c multi line commands are not often necessary...
            sanitized = delta.content.replace("\n", " ")
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
