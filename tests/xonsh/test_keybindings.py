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
        "bindings = KeyBindings(); events.on_ptk_create.fire(bindings=bindings); "
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
        "bindings = KeyBindings(); events.on_ptk_create.fire(bindings=bindings); "
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


def test_alt_dot_cycles_previous_command_arguments_in_vi_mode():
    keybindings = ROOT / ".config/xonsh/rc.d/keybindings.xsh"
    command = (
        f"source {keybindings}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.history import InMemoryHistory; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "from prompt_toolkit.keys import Keys; "
        "from types import SimpleNamespace; "
        "bindings = KeyBindings(); events.on_ptk_create.fire(bindings=bindings); "
        "alt_dot = next(binding.handler for binding in bindings.bindings "
        "if binding.keys == (Keys.Escape, '.')); "
        "history = InMemoryHistory(); "
        "history.append_string('git add first.txt'); "
        "history.append_string('nvim second.py'); "
        "buffer = Buffer(history=history); buffer.text = 'echo '; "
        "buffer.cursor_position = len(buffer.text); "
        "event = SimpleNamespace(current_buffer=buffer); "
        "alt_dot(event); assert buffer.text == 'echo second.py'; "
        "alt_dot(event); assert buffer.text == 'echo first.txt'"
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
        "bindings = KeyBindings(); events.on_ptk_create.fire(bindings=bindings); "
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
