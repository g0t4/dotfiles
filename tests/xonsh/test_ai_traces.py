import json
import sys
from pathlib import Path


XONSH_LIB = Path(__file__).parents[2] / ".config/xonsh/lib"
sys.path.insert(0, str(XONSH_LIB))

from wes_ai_traces import build_chat_trace, save_chat_trace  # noqa: E402


def test_build_chat_trace_matches_existing_schema():
    messages = [
        {"role": "system", "content": "complete commands"},
        {"role": "user", "content": "command_before_cursor=git "},
    ]
    last_sse = {
        "model": "local-model",
        "system_fingerprint": "build21",
        "choices": [{"delta": {}, "finish_reason": "stop", "index": 0}],
        "timings": {"prompt_n": 12, "predicted_n": 2},
    }

    trace = build_chat_trace(
        messages=messages,
        full_content="status",
        reasoning_content="The likely command is git status.",
        model="requested-model",
        service="xonsh_ai_autosuggest",
        last_sse=last_sse,
        session_id=123,
    )

    assert trace["session_id"] == 123
    assert trace["messages"][:2] == messages
    assert trace["messages"][-1] == {
        "role": "assistant",
        "content": "status",
        "finish_reason": "stop",
        "reasoning_content": "The likely command is git status.",
    }
    assert trace["response"] == {
        "model": "requested-model",
        "service": "xonsh_ai_autosuggest",
        "system_fingerprint": "build21",
        "timings": {"prompt_n": 12, "predicted_n": 2},
        "finish_reason": "stop",
    }
    assert trace["last_sse"] == last_sse


def test_save_chat_trace_preserves_existing_file(tmp_path):
    trace = {"session_id": 123, "messages": [], "response": {}}

    first = save_chat_trace(trace, tmp_path)
    second = save_chat_trace(trace, tmp_path)

    assert first.name == "123-trace.json"
    assert second.name == "123-2-trace.json"
    assert json.loads(first.read_text()) == trace
    assert json.loads(second.read_text()) == trace
