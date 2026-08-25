import re
import sys
from pathlib import Path


XONSH_LIB = Path(__file__).parents[2] / ".config/xonsh/lib"
sys.path.insert(0, str(XONSH_LIB))

from wes_logging import configure_logging, get_logger  # noqa: E402
from wes_auto_venv import AutoVenv  # noqa: E402


ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def test_all_components_write_to_one_named_log(tmp_path):
    path = tmp_path / "xonsh.log"
    configure_logging(path, clear_iterm_scrollback=True)

    get_logger("ai_autosuggest").info("request id=%s", 7)
    get_logger("fzf_pickers").info("picker=%s", "files")
    get_logger("test").info("long=%s", "x" * 5_000)

    contents = path.read_text()
    plain = ANSI.sub("", contents)
    assert contents.count("\x1b]1337;ClearScrollback\x07") == 1
    assert "\x1b[" in contents
    assert not re.search(r"\d{4}-\d{2}-\d{2}", plain)
    assert all(line == line.rstrip(" ") for line in plain.splitlines())
    assert len(plain.splitlines()) == 3
    assert "xonsh.ai_autosuggest request id=7" in plain
    assert "xonsh.fzf_pickers picker=files" in plain


def test_reconfiguring_same_log_does_not_duplicate_handlers_or_clear(tmp_path):
    path = tmp_path / "xonsh.log"
    configure_logging(path, clear_iterm_scrollback=True)
    configure_logging(path, clear_iterm_scrollback=True)

    get_logger("test").info("once")

    contents = path.read_text()
    assert contents.count("ClearScrollback") == 1
    assert contents.count("once") == 1


def test_rich_output_can_be_disabled_globally(tmp_path):
    path = tmp_path / "plain.log"
    configure_logging(path, rich_output="false")

    get_logger("test").warning("plain value=%r", {"answer": 42})

    contents = path.read_text()
    assert "\x1b[" not in contents
    assert "WARNING xonsh.test plain value={'answer': 42}" in contents


def test_auto_venv_logs_path_mutations_to_shared_log(tmp_path):
    path = tmp_path / "xonsh.log"
    configure_logging(path)
    project = tmp_path / "project"
    venv_bin = project / ".venv/bin"
    venv_bin.mkdir(parents=True)
    elsewhere = tmp_path / "elsewhere"
    elsewhere.mkdir()
    env = {"PATH": ["/custom/bin", "/usr/bin"]}

    auto_venv = AutoVenv(env)
    auto_venv.update(project)
    auto_venv.update(elsewhere)

    contents = ANSI.sub("", path.read_text())
    assert "xonsh.auto_venv update" in contents
    assert f"activated venv='{project / '.venv'}'" in contents
    assert "deactivated" in contents
    assert "path_removed=" in contents
