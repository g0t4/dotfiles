from copy import deepcopy

import pytest
from langchain_core.messages import AIMessage

from clanker_mode import clank, run_agent
from trace_test_helpers import message_bodies, read_records


class Reply:
    def __init__(self, content):
        self.content = content
        self.inputs = []

    def bind_tools(self, tools):
        return self

    def invoke(self, messages):
        self.inputs.append(deepcopy(messages))
        return AIMessage(
            content=self.content, response_metadata={"finish_reason": "stop"}
        )


def test_session_appends_and_replays_without_changing_earlier_bytes(shell, tmp_path):
    first = Reply("first answer")
    assert (
        run_agent("first question", shell, model=first, trace_dir=tmp_path)
        == "first answer"
    )
    (path,) = tmp_path.glob("*.jsonl")
    before = path.read_bytes()
    original = read_records(path)
    # A changing shell/backend must not rewrite the original system prompt.
    shell.history = None
    second = Reply("second answer")
    run_agent("follow-up", shell, model=second, trace_dir=tmp_path)
    assert path.read_bytes().startswith(before)
    assert path.read_bytes().endswith(b"\n")
    records = read_records(path)
    assert records[: len(original)] == original
    assert list(tmp_path.glob("*.jsonl")) == [path]
    assert [record["sequence"] for record in records] == list(range(len(records)))
    assert [m.type for m in second.inputs[0]] == ["system", "human", "ai", "human"]
    assert second.inputs[0][0].content == first.inputs[0][0].content
    assert [m.content for m in second.inputs[0][1:]] == [
        "first question",
        "first answer",
        "follow-up",
    ]
    assert len([r for r in records if r["type"] == "session"]) == 1
    assert [r["status"] for r in records if r["type"] == "turn_end"] == [
        "success",
        "success",
    ]
    assert path.stat().st_mode & 0o777 == 0o600


def test_metadata_and_old_reasoning_stay_local_and_original_records_stay_intact(
    shell, tmp_path
):
    class Model(Reply):
        def invoke(self, messages):
            return AIMessage(
                content="answer",
                additional_kwargs={"reasoning_content": "saved reasoning"},
                response_metadata={"finish_reason": "stop", "custom": 123},
                usage_metadata={
                    "input_tokens": 10,
                    "output_tokens": 5,
                    "total_tokens": 15,
                },
            )

    run_agent("question", shell, model=Model(""), trace_dir=tmp_path)
    (path,) = tmp_path.glob("*.jsonl")
    before = path.read_bytes()
    second = Reply("next answer")
    run_agent("next", shell, model=second, trace_dir=tmp_path)
    assert path.read_bytes().startswith(before)
    sent = second.inputs[0][-2]
    assert "reasoning_content" not in sent.additional_kwargs
    assert sent.response_metadata == {}
    assert sent.usage_metadata is None
    assistant = next(
        r
        for r in read_records(path)
        if r["type"] == "message" and r["message"]["role"] == "assistant"
    )
    assert assistant["message"]["reasoning_content"] == "saved reasoning"
    assert assistant["metadata"]["response"]["custom"] == 123
    assert assistant["metadata"]["usage"]["total_tokens"] == 15
    assert "response" not in assistant["message"]


def test_clear_preserves_file_and_starts_a_fresh_context(shell, tmp_path, capsys):
    run_agent(
        "secret earlier question",
        shell,
        model=Reply("earlier answer"),
        trace_dir=tmp_path,
    )
    (path,) = tmp_path.glob("*.jsonl")
    before = path.read_bytes()
    assert clank(["--clear"]) == 0
    assert "trace retained" in capsys.readouterr().out
    assert path.read_bytes().startswith(before)
    second = Reply("fresh")
    run_agent("new question", shell, model=second, trace_dir=tmp_path)
    assert [m.type for m in second.inputs[0]] == ["system", "human"]
    assert second.inputs[0][-1].content == "new question"
    records = read_records(path)
    assert any(r["type"] == "context_reset" for r in records)
    assert any(
        m["content"] == "secret earlier question" for m in message_bodies(records)
    )
    assert len(list(tmp_path.glob("*.jsonl"))) == 1


def test_interrupted_tool_calls_are_closed_without_retry_before_followup(
    shell, tmp_path
):
    class Model(Reply):
        def invoke(self, messages):
            return AIMessage(
                content="",
                tool_calls=[
                    {
                        "id": "interrupted",
                        "name": "execute_in_current_xonsh",
                        "args": {"code": "raise KeyboardInterrupt()"},
                        "type": "tool_call",
                    },
                    {
                        "id": "unstarted",
                        "name": "execute_in_current_xonsh",
                        "args": {"code": "must_not_run = True"},
                        "type": "tool_call",
                    },
                ],
            )

    with pytest.raises(KeyboardInterrupt):
        run_agent("interrupt", shell, model=Model(""), trace_dir=tmp_path)
    assert "must_not_run" not in shell.ctx
    (path,) = tmp_path.glob("*.jsonl")
    before = path.read_bytes()
    next_model = Reply("recovered")
    assert (
        run_agent("continue", shell, model=next_model, trace_dir=tmp_path)
        == "recovered"
    )
    assert path.read_bytes().startswith(before)
    sent = next_model.inputs[0]
    assert [m.type for m in sent] == ["system", "human", "ai", "tool", "tool", "human"]
    assert sent[3].tool_call_id == "interrupted"
    assert "side effects may have occurred" in sent[3].content
    assert sent[4].tool_call_id == "unstarted"
    assert "not executed" in sent[4].content
    assert "must_not_run" not in shell.ctx
    records = read_records(path)
    assert any(
        r["type"] == "error" and r["error"]["class"] == "KeyboardInterrupt"
        for r in records
    )
    assert [r["status"] for r in records if r["type"] == "turn_end"] == [
        "interrupted",
        "success",
    ]


