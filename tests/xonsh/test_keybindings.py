import os
import subprocess
from pathlib import Path

import pytest


ROOT = Path(__file__).parents[2]
XONSH_LIB = ROOT / ".config/xonsh/lib"


def _xonsh_test_env():
    return {**os.environ, "PYTHONPATH": str(XONSH_LIB)}


def test_directory_history_navigates_and_branches(monkeypatch):
    monkeypatch.syspath_prepend(str(ROOT / ".config/xonsh/lib"))
    from wes_directory_history import DirectoryHistory

    history = DirectoryHistory()
    current = "/a"

    def cd(path):
        nonlocal current
        old = current
        current = path
        history.record(old, current)

    cd("/b")
    cd("/c")
    assert history.back(current, cd) and current == "/b"
    assert history.back(current, cd) and current == "/a"
    assert history.forward(current, cd) and current == "/b"

    cd("/d")
    assert history.following == []
    assert not history.forward(current, cd)


def test_directory_history_restores_state_when_cd_fails(monkeypatch):
    monkeypatch.syspath_prepend(str(ROOT / ".config/xonsh/lib"))
    from wes_directory_history import DirectoryHistory

    history = DirectoryHistory(previous=["/gone"])

    with pytest.raises(OSError):
        history.back("/here", lambda _path: (_ for _ in ()).throw(OSError()))

    assert history.previous == ["/gone"]
    assert history.following == []


def test_directory_history_is_bounded(monkeypatch):
    monkeypatch.syspath_prepend(str(ROOT / ".config/xonsh/lib"))
    from wes_directory_history import DirectoryHistory

    history = DirectoryHistory(limit=3)
    for number in range(5):
        history.record(f"/{number}", f"/{number + 1}")

    assert history.previous == ["/2", "/3", "/4"]


def test_ctrl_y_invokes_redo():
    keybindings = ROOT / ".config/xonsh/rc.d/keybindings.xsh"
    command = (
        f"source {keybindings}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.keys import Keys; "
        "from types import SimpleNamespace; "
        "bindings = KeyBindings(); "
        "prompter = SimpleNamespace(app=SimpleNamespace(timeoutlen=1)); "
        "events.on_ptk_create.fire(bindings=bindings, prompter=prompter); "
        "redo = next(binding.handler for binding in bindings.bindings "
        "if binding.keys == (Keys.ControlY,)); "
        "buffer = Buffer(); buffer.text = 'before'; buffer.save_to_undo_stack(); "
        "buffer.text = 'after'; buffer.undo(); assert buffer.text == 'before'; "
        "redo(SimpleNamespace(current_buffer=buffer)); assert buffer.text == 'after'"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=_xonsh_test_env(),
    )

    assert completed.returncode == 0, completed.stderr


def test_ctrl_r_invokes_redo_only_in_vi_normal_mode():
    keybindings = ROOT / ".config/xonsh/rc.d/keybindings.xsh"
    command = (
        f"source {keybindings}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.filters import vi_navigation_mode; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.keys import Keys; "
        "from types import SimpleNamespace; "
        "bindings = KeyBindings(); "
        "prompter = SimpleNamespace(app=SimpleNamespace(timeoutlen=1)); "
        "events.on_ptk_create.fire(bindings=bindings, prompter=prompter); "
        "binding = next(binding for binding in bindings.bindings "
        "if binding.keys == (Keys.ControlR,) "
        "and binding.handler.__name__ == '_vim_redo'); "
        "assert binding.filter is vi_navigation_mode; assert binding.eager(); "
        "buffer = Buffer(); buffer.text = 'before'; buffer.save_to_undo_stack(); "
        "buffer.text = 'after'; buffer.undo(); assert buffer.text == 'before'; "
        "binding.handler(SimpleNamespace(current_buffer=buffer)); "
        "assert buffer.text == 'after'"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=_xonsh_test_env(),
    )

    assert completed.returncode == 0, completed.stderr


def test_alt_up_and_down_cycle_every_history_token_reversibly():
    keybindings = ROOT / ".config/xonsh/rc.d/keybindings.xsh"
    command = (
        f"source {keybindings}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.history import InMemoryHistory; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.keys import Keys; "
        "from types import SimpleNamespace; "
        "bindings = KeyBindings(); "
        "prompter = SimpleNamespace(app=SimpleNamespace(timeoutlen=1)); "
        "events.on_ptk_create.fire(bindings=bindings, prompter=prompter); "
        "alt_up = next(binding.handler for binding in bindings.bindings "
        "if binding.keys == (Keys.Escape, Keys.Up)); "
        "alt_down = next(binding.handler for binding in bindings.bindings "
        "if binding.keys == (Keys.Escape, Keys.Down)); "
        "history = InMemoryHistory(); "
        "history.append_string('git add first.txt'); "
        "history.append_string('nvim second.py'); "
        "buffer = Buffer(history=history); buffer.text = 'echo '; "
        "buffer.cursor_position = len(buffer.text); "
        "event = SimpleNamespace(current_buffer=buffer); "
        "alt_up(event); assert buffer.text == 'echo second.py'; "
        "alt_up(event); assert buffer.text == 'echo nvim'; "
        "alt_up(event); assert buffer.text == 'echo first.txt'; "
        "alt_down(event); assert buffer.text == 'echo nvim'; "
        "alt_down(event); assert buffer.text == 'echo second.py'; "
        "alt_down(event); assert buffer.text == 'echo '"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=_xonsh_test_env(),
    )

    assert completed.returncode == 0, completed.stderr


