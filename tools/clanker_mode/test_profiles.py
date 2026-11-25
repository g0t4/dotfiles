import pytest
from langchain_core.messages import AIMessage

import clanker_mode
from clanker_mode import clank, get_session, retry_agent, run_agent
from trace_test_helpers import read_records


class RecordingModel:
    def __init__(self):
        self.inputs = []

    def bind_tools(self, tools):
        return self

    def invoke(self, messages):
        self.inputs.append(messages)
        return AIMessage(content="answer")


def test_retry_reuses_original_input_and_preserves_main_conversation(
    shell, monkeypatch
):
    model = RecordingModel()
    names = []

    def connect(xsh, name):
        names.append(name)
        return model

    monkeypatch.setattr(clanker_mode, "get_model", connect)
    assert clank(["--profile", "deepseek"]) == 0
    assert clank(["first"]) == 0
    assert clank(["second"]) == 0
    session = get_session(shell, clanker_mode.TRACE_DIR)
    original = session.outbound_bodies()
    assert clank(["--retry", "inkling-2-mini"]) == 0
    assert model.inputs[1] == model.inputs[2]
    assert session.outbound_bodies() == original
    assert names == ["deepseek", "deepseek", "inkling-2-mini"]
    assert shell.env["CLANKER_PROFILE"] == "deepseek"
    (branch,) = set(session.path.parent.glob("*.jsonl")) - {session.path}
    fork = next(r for r in read_records(branch) if r["type"] == "context_fork")
    assert (fork["source_session"], fork["source_turn"]) == (session.id, 2)
    session.clear()
    with pytest.raises(ValueError, match="No recent turn"):
        retry_agent(shell, session, "deepseek")


def test_profile_switch_retains_history_and_rejects_unknown(shell, monkeypatch):
    model = RecordingModel()
    monkeypatch.setattr(clanker_mode, "get_model", lambda xsh, name: model)
    run_agent("remember this", shell)
    assert clank(["--profile", "inkling-2-mini"]) == 0
    assert clank(["--profile", "unknown"]) == 1
    assert shell.env["CLANKER_PROFILE"] == "inkling-2-mini"
    run_agent("continue", shell)
    assert model.inputs[0] == model.inputs[1][:-2]


def test_switch_persists_for_new_shells_only(shell, tmp_path):
    from types import SimpleNamespace

    from clanker_profiles import initialize_profile, preference_path, selected_profile

    def start_shell(**env):
        other = SimpleNamespace(env={**shell.env, **env})
        initialize_profile(other)
        return other

    shell.env["XDG_STATE_HOME"] = str(tmp_path)
    earlier = start_shell(CLANKER_PROFILE="deepseek")
    assert clank(["--profile", "inkling-2-mini"]) == 0
    assert selected_profile(shell) == "inkling-2-mini"
    assert selected_profile(earlier) == "deepseek"
    assert selected_profile(start_shell(**earlier.env)) == "inkling-2-mini"

    # A redirected status query in an older shell must leave the saved choice alone.
    shell.env["CLANKER_PROFILE"] = "deepseek"
    assert clank(["--profile"]) == 0
    assert preference_path(shell).read_text().strip() == "inkling-2-mini"
