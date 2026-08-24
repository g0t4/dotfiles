import importlib
import platform
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from generate_misc_abbreviations import (  # noqa: E402
    MODULES,
    SKIPPED_ABBREVIATION_LINES,
    generate_all,
)
from wes_abbreviations import AbbreviationContext, AbbreviationRegistry  # noqa: E402
from wes_fish_bridge import UnsupportedFishFunctionError  # noqa: E402
from wes_misc_functions import (  # noqa: E402
    fish_command_alias,
    unsupported_fish_alias,
)


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
    result = AbbreviationRegistry()
    for module in MODULES:
        generated = importlib.import_module(f"wes_{module.name}_abbreviations")
        register = getattr(generated, f"register_{module.name}_abbreviations")
        register(result)
    return result


def test_generated_misc_modules_are_in_sync_with_fish_source():
    for target, expected in generate_all().items():
        assert target.read_text() == expected


def test_every_misc_fish_abbreviation_is_assigned_to_one_focused_module():
    entries = registry().abbreviations

    assert len(entries) == 833 - len(SKIPPED_ABBREVIATION_LINES)
    for entry in entries:
        if entry.cursor_marker and isinstance(entry.replacement, str):
            assert entry.replacement.count(entry.cursor_marker) == 1, entry.trigger


def test_every_misc_function_definition_is_assigned_to_a_focused_module():
    functions = []
    for module in MODULES:
        generated = importlib.import_module(f"wes_{module.name}_abbreviations")
        functions.extend(generated.FISH_FUNCTIONS)

    assert len(functions) == 109
    assert len(set(functions)) == 107


def test_static_regex_command_scoped_and_cursor_examples():
    abbreviations = registry()

    result, _ = abbreviations.expand(context("scs"))
    assert result.text == "sudo systemctl status"

    result, _ = abbreviations.expand(context("kgr"))
    assert result.text == "kubectl get --raw / | yq -P"
    assert result.cursor == len("kubectl get --raw /")

    assert abbreviations.expand(
        context("-S", command_path=("jq",), command_position=False)
    )
    assert (
        abbreviations.expand(
            context("-S", command_path=("ls",), command_position=False)
        )
        is None
    )

    result, _ = abbreviations.expand(context("man8"))
    assert result.text.endswith(" 8")
    result, _ = abbreviations.expand(context("man9"))
    assert result.text.endswith(" 9")

    result, _ = abbreviations.expand(context("pkill"))
    expected = "pkill -ilf" if platform.system() == "Darwin" else "pkill -if"
    assert result.text == expected

    matches = abbreviations.applicable(context("tail42"))
    assert len(matches) == 1
    assert callable(matches[0].replacement)


def test_safe_function_alias_delegates_to_interactive_fish(monkeypatch):
    calls = []

    def fake_command(name, *args, **kwargs):
        calls.append((name, args, kwargs))
        return 4

    monkeypatch.setattr("wes_misc_functions.fish_function_command", fake_command)
    alias = fish_command_alias("which_versions")

    assert alias(["python"], stdin="in", stdout="out", stderr="err") == 4
    assert calls == [
        (
            "which_versions",
            ("python",),
            {"stdin": "in", "stdout": "out", "stderr": "err"},
        )
    ]


def test_current_shell_function_alias_fails_loudly():
    alias = unsupported_fish_alias("cd2", "changes the current shell directory")

    try:
        alias(["somewhere"])
    except UnsupportedFishFunctionError as error:
        assert "cd2" in str(error)
        assert "native Xonsh migration" in str(error)
    else:
        raise AssertionError("current-shell Fish function unexpectedly ran")


def test_all_split_rc_files_load_together():
    rc_files = [ROOT / ".config/xonsh/rc.d/abbreviations.xsh"]
    rc_files.extend(
        ROOT / f".config/xonsh/rc.d/{name}"
        for name in (
            "cloud-ai.xsh",
            "kubernetes.xsh",
            "media.xsh",
            "misc-specific.xsh",
            "packages-hardware.xsh",
            "processes.xsh",
            "system-services.xsh",
        )
    )
    command = "; ".join(f"source {path}" for path in rc_files)
    command += "; print(len(XONSH_ABBREVIATIONS.abbreviations))"

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.strip() == str(833 - len(SKIPPED_ABBREVIATION_LINES))
