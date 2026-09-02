import importlib
import platform
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from generate_misc_abbreviations import (  # noqa: E402
    MODULES,
    SKIPPED_ABBREVIATION_LINES,
    SOURCE,
    generate_all,
)
from wes_abbreviations import AbbreviationContext, AbbreviationRegistry  # noqa: E402
from wes_fish_bridge import UnsupportedFishFunctionError  # noqa: E402
from wes_filetype_abbreviations import (  # noqa: E402
    FILETYPE_GLOBS,
    build_abbrs_for_filetype,
)
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


def generated_abbreviation_count():
    fish_abbreviation_count = sum(
        bool(re.match(r"^\s*abbr(?:\s|$)", line))
        for line in SOURCE.read_text().splitlines()
    )
    return fish_abbreviation_count - len(SKIPPED_ABBREVIATION_LINES)


def test_generated_misc_modules_are_in_sync_with_fish_source():
    for target, expected in generate_all().items():
        assert target.read_text() == expected


def test_generated_platform_commands_exist_only_where_used():
    generated = {target.stem: content for target, content in generate_all().items()}

    assert sum('MAN_COMMAND = "gman"' in content for content in generated.values()) == 1
    assert sum('SED_COMMAND = "gsed"' in content for content in generated.values()) == 1
    assert 'MAN_COMMAND = "gman"' in generated["wes_packages_hardware_abbreviations"]
    assert 'SED_COMMAND = "gsed"' in generated["wes_processes_abbreviations"]


def test_generated_pkill_abbreviations_preserve_platform_specific_flags():
    processes_module = next(
        content
        for target, content in generate_all().items()
        if target.name == "wes_processes_abbreviations.py"
    )

    assert "platform_abbreviation('pkill -9 -ilf', 'pkill -9 -if')" in processes_module
    assert (
        "platform_abbreviation('pkill -9 -U $USER -ilf', "
        "'pkill -9 -U $USER -if')"
    ) in processes_module


def test_fish_abbreviation_search_stays_native_while_xonsh_uses_registry():
    fish_source = SOURCE.read_text()
    processes_module = next(
        content
        for target, content in generate_all().items()
        if target.name == "wes_processes_abbreviations.py"
    )

    assert 'abbr --add agr --set-cursor "abbr | rg_grep -i \'%\'"' in fish_source
    assert "abbr(registry, 'agr', \"_abbr_list --any '%'\"" in processes_module
    assert "abbr(registry, 'agrs', \"_abbr_list --prefix '%'\"" in processes_module


def test_every_misc_fish_abbreviation_is_assigned_to_one_focused_module():
    entries = registry().abbreviations

    assert len(entries) == generated_abbreviation_count()
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
    expected = "pkill -9 -ilf" if platform.system() == "Darwin" else "pkill -9 -if"
    assert result.text == expected

    result, _ = abbreviations.expand(context("pkillu"))
    expected = (
        "pkill -9 -U $USER -ilf"
        if platform.system() == "Darwin"
        else "pkill -9 -U $USER -if"
    )
    assert result.text == expected

    result, _ = abbreviations.expand(context("kill9"))
    assert result.text == "kill -9"
    assert abbreviations.expand(context("pkill9")) is None
    assert abbreviations.expand(context("pkill9u")) is None

    matches = abbreviations.applicable(context("tail42"))
    assert len(matches) == 1
    assert callable(matches[0].replacement)


def test_repo_root_command_substitutions_are_not_quoted_for_xonsh():
    abbreviations = registry()

    for trigger, command in (
        ("cdr", "cd"),
        ("orr", "open"),
        ("cr", "code"),
        ("cir", "code-insiders"),
        ("csr", "cursor"),
    ):
        result, _ = abbreviations.expand(context(trigger))
        assert result.text == f"{command} $(_repo_root)"


def test_build_abbrs_for_filetype_registers_dedicated_and_scoped_forms():
    abbreviations = AbbreviationRegistry()

    build_abbrs_for_filetype(abbreviations, "x", "xsh", sed_command="gsed")

    result, _ = abbreviations.expand(context("sedx"))
    assert result.text == "gsed -Ei 's///g' (rg -g '*.xsh' --files-with-matches '___')"
    assert result.cursor == len("gsed -Ei 's/")

    result, _ = abbreviations.expand(
        context("*x", command_path=("rg",), command_position=False)
    )
    assert result.text == "-g '*.xsh'"
    assert (
        abbreviations.expand(
            context("*x", command_path=("fd",), command_position=False)
        )
        is None
    )

    result, _ = abbreviations.expand(
        context("*x", command_path=("gsed",), command_position=False)
    )
    assert result.text == "(rg -g '*.xsh' --files-with-matches '___')"

    result, _ = abbreviations.expand(context("rgx"))
    assert result.text == "rg -g '*.xsh'"


def test_build_abbrs_for_filetype_preserves_brace_globs():
    abbreviations = AbbreviationRegistry()

    build_abbrs_for_filetype(abbreviations, "j", "{json,js}", sed_command="sed")

    result, _ = abbreviations.expand(context("rgj"))
    assert result.text == "rg -g '*.{json,js}'"


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
    command += (
        "; print(sum(not item.internal "
        "for item in XONSH_ABBREVIATIONS.abbreviations))"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )

    assert completed.returncode == 0, completed.stderr
    dynamic_filetype_count = len(FILETYPE_GLOBS) * 4
    assert completed.stdout.strip() == str(
        generated_abbreviation_count() + dynamic_filetype_count
    )