def test_ctrl_w_uses_vim_small_word_boundaries_in_vi_insert_mode():
    keybindings = ROOT / ".config/xonsh/rc.d/keybindings.xsh"
    command = (
        f"source {keybindings}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.clipboard import InMemoryClipboard; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from types import SimpleNamespace; "
        "bindings = KeyBindings(); "
        "prompter = SimpleNamespace(app=SimpleNamespace(timeoutlen=1)); "
        "events.on_ptk_create.fire(bindings=bindings, prompter=prompter); "
        "ctrl_w = next(binding.handler for binding in bindings.bindings "
        "if binding.handler.__name__ == '_backward_kill_small_word'); "
        "buffer = Buffer(); buffer.text = 'foo.bar@example'; "
        "buffer.cursor_position = len(buffer.text); "
        "event = SimpleNamespace(current_buffer=buffer, arg=1, is_repeat=False, "
        "app=SimpleNamespace(clipboard=InMemoryClipboard())); "
        "ctrl_w(event); assert buffer.text == 'foo.bar@'; "
        "ctrl_w(event); assert buffer.text == 'foo.bar'; "
        "ctrl_w(event); assert buffer.text == 'foo.'; "
        "ctrl_w(event); assert buffer.text == 'foo'"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=_xonsh_test_env(),
    )

    assert completed.returncode == 0, completed.stderr


def _surround_command(keybinding_name, keys, before, pos, after):
    keybindings = ROOT / ".config/xonsh/rc.d/keybindings.xsh"
    key_list = ", ".join(f"SimpleNamespace(key={key!r})" for key in keys)
    return (
        f"source {keybindings}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from types import SimpleNamespace; "
        "bindings = KeyBindings(); "
        "prompter = SimpleNamespace(app=SimpleNamespace(timeoutlen=1)); "
        "events.on_ptk_create.fire(bindings=bindings, prompter=prompter); "
        f"handler = next(b.handler for b in bindings.bindings "
        f"if b.handler.__name__ == {keybinding_name!r}); "
        f"buffer = Buffer(); buffer.text = {before!r}; "
        f"buffer.cursor_position = {pos}; "
        f"event = SimpleNamespace(current_buffer=buffer, "
        f"key_sequence=[{key_list}], "
        "app=SimpleNamespace(invalidate=lambda: None)); "
        f"handler(event); assert buffer.text == {after!r}, buffer.text"
    )


def _run_surround_command(command):
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=_xonsh_test_env(),
    )
    assert completed.returncode == 0, completed.stderr


def test_ds_deletes_surround_pair():
    command = _surround_command(
        "_vi_delete_surround",
        ["d", "s", "("],
        "(foo)",
        2,
        "foo",
    )
    _run_surround_command(command)


def test_ds_deletes_paired_surround_using_closing_delimiter():
    command = _surround_command(
        "_vi_delete_surround",
        ["d", "s", ")"],
        "(foo)",
        2,
        "foo",
    )
    _run_surround_command(command)


def test_ds_deletes_innermost_of_nested_pairs():
    command = _surround_command(
        "_vi_delete_surround",
        ["d", "s", "("],
        "(a (b) c)",
        4,
        "(a b c)",
    )
    _run_surround_command(command)


def test_cs_changes_surround_pair():
    command = _surround_command(
        "_vi_change_surround",
        ["c", "s", "(", '"'],
        "(foo)",
        2,
        '"foo"',
    )
    _run_surround_command(command)


def test_yst_wraps_word_under_cursor():
    command = _surround_command(
        "_vi_ys_surround_this",
        ["y", "s", "t", '"'],
        "echo hello",
        6,
        'echo "hello"',
    )
    _run_surround_command(command)


def test_ysiw_wraps_inner_word():
    command = _surround_command(
        "_vi_ys_surround_inner_word",
        ["y", "s", "i", "w", '"'],
        "echo hello",
        6,
        'echo "hello"',
    )
    _run_surround_command(command)


def test_ysiW_wraps_inner_big_word():
    command = _surround_command(
        "_vi_ys_surround_inner_big_word",
        ["y", "s", "i", "W", '"'],
        "foo.bar",
        1,
        '"foo.bar"',
    )
    _run_surround_command(command)


def test_ys_dollar_wraps_to_end_of_buffer():
    command = _surround_command(
        "_vi_ys_surround_to_end",
        ["y", "s", "$", '"'],
        "git add foo",
        8,
        'git add "foo"',
    )
    _run_surround_command(command)
