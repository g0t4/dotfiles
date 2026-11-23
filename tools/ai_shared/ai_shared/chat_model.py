"""Keep local backend diagnostics alongside LangChain's normalized usage."""

from copy import deepcopy

from langchain_llama_server.chat_models import ChatLlamaServer


def preserve_diagnostics(message, response):
    # Keep diagnostics out of additional_kwargs, which become model input.
    for field in ("metrics", "timings", "sglext"):
        value = (
            response.get(field)
            if isinstance(response, dict)
            else getattr(response, field, None)
        )
        if value is not None:
            message.response_metadata[field] = deepcopy(value)


class LocalChatModel(ChatLlamaServer):
    """Preserve backend extensions for both JSON and SSE responses."""

    def _create_chat_result(self, response, generation_info=None):
        result = super()._create_chat_result(response, generation_info)
        for generation in result.generations:
            preserve_diagnostics(generation.message, response)
        return result

    def _convert_chunk_to_generation_chunk(
        self, chunk, default_chunk_class, base_generation_info
    ):
        generation = super()._convert_chunk_to_generation_chunk(
            chunk, default_chunk_class, base_generation_info
        )
        if generation is not None:
            preserve_diagnostics(generation.message, chunk)
        return generation
