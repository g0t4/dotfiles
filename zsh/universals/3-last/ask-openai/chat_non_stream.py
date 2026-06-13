import os
import re
from dataclasses import dataclass, field
from typing import Any

os.environ["TRANSFORMERS_NO_ADVISORY_WARNINGS"] = "1"
from langchain_core.language_models.chat_models import BaseChatModel

from langchain_llama_server.chat_models import ChatLlamaServer
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage
from services import Service, get_selected_service

# TODO testing this with only one consumer: (ctrl-b via single.py)
# TODO test anthropic
# DONE: openai/llama-server

TIMEOUT_SECONDS = 15


@dataclass
class GenerationResult:
    """Encapsulates the result of a non-streaming generation call."""
    content: str
    failed: bool = False
    service_name: str = ""
    model: str = ""
    response_metadata: dict[str, Any] = field(default_factory=dict)
    raw_ai_message: AIMessage | None = None


def get_model() -> tuple[BaseChatModel, Service]:
    service = get_selected_service()
    # log(f"using: {service}")

    if service.name == "anthropic":
        # FYI importing langchain_anthropic is ALSO slow b/c anthropic package eager loads basically everything on import!
        #  TBH this is NBD for my wes.py daemon b/c it loads once
        #    annoying for my rarely used ctrl-b keymap (not a daemon, takes hit every time)
        #  I setup a POC (proof of concept) to optimize this massively:
        #    https://github.com/anthropics/anthropic-sdk-python/issues/1211
        #    already 35% to 60% reduction in import time for several key modules
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

    # FYI importing langchain_openai is slow b/c openai.types is missing lazy loading with 100s of pydantic based types:
    # https://github.com/openai/openai-python/issues/2819
    # IOTW import langchain_openai suffers b/c it imports openai (which takes 220 to 300ms)
    from langchain_openai import ChatOpenAI
    model = ChatOpenAI(
        model=service.model,
        api_key=service.api_key,
        base_url=service.base_url,
        timeout=TIMEOUT_SECONDS,
        # max_retries=2
    )
    return model, service


def generate_non_streaming(passed_context: str, system_message: str, max_tokens: int) -> GenerationResult:
    model, service = get_model()
    messages = [
        SystemMessage(content=system_message),
        HumanMessage(content=passed_context),
    ]

    # TODO add temperature (optional) to Service? (perhaps rename to ServiceModel or split out generation args somehow)
    # PRN timeout?
    ai_message: AIMessage = model.invoke(messages, max_tokens=max_tokens)
    content = ai_message.content
    if not isinstance(content, str):
        # FYI implement other types as encountered so I can see what I am working with
        return GenerationResult(
            content=f"ABORT... expected string content but got {type(content).__name__} for response: {content}",
            failed=True,
            service_name=service.name,
            model=service.model,
        )

    try:
        # NOTE: ChatLlamaServer supports reasoning_content via additional_kwargs
        # strip new lines to avoid submitting commands prematurely, is there an alternate char I could use to split the lines still w/o submitting (would have to check what the shell supports, if anything is possible)... one downside to not being a part of the line editor.. unless there is a workaround? not that I care much b/c multi line commands are not often necessary...
        sanitized = content.replace("\n", " ")  # PRN check if str before calling replace (i.e. can be list[str] or list[dict]... when is that the case and do I ever use it?)
        sanitized = re.sub(r'```', '', sanitized).lstrip()

        # Capture reasoning_content from additional_kwargs for trace only
        response_metadata: dict[str, Any] = dict(getattr(ai_message, "response_metadata", {}))
        additional_kwargs = getattr(ai_message, "additional_kwargs", None)
        if additional_kwargs is not None:
            reasoning_content = additional_kwargs.get("reasoning_content", "")
            if reasoning_content:
                response_metadata["reasoning_content"] = reasoning_content

        # TODO should I check finish_reason to see if it ran out of tokens? and warn if so? (or better yet, offer to resume?)
        # if choice0.finish_reason == "length":
        #     await session.async_send_text(f"ran out off tokens, increase max_tokens...")
        #     break

        return GenerationResult(
            content=sanitized,
            service_name=service.name,
            model=service.model,
            response_metadata=response_metadata,
            raw_ai_message=ai_message,
        )
    except Exception as e:
        return GenerationResult(
            content=f"Error processing chunk: {e}\n chunk: {content}",
            failed=True,
            service_name=service.name,
            model=service.model,
        )


# generate_non_streaming("what is your name?", "be honest", 20)
