import re
from services import get_selected_service
from logs import log

def get_model():

    service = get_selected_service()
    log(f"using: {service}")

    if service.name == "anthropic":
        # TODO is this one slow too? measure it
        from langchain_anthropic import ChatAnthropic
        model = ChatAnthropic(
            model_name=service.model,
            api_key=service.api_key,
            timeout=None,
            stop=None,
        )
    else:
        # TODO why is this import so slow?
        from langchain_openai import ChatOpenAI
        model = ChatOpenAI(
            model=service.model,
            api_key=service.api_key,
            base_url=service.base_url,
        )

async def ask_openai_async_type_response(session, messages):
    model = get_model()

    # max_tokens=use.max_tokens or 200,
    # TODO temperature? and other model params on Service? (maybe rename it to be ServiceModel combo?)
    chunks = model.stream(messages)
    first_chunk = True
    for chunk in chunks:
        try:
            # FYI no reasoning content for llama-server, s/b fine as I don't use that => if I want it, I can add in my ChatLlamaServer impl
            # strip new lines to avoid submitting commands prematurely, is there an alternate char I could use to split the lines still w/o submitting (would have to check what the shell supports, if anything is possible)... one downside to not being a part of the line editor.. unless there is a workaround? not that I care much b/c multi line commands are not often necessary...
            sanitized = chunk.content.replace("\n", " ")  # PRN check if str before calling replace (i.e. can be list[str] or list[dict]... when is that the case and do I ever use it?)
            if sanitized.strip() == "":
                continue

            if first_chunk:
                log(f"first_chunk: {sanitized}")
                sanitized = re.sub(r'```', '', sanitized).lstrip()
                log(f"sanitized: {sanitized}")
                log(f"sanitized hex: {sanitized.encode('utf-8').hex()}")
                first_chunk = sanitized == ""  # stay in "first_chunk" mode until first non-empty chunk
                await session.async_send_text(sanitized)
            else:
                await session.async_send_text(sanitized)

            # TODO can I check finish_reason to see if it ran out of tokens?
            # if choice0.finish_reason == "length":
            #     await session.async_send_text(f"ran out off tokens, increase max_tokens...")
            #     break

        except Exception as e:
            log(f"Error processing chunk: {e}\n chunk: {chunk}")
            await session.async_send_text(f"Error processing chunk: {e}")
            return
