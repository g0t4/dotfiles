import sys
from pathlib import Path


XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))

from wes_auto_venv import AutoVenv, find_venv  # noqa: E402


RC_DIR = Path(__file__).parents[2] / ".config/xonsh/rc.d"


def test_paths_load_before_auto_venv():
    rc_files = sorted(path.name for path in RC_DIR.glob("*.xsh"))

    assert rc_files.index("00-paths.xsh") < rc_files.index(
        "auto-venv-on-cd-specific.xsh"
    )


def make_venv(directory):
    (directory / "bin").mkdir(parents=True)
    return directory


def test_find_venv_walks_upward_and_prefers_local(tmp_path):
    project = tmp_path / "project"
    child = project / "src" / "package"
    child.mkdir(parents=True)
    make_venv(project / ".venv")
    local = make_venv(project / ".venv.local")

    assert find_venv(child) == local


def test_find_venv_uses_nearest_parent(tmp_path):
    outer = make_venv(tmp_path / ".venv")
    project = tmp_path / "project"
    inner = make_venv(project / ".venv")
    child = project / "src"
    child.mkdir()

    assert find_venv(child) == inner
    assert find_venv(tmp_path) == outer


def test_activate_and_deactivate_restore_original_path(tmp_path):
    project = tmp_path / "project"
    venv = make_venv(project / ".venv")
    project.mkdir(exist_ok=True)
    elsewhere = tmp_path / "elsewhere"
    elsewhere.mkdir()
    original_path = ["/custom/bin", "/usr/bin"]
    env = {"PATH": original_path.copy()}
    auto_venv = AutoVenv(env)

    assert auto_venv.update(project) == venv
    assert env["VIRTUAL_ENV"] == str(venv)
    assert env["PATH"] == [str(venv / "bin"), *original_path]
    assert env["VIRTUAL_ENV_DISABLE_PROMPT"] is True

    assert auto_venv.update(elsewhere) is None
    assert env["PATH"] == original_path
    assert "VIRTUAL_ENV" not in env


def test_switching_venvs_does_not_accumulate_bin_paths(tmp_path):
    first = make_venv(tmp_path / "first" / ".venv")
    second = make_venv(tmp_path / "second" / ".venv")
    env = {"PATH": ["/usr/bin"]}
    auto_venv = AutoVenv(env)

    auto_venv.update(first.parent)
    auto_venv.update(second.parent)

    assert env["PATH"] == [str(second / "bin"), "/usr/bin"]
    assert env["VIRTUAL_ENV"] == str(second)


def test_repeated_update_is_idempotent(tmp_path):
    venv = make_venv(tmp_path / "project" / ".venv")
    env = {"PATH": ["/usr/bin"]}
    auto_venv = AutoVenv(env)

    auto_venv.update(venv.parent)
    auto_venv.update(venv.parent)

    assert env["PATH"] == [str(venv / "bin"), "/usr/bin"]


def test_inherited_venv_is_removed_from_path_before_activation(tmp_path):
    inherited = tmp_path / "inherited"
    project_venv = make_venv(tmp_path / "project" / ".venv")
    env = {
        "PATH": [str(inherited / "bin"), "/usr/bin"],
        "VIRTUAL_ENV": str(inherited),
    }

    AutoVenv(env).update(project_venv.parent)

    assert env["PATH"] == [str(project_venv / "bin"), "/usr/bin"]
    assert env["VIRTUAL_ENV"] == str(project_venv)
