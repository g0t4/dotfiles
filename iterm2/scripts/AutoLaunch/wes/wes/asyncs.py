import re
from client import get_ask_client, get_use
from logs import log
from langchain_openai import ChatOpenAI

async def ask_openai_async_type_response(session, messages):
    use, client = get_ask_client()
    log(f"using {use.log_safe_string()}")

    # * langchain instead:
    # cut out get_ask_client above when done w/ old IMPL, just need "use" here and don't wanna make openai client just to get use:
    use = get_use()
    log(f"got use: {use}")
    api_key = use.api_key or ""  # must set empty at least
    model = ChatOpenAI(model=use.model, api_key=api_key, base_url=use.base_url)
    # FYI I had use.chat_completions_path too but shouldn't need it beyond MAYBE vllm (anthropic will be handled above w/ diff Chat client)

    if use.name == "anthropic":
        from langchain_anthropic import ChatAnthropic
        model = ChatAnthropic(model_name=use.model, api_key=use.api_key, timeout=None, stop=None)
        return

    # max_tokens=use.max_tokens or 200,
    # TODO temperature? and other model params on Service? (maybe rename it to be ServiceModel combo?)
    chunks = model.stream(messages)
    for chunk in chunks:
        # FYI no reasoning content for llama-server, s/b fine as I don't use that => if I want it, I can add in my ChatLlamaServer impl
        await session.async_send_text(chunk.content)
        # TODO can I check finish_reason to see if it ran out of tokens?
        # if choice0.finish_reason == "length":
        #     await session.async_send_text(f"ran out off tokens, increase max_tokens...")
        #     break
    return

    # *** stream the reponse chunks
    first_chunk = True
    async for chunk in response_stream:
        try:

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
