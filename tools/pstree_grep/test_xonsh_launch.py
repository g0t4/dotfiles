"""Exercise the real rc-file alias and OS streams, outside Textual's test driver."""

import os
from pathlib import Path
import pty
import select
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]


def xonsh_command(command):
    # This automation environment can have a UID absent from the passwd database.
    # Keep that test-harness limitation out of the actual shell/tool configuration.
    bootstrap = (
        "import xonsh.prompt.base as prompt; "
        "prompt._current_username = lambda: 'pstree-test'; "
        "from xonsh.main import main; "
        f"main(['--no-rc', '-c', {command!r}])"
    )
    return [sys.executable, "-c", bootstrap]


def shell_setup():
    return (
        "import sys\n"
        "sys.path.insert(0, '.config/xonsh/lib')\n"
        "source .config/xonsh/rc.d/python-specific.xsh\n"
    )


def shell_env():
    return {**os.environ, "WES_DOTFILES": str(ROOT), "TERM": "xterm-256color"}


def test_xonsh_alias_inherits_terminal_and_exits_with_f9():
    master, slave = pty.openpty()
    process = subprocess.Popen(
        xonsh_command(shell_setup() + "pstree_grep\n"),
        cwd=ROOT,
        env=shell_env(),
        stdin=slave,
        stdout=slave,
        stderr=slave,
    )
    os.close(slave)
    output = bytearray()
    try:
        deadline = time.monotonic() + 10
        while b"Browse" not in output and time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                try:
                    output.extend(os.read(master, 65536))
                except OSError:
                    break
            if process.poll() is not None:
                break
        assert b"Browse" in output, output.decode(errors="replace")
        assert b"interactive mode requires a terminal" not in output
        os.write(master, b"codex")
        os.write(master, b"\x1b[20~")  # F9
        deadline = time.monotonic() + 5
        while process.poll() is None and time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                try:
                    output.extend(os.read(master, 65536))
                except OSError:
                    break
        assert process.wait(timeout=2) == 0, output.decode(errors="replace")
        assert b"\x1b[?1049l" in output  # alternate screen restored
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        os.close(master)


def test_xonsh_snapshot_keeps_stdout_and_stderr_redirects(tmp_path):
    output = tmp_path / "snapshot.txt"
    errors = tmp_path / "errors.txt"
    command = shell_setup() + (
        f"pstree_grep pstree_grep > {str(output)!r}\n"
        f"pstree_grep '[' 2> {str(errors)!r}\n"
    )
    completed = subprocess.run(
        xonsh_command(command),
        cwd=ROOT,
        env=shell_env(),
        capture_output=True,
        text=True,
        timeout=10,
    )
    assert "[self: pstree_grep]" in output.read_text()
    assert "invalid regex" in errors.read_text()
    assert "# matches:" not in completed.stdout
    assert "invalid regex" not in completed.stderr
