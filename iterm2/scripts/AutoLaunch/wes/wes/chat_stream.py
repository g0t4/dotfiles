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
from rare_alerts import slap_human
from logs import log

# Directory for iTerm2 streaming traces (mirrors nvim plugin's trace dir)
ASK_SHELL_TRACE_DIR = os.path.expanduser("~/.local/state/nvim/ask-openai/shell")
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
    clear_line: Callable[[], Awaitable[None]],
) -> None:
    """Stream OpenAI response and log trace after completion.

    Streaming chunks are sent via on_chunk as they arrive. After the stream
    completes, a trace file is written with session_id, messages, and full
    response metadata (token usage, timings, etc.).
    """
    show_asking = on_chunk("asking...")
    model, service = get_model()

    stream_kwargs = {}
    service.max_tokens = 10
    if service.max_tokens is not None:
        stream_kwargs["max_tokens"] = service.max_tokens

    all_content = ""
    all_reasoning = ""
    num_reasoning_chunks = 0
    response_metadata: dict = {}
    finish_reason: str | None = None

    # PRN temperature based on model or service default configs maybe (mostly I use default configs)?

    # PRN what happens if asking doesn't show in time? does it even matter if I don't wait for it before first chunk arrives?
    await show_asking  # don't let showing the asking... message block starting request to backend (assuming non-blocking I/O)

    last_chunk = None
    async for chunk in model.astream(messages, **stream_kwargs):
        try:
            last_chunk = chunk
            log(f'{chunk=}')

            if hasattr(chunk, "response_metadata") and chunk.response_metadata:
                response_metadata = dict(chunk.response_metadata)
                choices = response_metadata.get("choices", [])
                if choices:
                    last_choice = choices[-1]
                    finish_reason = last_choice.get("finish_reason")
                    # TODO do any langchain providers (that I use) not put finish_reason on the response_metadata?
                    #  if no then drop checking here in choices
                    log(f'found finish_reason on choice: {finish_reason=}')
                    slap_human(
                        "FYI you wanted to know if this ever happens...",
                        f"""finish_reason (in langchain providers) is on choices...
                            you have code you suspect is old and vestigial...
                            this proves you may want the code actually...
                            finish_reason={finish_reason!r} (see logs for more)""",
                    )

                if "finish_reason" in response_metadata:
                    # FYI I suspect all my langchain providers put the finish_reason here
                    finish_reason = response_metadata["finish_reason"]
                    log(f'found finish_reason on response_metadata: {finish_reason=}')

            # Capture reasoning_content from additional_kwargs (e.g. ChatLlamaServer)
            additional_kwargs = getattr(chunk, "additional_kwargs", None)
            if additional_kwargs is not None:
                chunk_reasoning = additional_kwargs.get("reasoning_content", "")
                if chunk_reasoning:
                    all_reasoning += chunk_reasoning

                    # * show thinking dots
                    if num_reasoning_chunks % 10 == 0:
                        # TODO try using inject instead of send text... I might be able to use ansi escape codes to color this and italicize it!
                        #    if I am just drawing on the iterm canvas and not interacting with the shell
                        if num_reasoning_chunks % 100 == 0:
                            await clear_line()
                            await on_chunk("thinking")
                        else:
                            await on_chunk(".")
                    num_reasoning_chunks += 1

            original_content = getattr(chunk, "content", "")
            # strip new lines to avoid submitting commands prematurely
            #   FYI I might be able to do shell specific alt+enter (or w/e meta keys to insert line wrap if supported)
            # TODO add tests of this too (test can pass on_chunk as write_text or smth like that) and accumulate it and verify that way
            safe_content = original_content.replace("\n", " ")  # PRN check if str before calling replace (i.e. can be list[str] or list[dict]... when is that the case and do I ever use it?)
            # PRN flag this situation and put flag on trace file? maybe alert me too so I take note and can decide if I like the "fix" of adding a space... I need real examples to decide
            #   I cannot really think of a time when the model gave me a multiline response

            is_first_content_chunk = original_content != "" and all_content == ""
            if is_first_content_chunk:
                # TODO test this
                #  TODO where do I strip the trailing ```???
                #  TODO does this ever happen? I can't imagine it doesnt... WTF... I would leave ``` on end and yet I can't think of a time I saw that
                #  TODO is ``` always in a single chunk?
                safe_content = re.sub(r'```', '', safe_content).lstrip()

                await clear_line()

            all_content += original_content
            await on_chunk(safe_content)

            if finish_reason == "length":
                # careful whatever you type is subject to applicable abbrs ;) so ... at start is gonna => cd ../..
                await on_chunk(f"# --- OOOPS I ran out off tokens, increase max_tokens {service.max_tokens=} --- ")
                break
            # TODO any other finish_reason I want to flag to user?

        except Exception as e:
            log(f"Error processing chunk: {e}\n chunk: {chunk}")
            await on_chunk(f"Error processing chunk: {e}")
            return

    # After streaming completes, write trace file
    _save_iterm2_trace(messages, all_content, response_metadata, finish_reason, service, last_chunk, all_reasoning)


def _save_iterm2_trace(
    messages: list[dict],
    full_content: str,
    response_metadata: dict,
    finish_reason: str | None,
    service: Service,
    last_chunk: AIMessageChunk,
    reasoning_content: str = "",
) -> None:
    """Write trace file after streaming completes.

    Mirrors the fish non-streaming trace format for consistency across
    both code paths (fish non-streaming and iTerm2 streaming).
    """
    try:
        os.makedirs(ASK_SHELL_TRACE_DIR, exist_ok=True)
    except OSError as e:
        log(f"Warning: could not create trace dir {ASK_SHELL_TRACE_DIR}: {e}")
        return

    # Build assistant message with content and any reasoning if available
    assistant_entry: dict = {"role": "assistant", "content": full_content}
    if response_metadata:
        if "reasoning_content" in response_metadata:
            assistant_entry["reasoning_content"] = response_metadata["reasoning_content"]
        if finish_reason is not None:
            assistant_entry["finish_reason"] = finish_reason

    # Add reasoning_content from additional_kwargs to trace
    if reasoning_content:
        assistant_entry["reasoning_content"] = reasoning_content

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
    trace_path = os.path.join(ASK_SHELL_TRACE_DIR, trace_filename)

    try:
        with open(trace_path, "w", encoding="utf-8") as trace_file:
            json.dump(trace_data, trace_file, indent=2, ensure_ascii=False)
        log(f"# trace saved: {trace_path}")
    except OSError as e:
        log(f"Warning: could not write trace file {trace_path}: {e}")
