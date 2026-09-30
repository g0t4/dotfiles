"""Exercise local config loading in a real Xonsh session."""

import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]
LIB = ROOT / ".config/xonsh/lib"
LOADER = ROOT / ".config/xonsh/rc.d/zzzz-local-config.xsh"


def test_loader_runs_after_global_abbreviation_setup():
    rc_files = sorted(LOADER.parent.glob("*.xsh"))
    assert rc_files[-1] == LOADER


def run_xonsh(command, *, cwd=None):
    return subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
        cwd=cwd,
    )


def test_scoped_functions_abbreviations_and_env_follow_nearest_config(tmp_path):
    outer = tmp_path / "outer"
    child = outer / "child"
    other = tmp_path / "other"
    child.mkdir(parents=True)
    other.mkdir()
    (outer / ".config.xsh").write_text(
        "from wes_local_config import local_abbr, local_function, local_env\n"
        "def private_name():\n"
        "    return 'outer'\n"
        "def project_name():\n"
        "    return private_name()\n"
        "local_abbr('project', 'echo outer')\n"
        "local_env('PROJECT_TEST_VALUE', 'outer')\n"
    )
    (other / ".config.xsh").write_text(
        "@local_function\n"
        "def project_name():\n"
        "    return 'other'\n"
        "local_abbr('project', 'echo other')\n"
        "local_env('PROJECT_TEST_VALUE', 'other')\n"
    )
    command = (
        "import sys; "
        f"sys.path.insert(0, {str(LIB)!r}); "
        f"source {LOADER}; "
        "from xonsh.built_ins import XSH; "
        "import wes_abbreviations; "
        "from wes_abbreviations import AbbreviationContext; "
        "registry = wes_abbreviations.XONSH_ABBREVIATIONS; "
        "context = AbbreviationContext('project', 7, 0, 7, 'project', command_position=True); "
        "XSH.ctx['project_name'] = lambda: 'global'; "
        f"cd {outer}; "
        "print(project_name(), 'private_name' in XSH.ctx, 'local_abbr' in XSH.ctx, XSH.env['PROJECT_TEST_VALUE'], registry.expand(context)[0].text); "
        f"cd {child}; "
        "print(project_name(), len(registry.abbreviations)); "
        f"cd {other}; "
        "print(project_name(), XSH.env['PROJECT_TEST_VALUE'], registry.expand(context)[0].text); "
        f"cd {tmp_path}; "
        "print(project_name(), 'private_name' in XSH.ctx, 'PROJECT_TEST_VALUE' in XSH.env, registry.expand(context))"
    )

    completed = run_xonsh(command)

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.splitlines() == [
        "outer True False outer echo outer",
        "outer 1",
        "other other echo other",
        "global False False None",
    ]


def test_failed_config_rolls_back_registered_items(tmp_path):
    project = tmp_path / "project"
    project.mkdir()
    (project / ".config.xsh").write_text(
        "local_abbr('temporary', 'echo temporary')\n"
        "local_env('PROJECT_TEST_VALUE', 'temporary')\n"
        "raise RuntimeError('broken config')\n"
    )
    command = (
        "import sys; "
        f"sys.path.insert(0, {str(LIB)!r}); "
        "from xonsh.built_ins import XSH; "
        "import wes_abbreviations; "
        "from wes_local_config import LocalConfigManager; "
        "manager = LocalConfigManager(ctx=XSH.ctx, env=XSH.env, "
        "registry=wes_abbreviations.XONSH_ABBREVIATIONS, execx=XSH.builtins.execx)\n"
        f"try: manager.update({str(project)!r})\n"
        "except RuntimeError: pass\n"
        "print(manager.active_path, 'PROJECT_TEST_VALUE' in XSH.env, "
        "len(wes_abbreviations.XONSH_ABBREVIATIONS.abbreviations))"
    )

    completed = run_xonsh(command)

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.strip() == "None False 0"


def test_config_loads_in_initial_directory(tmp_path):
    (tmp_path / ".config.xsh").write_text(
        "from wes_local_config import local_function\n"
        "def initial_project():\n"
        "    return 'loaded'\n"
    )
    command = (
        "import sys; "
        f"sys.path.insert(0, {str(LIB)!r}); "
        f"source {LOADER}; "
        "print(initial_project())"
    )

    completed = run_xonsh(command, cwd=tmp_path)

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.strip() == "loaded"
