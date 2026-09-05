import importlib
import platform
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from generate_python_abbreviations import SOURCE, TARGET, generate  # noqa: E402
from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
from wes_python_functions import run_wcl, wcl_completion_candidates  # noqa: E402


def context(token, *, command_path=(), command_position=True):
    return AbbreviationContext(
        buffer=token,
        cursor=len(token),
        token_start=0,
        token_end=len(token),
        token=token,
        command_path=command_path,
        command_position=command_position,
    )


def registry():
    generated = importlib.import_module("wes_python_abbreviations")
    result = reset_registry()
    generated.register_python_abbreviations()
    return result


def test_generated_module_is_in_sync_with_fish_source():
    assert TARGET.read_text() == generate()


def test_every_fish_abbreviation_is_generated_with_duplicate_triggers_replaced():
    source_names = []
    for line_number, line in enumerate(SOURCE.read_text().splitlines(), 1):
        if re.match(r"^\s*abbr(?:\s|$)", line):
            from generate_misc_abbreviations import parse_abbreviation

            source_names.append(parse_abbreviation(line_number, line)[1])

    entries = registry().abbreviations
    assert len(entries) == len(set(source_names))
    assert len([entry for entry in entries if entry.trigger == "uvt"]) == 1
    result, _ = registry().expand(context("uvt"))
    assert result.text == "uv tool"


def test_python_uv_and_pytest_abbreviations():
    abbreviations = registry()

    expected = {
        "py": "ipython3",
        "pyt": "python3",
        "vea": "source .venv*/bin/activate.xsh",
        "uva_common": "uv add ipython ipykernel yapf rope rich httpx pytest pytest-watch",
        "uv_pip_install_upgrade": "uv pip install --upgrade $(uv pip list --outdated | tail +3 | cut -d' ' -f1)",
    }
    for trigger, expansion in expected.items():
        result, _ = abbreviations.expand(context(trigger))
        assert result.text == expansion

    result, _ = abbreviations.expand(
        context("-s", command_path=("pytest",), command_position=False)
    )
    assert result.text == "--capture=no"
    assert abbreviations.expand(
        context("-s", command_path=("python",), command_position=False)
    ) is None


def test_py_kill_preserves_platform_specific_flags():
    result, _ = registry().expand(context("py_kill"))
    expected_flag = "-ilf" if platform.system() == "Darwin" else "-if"
    assert result.text == f'pkill {expected_flag} "python.*3.13.5"'
    generated = generate()
    assert "'pkill -ilf \"python.*3.13.5\"'" in generated
    assert "'pkill -if \"python.*3.13.5\"'" in generated


def test_function_inventory_and_dynamic_ptw_expansion():
    generated = importlib.import_module("wes_python_abbreviations")
    assert len(generated.FISH_FUNCTIONS) == 14
    assert "uv_add" in generated.FISH_FUNCTIONS
    assert "apply_patch_multi" in generated.FISH_FUNCTIONS

    matching = registry().applicable(context("ptw_one"))
    assert len(matching) == 1
    assert callable(matching[0].replacement)
    assert matching[0].cursor_marker == "%"


def test_python_rc_loads_with_native_wcl():
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    python_rc = ROOT / ".config/xonsh/rc.d/python-specific.xsh"
    command = (
        f"source {abbreviations}; source {python_rc}; "
        "assert $PYTEST_ADDOPTS == '-o verbosity_assertions=2'; "
        "assert callable(aliases['wcl']); "
        "print(len(wes_abbreviations.XONSH_ABBREVIATIONS.abbreviations))"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )

    assert completed.returncode == 0, completed.stderr


def test_run_wcl_changes_xonsh_directory_from_stderr_protocol(tmp_path, monkeypatch):
    destination = tmp_path / "github/g0t4/example"
    destination.mkdir(parents=True)
    calls = []

    def fake_run(*_args, **_kwargs):
        return subprocess.CompletedProcess(
            [], 0, stderr=f"ordinary warning\n__wcl_cd {destination}\n"
        )

    def fake_cd(args):
        calls.append(args)
        return None, None, 0

    monkeypatch.setattr(subprocess, "run", fake_run)
    stderr = __import__("io").StringIO()

    result = run_wcl(
        ["--cd", "example"],
        script=Path("wcl.py"),
        python=Path("python3"),
        cd=fake_cd,
        stderr=stderr,
    )

    assert result == 0
    assert calls == [[str(destination)]]
    assert stderr.getvalue() == "ordinary warning\n"


def test_run_wcl_does_not_change_directory_after_failure(tmp_path, monkeypatch):
    destination = tmp_path / "example"
    destination.mkdir()
    monkeypatch.setattr(
        subprocess,
        "run",
        lambda *_args, **_kwargs: subprocess.CompletedProcess(
            [], 2, stderr=f"__wcl_cd {destination}\n"
        ),
    )

    calls = []
    result = run_wcl(
        ["--cd", "example"],
        script=Path("wcl.py"),
        python=Path("python3"),
        cd=lambda args: calls.append(args),
    )

    assert result == 2
    assert calls == []


def test_wcl_completion_candidates_select_options_or_repositories():
    repositories = ["dotfiles", "docker", "ask-openai.nvim"]

    assert wcl_completion_candidates("do", repositories) == ["dotfiles", "docker"]
    assert wcl_completion_candidates("--d", repositories) == ["--dry-run"]