def test_api_error_is_retained_and_followup_has_prior_user_message(shell, tmp_path):
    class Model(Reply):
        def invoke(self, messages):
            raise RuntimeError("endpoint unavailable")

    with pytest.raises(RuntimeError, match="endpoint unavailable"):
        run_agent("question", shell, model=Model(""), trace_dir=tmp_path)
    next_model = Reply("back online")
    run_agent("retry", shell, model=next_model, trace_dir=tmp_path)
    assert [m.type for m in next_model.inputs[0]] == ["system", "human", "human"]
    (path,) = tmp_path.glob("*.jsonl")
    assert any(
        r["type"] == "error" and r["error"]["message"] == "endpoint unavailable"
        for r in read_records(path)
    )


def test_tail_reader_sees_complete_records_before_model_returns(shell, tmp_path):
    class Model(Reply):
        def invoke(self, messages):
            (path,) = tmp_path.glob("*.jsonl")
            assert path.read_bytes().endswith(b"\n")
            records = read_records(path)
            assert records[-1]["type"] == "message"
            assert records[-1]["message"] == {
                "role": "user",
                "content": "live question",
            }
            assert not any(r["type"] == "turn_end" for r in records)
            return AIMessage(content="done")

    run_agent("live question", shell, model=Model(""), trace_dir=tmp_path)
    (path,) = tmp_path.glob("*.jsonl")
    assert read_records(path)[-1]["type"] == "turn_end"
    assert clank(["--trace"]) == 0


def test_current_turn_reasoning_is_retained_in_the_input_view(shell, tmp_path):
    class Model(Reply):
        calls = 0

        def invoke(self, messages):
            self.calls += 1
            if self.calls == 1:
                return AIMessage(
                    content="",
                    additional_kwargs={"reasoning_content": "current reasoning"},
                    tool_calls=[
                        {
                            "id": "reasoning-call",
                            "name": "execute_in_current_xonsh",
                            "args": {"code": 'print("observed")'},
                            "type": "tool_call",
                        }
                    ],
                )
            assert (
                messages[-2].additional_kwargs["reasoning_content"]
                == "current reasoning"
            )
            return AIMessage(content="done")

    run_agent("question", shell, model=Model(""), trace_dir=tmp_path)


def test_malformed_tool_call_is_logged_but_not_replayed_as_a_pending_call(
    shell, tmp_path
):
    raw_call = {
        "id": "malformed",
        "type": "function",
        "function": {"name": "execute_in_current_xonsh", "arguments": "{bad json"},
    }

    class Model(Reply):
        def invoke(self, messages):
            return AIMessage(
                content="Invalid call", additional_kwargs={"tool_calls": [raw_call]}
            )

    with pytest.raises(RuntimeError, match="Invalid tool calls"):
        run_agent("question", shell, model=Model(""), trace_dir=tmp_path)
    next_model = Reply("recovered")
    run_agent("follow-up", shell, model=next_model, trace_dir=tmp_path)
    assert next_model.inputs[0][-2].tool_calls == []
    (path,) = tmp_path.glob("*.jsonl")
    records = read_records(path)
    assistant = next(
        r
        for r in records
        if r["type"] == "message" and r["message"]["role"] == "assistant"
    )
    assert assistant["metadata"]["invalid_tool_calls"]
    assert assistant["metadata"]["raw_tool_calls"] == [raw_call]
    assert "tool_calls" not in assistant["message"]


def test_trace_filenames_sort_within_and_across_minutes(tmp_path):
    from datetime import datetime

    from clanker_session import _create_trace_file

    moments = [
        datetime(2026, 11, 12, 15, 30, 0, 0),
        datetime(2026, 11, 12, 15, 30, 0, 1),
        datetime(2026, 11, 12, 15, 30, 1, 0),
        datetime(2026, 11, 12, 15, 30, 59, 999999),
        datetime(2026, 11, 12, 15, 31, 0, 0),
    ]
    paths = [_create_trace_file(tmp_path, moment) for moment in moments]
    names = [path.name for path in paths]
    assert names[0] == "2026-11-12_1530-0000000.jsonl"
    assert names[1] == "2026-11-12_1530-0000001.jsonl"
    assert names[-1] == "2026-11-12_1531-0000000.jsonl"
    assert sorted(names) == names
    assert all(len(path.stem.rsplit("-", 1)[1]) == 7 for path in paths)


def test_trace_filename_collisions_preserve_existing_files(tmp_path):
    from concurrent.futures import ThreadPoolExecutor
    from datetime import datetime

    from clanker_session import _create_trace_file

    moment = datetime(2026, 11, 12, 15, 30, 12, 345678)
    original = _create_trace_file(tmp_path, moment)
    original.write_text("existing trace\n")
    with ThreadPoolExecutor(max_workers=4) as workers:
        paths = list(
            workers.map(lambda _: _create_trace_file(tmp_path, moment), range(12))
        )
    assert len(set(paths)) == 12
    assert original not in paths
    assert original.read_text() == "existing trace\n"
    assert all(path.stat().st_mode & 0o777 == 0o600 for path in paths)
