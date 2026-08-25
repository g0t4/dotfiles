import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
XONSH = shutil.which("xonsh")
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_fzf_pickers import (  # noqa: E402
    FzfMru,
    apply_path_selection,
    ordered_candidates,
    parse_git_ref_token,
)


def test_mru_uses_same_pwd_with_newline_sha1_key_as_fish(tmp_path):
    cwd = tmp_path / "repo"
    expected = hashlib.sha1(f"{cwd}\n".encode()).hexdigest()
    mru = FzfMru(tmp_path / "cache", cap=3)

    assert mru.path("files", cwd).name == expected


def test_mru_keeps_newest_first_deduplicated_and_capped(tmp_path):
    cwd = tmp_path / "repo"
    cwd.mkdir()
    for name in ("one", "two", "three", "four"):
        (cwd / name).touch()
    mru = FzfMru(tmp_path / "cache", cap=3)
    for name in ("one", "two", "three", "one", "four"):
        mru.record("files", name, cwd)

    assert mru.read("files", cwd) == ["four", "one", "three"]


def test_mru_read_drops_paths_that_no_longer_exist(tmp_path):
    cwd = tmp_path / "repo"
    cwd.mkdir()
    (cwd / "alive").touch()
    mru = FzfMru(tmp_path / "cache")
    mru.path("files", cwd).write_text("missing\nalive\n")

    assert mru.read("files", cwd) == ["alive"]


def test_candidates_put_mru_first_then_fresh_without_duplicates():
    assert ordered_candidates(["b", "a"], ["a", "b", "c", "c"]) == [
        "b",
        "a",
        "c",
    ]


def test_git_ref_token_keeps_ref_separate_from_picker_query():
    assert parse_git_ref_token("HEAD:src/thing") == ("HEAD", "src/thing")
    assert parse_git_ref_token("ordinary/path") == (None, "ordinary/path")
    assert parse_git_ref_token(":README") == (None, ":README")


def test_selection_replaces_whole_token_and_shell_quotes_path():
    assert apply_path_selection("cat old-query tail", 4, 13, "new file") == (
        "cat 'new file' tail",
        14,
    )


def test_git_ref_selection_replaces_token_without_shell_quoting_the_colon():
    assert apply_path_selection(
        "git show HEAD:src", 9, 17, "path with spaces", git_ref="HEAD"
    ) == ("git show 'HEAD:path with spaces'", 32)


def test_cancel_leaves_buffer_and_query_untouched():
    assert apply_path_selection("cat partial", 4, 11, None) == ("cat partial", 11)


def test_files_rc_registers_picker_bindings_and_parses_current_token():
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    files_rc = ROOT / ".config/xonsh/rc.d/files-specific.xsh"
    command = (
        f"source {abbreviations}; source {files_rc}; "
        "from prompt_toolkit.buffer import Buffer; "
        "from prompt_toolkit.key_binding import KeyBindings; "
        "bindings = KeyBindings(); "
        "before = len(bindings.bindings); "
        "events.on_ptk_create.fire(bindings=bindings); "
        "from prompt_toolkit.input import ansi_escape_sequences; "
        "from prompt_toolkit.keys import Keys; "
        "assert ansi_escape_sequences.ANSI_SEQUENCES['\\x1b[100;4u'] "
        "== (Keys.Escape, 'D'); "
        "assert ansi_escape_sequences.ANSI_SEQUENCES['\\x1b[102;4u'] "
        "== (Keys.Escape, 'F'); "
        "assert ansi_escape_sequences.ANSI_SEQUENCES['\\x1b[27;4;102~'] "
        "== (Keys.Escape, 'F'); "
        "b = Buffer(); b.text = 'cat partial tail'; b.cursor_position = 11; "
        "assert _files_current_token(b) == ('partial', 4, 11); "
        "picker_keys = [binding.keys for binding in bindings.bindings[before:]]; "
        "assert ('escape', 'D') in picker_keys; "
        "assert ('escape', 'F') in picker_keys; "
        "assert ('escape', 'G') in picker_keys; "
        "assert len(bindings.bindings) - before >= 5"
    )
    completed = subprocess.run(
        [XONSH, "--no-rc", "-c", command], capture_output=True, text=True
    )

    assert completed.returncode == 0, completed.stderr


def test_picker_subprocess_uses_xonsh_path_not_stale_process_path():
    env = os.environ.copy()
    env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
    env["XONSH_CONFIG_DIR"] = str(ROOT / ".config/xonsh")
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    paths = ROOT / ".config/xonsh/rc.d/paths.xsh"
    files_rc = ROOT / ".config/xonsh/rc.d/files-specific.xsh"
    command = (
        f"source {abbreviations}; source {paths}; source {files_rc}; "
        "candidates, error = _files_picker_candidates('files', None, Path.cwd()); "
        "assert error is None; assert candidates is not None; print(len(candidates))"
    )

    completed = subprocess.run(
        [XONSH, "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
        cwd=ROOT,
    )

    assert completed.returncode == 0, completed.stderr
    assert int(completed.stdout) > 0


def test_keypress_debug_tee_forwards_keys_unchanged():
    env = os.environ.copy()
    env["XONSH_LOG"] = os.devnull
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    files_rc = ROOT / ".config/xonsh/rc.d/files-specific.xsh"
    command = (
        f"source {abbreviations}; source {files_rc}; "
        "from types import SimpleNamespace; "
        "from prompt_toolkit.key_binding.key_processor import KeyPress; "
        "calls = []; "
        "kp = SimpleNamespace(feed_multiple=lambda keys, first=False: "
        "calls.append((list(keys), first))); "
        "prompter = SimpleNamespace(app=SimpleNamespace(key_processor=kp)); "
        "_files_install_keypress_tee(prompter); "
        "$XONSH_KEYPRESS_DEBUG = True; "
        "key = KeyPress('x', 'x'); kp.feed_multiple([key], first=True); "
        "assert calls == [([key], True)]"
    )

    completed = subprocess.run(
        [XONSH, "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
