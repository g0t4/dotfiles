import asyncio
import os
import re

from textual.widgets import Input, Static

from tools.pstree_grep.cli import ProcessInfo
from tools.pstree_grep.tui import ProcessTreeApp, render_tree


def fixture_snapshot():
    procs = {
        100: ProcessInfo(100, 1, "parent", "parent --codex"),
        101: ProcessInfo(101, 100, "codex", "codex server"),
        102: ProcessInfo(102, 101, "worker", "worker"),
        200: ProcessInfo(200, 1, "unrelated", "unrelated"),
    }
    return procs, {1: [100, 200], 100: [101], 101: [102]}


def test_tree_preserves_descendants_and_deduplicates_matches():
    output, matches, roots = render_tree(*fixture_snapshot(), re.compile("codex"))
    assert (matches, roots) == (2, 1)
    assert output.plain == "parent(100)*\n   └─ codex(101)*\n      └─ worker(102)\n"
    assert "unrelated" not in output.plain


def test_self_and_full_command_ascii():
    pid = os.getpid()
    procs = {pid: ProcessInfo(pid, 1, "Python", "python pstree_grep.py codex")}
    output, _, _ = render_tree(
        procs, {}, re.compile("codex"), full_cmd=True, ascii=True
    )
    assert "python pstree_grep.py codex" in output.plain
    assert "[self: pstree_grep]" in output.plain


def test_live_interaction():
    async def check():
        state = [fixture_snapshot()]
        app = ProcessTreeApp("codex", snapshot=lambda: state[0], refresh_interval=0.05)
        async with app.run_test(size=(90, 20)) as pilot:
            await pilot.pause()
            field = app.query_one(Input)
            tree = app.query_one("#tree", Static)
            assert app.focused is field
            assert "worker(102)" in tree.content.plain
            # Literal q/f/i stay editable text, rather than invoking browser actions.
            field.value = ""
            await pilot.press("q", "f", "i")
            await pilot.pause()
            assert field.value == "qfi"
            assert not app.full_cmd
            await pilot.press("ctrl+l")
            assert app.full_cmd and app.focused is field
            await pilot.press("ctrl+l")
            field.value = "codex"
            await pilot.pause()
            field.value = "["
            await pilot.pause()
            assert app.regex_error
            assert "worker(102)" in tree.content.plain
            field.value = "CODEX"
            await pilot.pause()
            assert "No matches" in tree.content.plain
            await pilot.press("escape", "i", "f")
            await pilot.pause()
            assert app.ignore_case and app.full_cmd
            assert "parent --codex" in tree.content.plain
            # Refresh observes processes disappearing and appearing.
            state[0] = ({300: ProcessInfo(300, 1, "new", "codex new")}, {})
            await pilot.pause(0.15)
            assert "codex new" in tree.content.plain
            assert "worker" not in tree.content.plain
            await pilot.press("/")
            assert app.focused is field
            await pilot.press("f9")
        assert not app.is_running

    asyncio.run(check())


def test_refresh_preserves_scroll():
    async def check():
        procs = {
            pid: ProcessInfo(pid, 1, "worker", "worker") for pid in range(100, 180)
        }
        app = ProcessTreeApp(
            "worker", snapshot=lambda: (procs, {}), refresh_interval=60
        )
        async with app.run_test(size=(80, 15)) as pilot:
            await pilot.pause()
            await pilot.press("pagedown")
            await pilot.pause()
            viewport = app.query_one("#viewport")
            offset = viewport.scroll_y
            assert offset > 0
            await app.sample()
            await pilot.pause()
            assert viewport.scroll_y == offset
            await pilot.press("f9")

    asyncio.run(check())
