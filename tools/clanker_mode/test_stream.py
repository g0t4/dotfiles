import pytest
from langchain_core.messages import AIMessageChunk

from clanker_mode import run_agent
from trace_test_helpers import read_records


def fragment(index, name=None, args=None, identifier=None):
    return {"index": index, "name": name, "args": args, "id": identifier}


@pytest.mark.parametrize("finish", ["tool_calls", None, KeyboardInterrupt])
def test_partial_tool_calls_require_finished_json(shell, tmp_path, finish):
    previews = []
    args = '{"code": "ran_partial = True"'

    class Model:
        def bind_tools(self, tools):
            return self

        def stream(self, messages):
            yield AIMessageChunk(
                content="", additional_kwargs={"reasoning_content": "inspect"}
            )
            yield AIMessageChunk(
                content="",
                tool_call_chunks=[
                    fragment(0, "execute_in_current_xonsh", args[:10], "one")
                ],
            )
            yield AIMessageChunk(
                content="", tool_call_chunks=[fragment(0, args=args[10:])]
            )
            if finish is KeyboardInterrupt:
                raise KeyboardInterrupt
            if finish:
                yield AIMessageChunk(
                    content="", response_metadata={"finish_reason": finish}
                )

    def observe(event, message):
        if event == "assistant_partial":
            previews.append(message)

    with pytest.raises(
        KeyboardInterrupt if finish is KeyboardInterrupt else RuntimeError
    ):
        run_agent("try it", shell, model=Model(), trace_dir=tmp_path, on_event=observe)
    assert previews[0].additional_kwargs["reasoning_content"] == "inspect"
    assert previews[1].tool_call_chunks[0]["args"] == args[:10]
    records = read_records(next(tmp_path.glob("*.jsonl")))
    assistants = [r for r in records if r.get("message", {}).get("role") == "assistant"]
    if finish == "tool_calls":
        (record,) = assistants
        assert "tool_calls" not in record["message"]
        assert record["metadata"]["invalid_tool_calls"][0]["args"] == args
        assert record["metadata"]["raw_tool_calls"][0]["function"]["arguments"] == args
    else:
        assert not assistants
    assert records[-1]["status"] == (
        "interrupted" if finish is KeyboardInterrupt else "error"
    )
    assert "ran_partial" not in shell.ctx


def test_parallel_calls_retain_raw_arguments_and_trailing_usage():
    from clanker_session import serialize_message
    from clanker_stream import CompletionStream

    completion = CompletionStream(None)
    completion.add(
        AIMessageChunk(
            content="",
            id="response",
            tool_call_chunks=[
                fragment(1, "second", '{"b":', "two"),
                fragment(0, "first", '{"a":', "one"),
            ],
        )
    )
    completion.add(
        AIMessageChunk(
            content="",
            tool_call_chunks=[
                fragment(0, args="  1}"),
                fragment(1, args="2}"),
            ],
            response_metadata={"finish_reason": "tool_calls"},
        )
    )
    usage = {"input_tokens": 10, "output_tokens": 2, "total_tokens": 12}
    completion.add(
        AIMessageChunk(
            content="",
            usage_metadata=usage,
            response_metadata={"metrics": {"time": 0.2}},
        )
    )
    answer = completion.finish()
    assert [call["args"] for call in answer.tool_calls] == [{"a": 1}, {"b": 2}]
    body, metadata = serialize_message(answer)
    assert [call["function"]["arguments"] for call in body["tool_calls"]] == [
        '{"a":  1}',
        '{"b":2}',
    ]
    assert metadata["response"] == {
        "finish_reason": "tool_calls",
        "metrics": {"time": 0.2},
    }
    assert metadata["usage"] == usage
    assert metadata["provider_message_id"] == "response"
