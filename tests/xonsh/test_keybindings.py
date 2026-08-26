import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]


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
    )

    assert completed.returncode == 0, completed.stderr
