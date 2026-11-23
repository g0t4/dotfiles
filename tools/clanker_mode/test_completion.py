import json

from prompt_toolkit.document import Document

from clanker_completion import ClankerReplCompleter, shell_candidates


def write_snapshot(directory, title, restores, updated):
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f"{title.replace(' ', '-')}.json"
    path.write_text(
        json.dumps(
            {
                "version": 1,
                "conversation_id": path.stem,
                "created_at": updated,
                "messages": [{"message": {"role": "user", "content": title}, "metadata": {}}],
                "title": title,
                "restore_count": restores,
                "updated_at": updated,
                "last_restored_at": updated,
            }
        )
    )


def test_shell_completion_has_manage_hierarchy_and_legacy_options(tmp_path):
    root = shell_candidates(["clank", ""], 1, "", tmp_path)
    values = [candidate[0] for candidate in root]
    assert values[0] == "manage"
    assert "--list" in values
    assert "--restore" in values
    assert "--saved" not in values

    manage = shell_candidates(["clank", "manage", "r"], 2, "r", tmp_path)
    assert [candidate[0] for candidate in manage] == ["rename", "restore", "rollback"]


def test_restore_completion_quotes_titles_and_preserves_usage_order(tmp_path):
    write_snapshot(tmp_path, "how to print in python", 4, "2026-01-01")
    write_snapshot(tmp_path, "python packaging", 1, "2026-02-01")

    legacy = shell_candidates(["clank", "--restore", "py"], 2, "py", tmp_path)
    managed = shell_candidates(
        ["clank", "manage", "restore", "py"], 3, "py", tmp_path
    )

    assert legacy == managed
    assert [candidate[1] for candidate in legacy] == [
        "how to print in python",
        "python packaging",
    ]
    assert legacy[0][0] == "'how to print in python'"
    assert legacy[0][2] == "4 restores"


def test_subrepl_completion_is_scoped_to_controls_and_restore_titles(tmp_path):
    write_snapshot(tmp_path, "how to print in python", 2, "2026-01-01")
    completer = ClankerReplCompleter(tmp_path)

    controls = list(completer.get_completions(Document("/li"), None))
    assert [item.text for item in controls] == ["/list"]
    titles = list(
        completer.get_completions(Document("/restore print"), None)
    )
    assert [item.text for item in titles] == ["how to print in python"]
    assert titles[0].start_position == -len("print")
    assert list(completer.get_completions(Document("tell me /list"), None)) == []


def test_delete_completes_selectors_and_restore_titles(tmp_path):
    write_snapshot(tmp_path, "shell notes", 1, "now")
    args = ["clanker", "manage", "delete"]
    assert {item[0] for item in shell_candidates(args, 3, "--", tmp_path)} == {
        "--both", "--saved", "--trace",
    }
    for selector in [[], ["--trace"]]:
        assert shell_candidates(args + selector, 3 + len(selector), "notes", tmp_path)[0][1] == "shell notes"
    complete = ClankerReplCompleter(tmp_path).get_completions
    assert [item.text for item in complete(Document("/delete --both notes"), None)] == ["shell notes"]
