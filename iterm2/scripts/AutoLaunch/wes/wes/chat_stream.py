import json
import os
import re
import time
from collections.abc import Awaitable, Callable

os.environ["TRANSFORMERS_NO_ADVISORY_WARNINGS"] = "1"
from langchain_core.language_models.chat_models import BaseChatModel

from langchain_llama_server.chat_models import ChatLlamaServer
from langchain_core.messages import AIMessageChunk
from services import Service, get_selected_service
from logs import log

# Directory for iTerm2 streaming traces (mirrors nvim plugin's trace dir)
ITERM2_TRACE_DIR = os.path.expanduser("~/.local/state/nvim/ask-openai/fish")

TIMEOUT_SECONDS = 15

def get_model() -> tuple[BaseChatModel, Service]:
    service = get_selected_service()
    log(f"using: {service}")

    if service.name == "anthropic":
        from langchain_anthropic import ChatAnthropic
        model = ChatAnthropic(
            model_name=service.model,
            api_key=service.api_key,
            timeout=TIMEOUT_SECONDS,
            stop=None,
        )
        return model, service

    if service.name == "ask_lan":
        model = ChatLlamaServer(
            model=service.model,
            base_url=service.base_url,
            timeout=TIMEOUT_SECONDS,
            api_key="",
        )
        return model, service

    from langchain_openai import ChatOpenAI
    model = ChatOpenAI(
        model=service.model,
        api_key=service.api_key,
        base_url=service.base_url,
        timeout=TIMEOUT_SECONDS,
        # max_retries=2
    )
    return model, service

async def ask_openai_async_type_response(
    messages: list[dict],
    on_chunk: Callable[[str], Awaitable[None]],
) -> None:
    """Stream OpenAI response and log trace after completion.

    Streaming chunks are sent via on_chunk as they arrive. After the stream
    completes, a trace file is written with session_id, messages, and full
    response metadata (token usage, timings, etc.).
    """
    log(f"{messages=}")
    model, service = get_model()

    stream_kwargs = {}
    if service.max_tokens is not None:
        stream_kwargs["max_tokens"] = service.max_tokens

    # Accumulate full assistant content and capture response_metadata from final chunk
    full_content = ""
    first_chunk = True
    response_metadata: dict = {}
    finish_reason: str | None = None

    # PRN temperature based on model or service default configs maybe (mostly I use default configs)?
    chunks = model.astream(messages, **stream_kwargs)
    last_chunk = None
    async for chunk in chunks:
        try:
            last_chunk = chunk
            log(f'{chunk=}')
            # NOTE: ChatLlamaServer supports reasoning_content via additional_kwargs
            # Extract token_usage/timings from the last chunk's response_metadata
            if hasattr(chunk, "response_metadata") and chunk.response_metadata:
                response_metadata = dict(chunk.response_metadata)
                choices = response_metadata.get("choices", [])
                if choices:
                    last_choice = choices[-1]
                    finish_reason = last_choice.get("finish_reason")

            # Process content chunks
            content = getattr(chunk, "content", None)
            if content is None:
                continue

            # strip new lines to avoid submitting commands prematurely, is there an alternate char I could use to split the lines still w/o submitting (would have to check what the shell supports, if anything is possible)... one downside to not being a part of the line editor.. unless there is a workaround? not that I care much b/c multi line commands are not often necessary...
            sanitized = content.replace("\n", " ")  # PRN check if str before calling replace (i.e. can be list[str] or list[dict]... when is that the case and do I ever use it?)
            if sanitized.strip() == "":
                continue

            if first_chunk:
                log(f"first_chunk: {sanitized}")
                sanitized = re.sub(r'```', '', sanitized).lstrip()
                log(f"sanitized: {sanitized}")
                log(f"sanitized hex: {sanitized.encode('utf-8').hex()}")
                first_chunk = sanitized == ""  # stay in "first_chunk" mode until first non-empty chunk

            full_content += content
            await on_chunk(sanitized)

            # TODO can I check finish_reason to see if it ran out of tokens?
            # if choice0.finish_reason == "length":
            #     await on_chunk(f"ran out off tokens, increase max_tokens...")
            #     break

        except Exception as e:
            log(f"Error processing chunk: {e}\n chunk: {chunk}")
            await on_chunk(f"Error processing chunk: {e}")
            return

    # After streaming completes, write trace file
    _save_iterm2_trace(messages, full_content, response_metadata, finish_reason, service, last_chunk)

def _save_iterm2_trace(
    messages: list[dict],
    full_content: str,
    response_metadata: dict,
    finish_reason: str | None,
    service: Service,
    last_chunk: AIMessageChunk,
) -> None:
    """Write trace file after streaming completes.

    Mirrors the fish non-streaming trace format for consistency across
    both code paths (fish non-streaming and iTerm2 streaming).
    """
    try:
        os.makedirs(ITERM2_TRACE_DIR, exist_ok=True)
    except OSError as e:
        log(f"Warning: could not create trace dir {ITERM2_TRACE_DIR}: {e}")
        return

    # Build assistant message with content and any reasoning if available
    assistant_entry: dict = {"role": "assistant", "content": full_content}
    if response_metadata:
        if "reasoning_content" in response_metadata:
            assistant_entry["reasoning_content"] = response_metadata["reasoning_content"]
        if finish_reason is not None:
            assistant_entry["finish_reason"] = finish_reason

    trace_messages = list(messages)  # copy system + user messages
    trace_messages.append(assistant_entry)

    # Build the response object from response_metadata
    response_data: dict = {}
    if response_metadata:
        response_data = dict(response_metadata)

    # Add model info that might not be in response_metadata
    response_data["model"] = service.model
    response_data["service"] = service.name

    unix_timestamp = int(time.time())
    trace_data: dict = {
        "session_id": unix_timestamp,
        "messages": trace_messages,
        "response": response_data,

        # TODO! switch to my langchain-llama-server client and grab timings + __verbose (if set) => basically grab last_sse (add it if needed to client)
        # "last_sse": {
        #     "timings": last_chunk.timings
        # }
        # "last_chunk": last_chunk # TODO! rename to last_sse? AIMessageChunk is not serializable
    }

    trace_filename = f"{unix_timestamp}-trace.json"
    trace_path = os.path.join(ITERM2_TRACE_DIR, trace_filename)

    try:
        with open(trace_path, "w", encoding="utf-8") as trace_file:
            json.dump(trace_data, trace_file, indent=2, ensure_ascii=False)
        log(f"# trace saved: {trace_path}")
    except OSError as e:
        log(f"Warning: could not write trace file {trace_path}: {e}")
