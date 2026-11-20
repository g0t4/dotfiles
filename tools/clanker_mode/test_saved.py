import io

import clanker_mode
from clanker_mode import compact_session, run_agent
from clanker_saved import SavedConversations
from clanker_session import get_session
from test_session import Reply
from trace_test_helpers import message_bodies, read_records


def test_manage_list_and_legacy_list_alias(shell, tmp_path, monkeypatch):
    monkeypatch.setattr(clanker_mode, "TRACE_DIR", tmp_path / "traces")
    monkeypatch.setattr(clanker_mode, "SAVED_DIR", tmp_path / "saved")

    managed = io.StringIO()
    legacy = io.StringIO()
    assert clanker_mode.clank(["manage", "list"], stdout=managed) == 0
    assert clanker_mode.clank(["--list"], stdout=legacy) == 0
    assert managed.getvalue() == legacy.getvalue() == "No saved Clanker conversations.\n"

    errors = io.StringIO()
    assert clanker_mode.clank(["manage", "unknown"], stderr=errors) == 2
    assert "unknown manage command" in errors.getvalue()


def test_save_restore_and_rename_preserve_active_context(shell, tmp_path):
    traces = tmp_path / "traces"
    saved = SavedConversations(tmp_path / "saved")
    run_agent("How do I print in Python?", shell, model=Reply("Use print"), trace_dir=traces)
    session = get_session(shell, traces)

    snapshot = saved.save(session)
    assert snapshot["title"] == "How do I print in Python?"
    path = tmp_path / "saved" / f"{snapshot['conversation_id']}.json"
    assert path.stat().st_mode & 0o777 == 0o600

    renamed = saved.rename(session, "how to print in python")
    assert renamed["conversation_id"] == snapshot["conversation_id"]
    session.clear()
    restored = saved.restore(session, "print in python")
    assert restored["title"] == "how to print in python"

    followup = Reply("continued")
    run_agent("show an example", shell, model=followup, trace_dir=traces)
    assert [message.content for message in followup.inputs[0][-3:]] == [
        "How do I print in Python?",
        "Use print",
        "show an example",
    ]
    assert [message.type for message in followup.inputs[0]] == [
        "system",
        "human",
        "ai",
        "human",
    ]
    records = read_records(session.path)
    assert any(record["type"] == "context_restore" for record in records)


def test_saved_conversations_sort_by_restore_usage(shell, tmp_path):
    traces = tmp_path / "traces"
    saved = SavedConversations(tmp_path / "saved")
    run_agent("rare", shell, model=Reply("one"), trace_dir=traces)
    session = get_session(shell, traces)
    rare = saved.save(session, "rare")
    session.clear()
    run_agent("favorite", shell, model=Reply("two"), trace_dir=traces)
    favorite = saved.save(session, "favorite")

    saved.restore(session, favorite["conversation_id"])
    saved.restore(session, favorite["conversation_id"])
    saved.restore(session, rare["conversation_id"])

    listed = saved.list()
    assert [item["title"] for item in listed] == ["favorite", "rare"]
    assert [item["restore_count"] for item in listed] == [2, 1]


def test_compaction_replaces_input_view_but_retains_original_trace(shell, tmp_path):
    run_agent("large question", shell, model=Reply("large answer"), trace_dir=tmp_path)
    session = get_session(shell, tmp_path)
    before = session.path.read_bytes()

    count, summary = compact_session(
        session, shell, model=Reply("User is investigating Python printing.")
    )

    assert count == 3
    assert summary == "User is investigating Python printing."
    assert session.path.read_bytes().startswith(before)
    assert [message.type for message in session.outbound()] == ["system", "system"]
    assert "Compacted prior conversation" in session.outbound()[-1].content
    records = read_records(session.path)
    assert any(record["type"] == "context_compaction" for record in records)
    assert any(
        body["content"] == "large question" for body in message_bodies(records)
    )
