import json
from pathlib import Path
import subprocess
import sys

import test_setup  # noqa: F401  # load first
from wes_xompletions import (  # noqa: E402
    XompletionManager,
    discover_xompletion_files,
    load_xompletions,
    source_roots_for_venv,
)


RC_DIR = Path(__file__).parents[2] / ".config/xonsh/rc.d"
LIB = RC_DIR.parent / "lib"
AUTO_VENV_RC = RC_DIR / "auto-venv-on-cd-specific.xsh"
XOMPLETION_RC = RC_DIR / "auto-venv-xompletions.xsh"


def make_project(root, command, value, *, commands=None):
    package = root / "tools" / command
    completion = package / "xompletions" / "__init__.py"
    completion.parent.mkdir(parents=True)
    (root / "tools" / "__init__.py").write_text("")
    (package / "__init__.py").write_text("")
    (package / "__main__.py").write_text(f"VALUE = {value!r}\n")
    declaration = f"COMMANDS = {commands!r}\n" if commands is not None else ""
    completion.write_text(
        "from ..__main__ import VALUE\n"
        f"{declaration}"
        "def xonsh_complete(ctx):\n"
        "    yield f'{VALUE}:{ctx}'\n"
    )
    return completion


def make_editable_venv(root, source):
    (root / "bin").mkdir(parents=True)
    site_packages = root / "lib" / "python3.14" / "site-packages"
    dist_info = site_packages / "example-0.1.dist-info"
    dist_info.mkdir(parents=True)
    (dist_info / "direct_url.json").write_text(
        json.dumps({"url": source.as_uri(), "dir_info": {"editable": True}})
    )
    return root


def run_xonsh(command, *, cwd):
    return subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        cwd=cwd,
    )


def test_xompletion_rc_loads_after_auto_venv():
    rc_files = sorted(path.name for path in RC_DIR.glob("*.xsh"))

    assert rc_files.index("auto-venv-on-cd-specific.xsh") < rc_files.index(
        "auto-venv-xompletions.xsh"
    )


def test_discovery_finds_nested_tool_completion(tmp_path):
    first = make_project(tmp_path, "cats", "global")
    second = make_project(tmp_path, "flowers", "local")

    assert discover_xompletion_files([tmp_path]) == [
        (tmp_path.resolve(), first.resolve()),
        (tmp_path.resolve(), second.resolve()),
    ]


def test_loader_supports_relative_imports_without_importing_tools(tmp_path):
    make_project(tmp_path, "cats", "native")
    before = set(sys.modules)

    loaded = load_xompletions([tmp_path])
    try:
        assert list(loaded.completions["cats"]("ctx")) == ["native:ctx"]
        assert "tools" not in set(sys.modules) - before
    finally:
        loaded.unload()

    assert not any(
        name.startswith("_wes_xompletion_") for name in set(sys.modules) - before
    )


def test_declared_commands_override_directory_name(tmp_path):
    make_project(tmp_path, "flowers", "paint", commands=("paint", "paint-preview"))
    loaded = load_xompletions([tmp_path])
    try:
        assert sorted(loaded.completions) == ["paint", "paint-preview"]
    finally:
        loaded.unload()


def test_local_venv_overrides_global_and_unloads_on_exit(tmp_path):
    global_source = tmp_path / "global-source"
    local_source = tmp_path / "local-source"
    make_project(global_source, "cats", "global")
    make_project(local_source, "cats", "local")
    make_project(local_source, "flowers", "local")
    tool_dir = tmp_path / "uv-tools"
    make_editable_venv(tool_dir / "global-tool", global_source)
    local_venv = make_editable_venv(tmp_path / "project" / ".venv", local_source)

    manager = XompletionManager(tool_directory=tool_dir)
    manager.load_global()
    assert list(manager.complete("cats", "ctx")) == ["global:ctx"]

    manager.update_local(local_venv)
    assert list(manager.complete("cats", "ctx")) == ["local:ctx"]
    assert list(manager.complete("flowers", "ctx")) == ["local:ctx"]

    manager.update_local(None)
    assert list(manager.complete("cats", "ctx")) == ["global:ctx"]
    assert manager.complete("flowers", "ctx") is None
    manager.global_scope.unload()


def test_discovery_is_deferred_until_first_completion(tmp_path):
    global_source = tmp_path / "global-source"
    local_source = tmp_path / "local-source"
    make_project(global_source, "cats", "global")
    make_project(local_source, "cats", "local")
    tool_dir = tmp_path / "uv-tools"
    make_editable_venv(tool_dir / "global-tool", global_source)
    local_venv = make_editable_venv(tmp_path / "project" / ".venv", local_source)

    manager = XompletionManager(tool_directory=tool_dir)
    manager.update_local(local_venv)

    assert not manager.global_loaded
    assert not manager.local_loaded
    assert manager.global_scope.completions == {}
    assert manager.local_scope.completions == {}

    assert list(manager.complete("cats", "ctx")) == ["local:ctx"]
    assert manager.global_loaded
    assert manager.local_loaded
    manager.global_scope.unload()
    manager.local_scope.unload()


def test_same_project_can_be_global_and_local(tmp_path):
    source = tmp_path / "source"
    make_project(source, "cats", "shared")
    tool_dir = tmp_path / "uv-tools"
    make_editable_venv(tool_dir / "global-tool", source)
    local_venv = make_editable_venv(tmp_path / "project" / ".venv", source)

    manager = XompletionManager(tool_directory=tool_dir)
    manager.load_global()
    manager.update_local(local_venv)
    local_function = manager.get("cats")

    manager.update_local(None)

    assert manager.get("cats") is not local_function
    assert list(manager.complete("cats", "ctx")) == ["shared:ctx"]
    manager.global_scope.unload()


def test_venv_roots_include_editable_source_and_site_packages(tmp_path):
    source = tmp_path / "source"
    source.mkdir()
    venv = make_editable_venv(tmp_path / ".venv", source)

    roots = source_roots_for_venv(venv)

    assert roots == [
        source.resolve(),
        (venv / "lib/python3.14/site-packages").resolve(),
    ]


def test_real_xonsh_completer_discovers_active_venv_tool(tmp_path):
    project = tmp_path / "project"
    make_project(project, "cats", "kitten")
    make_editable_venv(project / ".venv", project)
    command = (
        "import sys; "
        f"sys.path.insert(0, {str(LIB)!r}); "
        f"source {AUTO_VENV_RC}; "
        f"source {XOMPLETION_RC}; "
        'completer complete "cats "'
    )

    completed = run_xonsh(command, cwd=project)

    assert completed.returncode == 0, completed.stderr
    assert "kitten:" in completed.stdout
    assert "provider='cats'" in completed.stdout
