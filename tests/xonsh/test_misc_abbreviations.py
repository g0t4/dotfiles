import importlib
import io
import platform
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from fish_to_xonsh_policy import (  # noqa: E402
    AbbreviationSelector,
    declaration,
    matching_rule,
    should_skip,
)
from generate_from_fish import (  # noqa: E402
    MAPPINGS,
    generate_all,
)
from generate_misc_fish_abbreviations import (  # noqa: E402
    TARGET as MISC_FISH_TARGET,
    render as render_misc_fish,
)
from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
from wes_fish_bridge import UnsupportedFishFunctionError  # noqa: E402
from wes_filetype_abbreviations import (  # noqa: E402
    FILETYPE_GLOBS,
    build_abbrs_for_filetype,
)
from wes_fish_migration import (  # noqa: E402
    SKIPPED_FISH_FUNCTIONS,
    fish_command_alias,
    wrap_fish_functions,
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
    registry = reset_registry()
    for mapping in MAPPINGS:
        generated = importlib.import_module(
            f"wes_{mapping.xonsh_module}_abbreviations"
        )
        register = getattr(
            generated, f"register_{mapping.xonsh_module}_abbreviations"
        )
        register()
    importlib.import_module("wes_misc_abbreviations").register_misc_abbreviations()
    return registry


def generated_abbreviation_count():
    fish_abbreviation_count = sum(
        bool(re.match(r"^\s*abbr(?:\s|$)", line))
        for mapping in MAPPINGS
        for line in mapping.source.read_text().splitlines()
    )
    # 12 source declarations are intentionally skipped or deduplicated.
    misc_count = sum(
        line.lstrip().startswith("abbr(")
        for line in (ROOT / ".config/xonsh/lib/wes_misc_abbreviations.py").read_text().splitlines()
    )
    return fish_abbreviation_count - 12 + misc_count


def test_migration_rules_do_not_depend_on_source_line_numbers():
    for name, replacement, options in [
        ("agr", "old %", {"cursor": True}),
        ("agrs", "old %", {"cursor": True}),
        ("man7", "$man_cmd 8", {}),
        ("pkill", "pkill -9 -ilf", {}),
        ("java19", "old", {}),
    ]:
        original = declaration(1, name, replacement, options)
        shifted = declaration(9999, name, replacement, options)
        assert original.split("  # Fish line")[0] == shifted.split("  # Fish line")[0]


def test_trigger_rules_can_distinguish_scopes_and_replacements():
    rules = {"rg": "general", AbbreviationSelector("rg", command="$sed_cmd"): "scoped"}
    assert matching_rule(rules, "rg", "", {"command": "$sed_cmd"}) == "scoped"
    assert matching_rule(rules, "rg", "", {"command": "other"}) == "general"
    assert should_skip("pkill", "pkill -9 -if", {})
    assert not should_skip("pkill", "pkill -9 -ilf", {})
    assert should_skip("*$filetype_letter", "anything", {"command": "rg"})


def test_generated_misc_modules_are_in_sync_with_fish_source():
    for target, expected in generate_all().items():
        assert target.read_text() == expected


def test_every_generated_module_has_a_dedicated_fish_source():
    assert len(MAPPINGS) == 6
    assert len({mapping.source for mapping in MAPPINGS}) == len(MAPPINGS)
    assert all(mapping.source.is_file() for mapping in MAPPINGS)


def test_one_to_one_fish_generator_reproduces_all_modules():
    completed = subprocess.run(
        [sys.executable, str(ROOT / "xonsh/generate_from_fish.py")],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )

    assert completed.returncode == 0, completed.stderr
    for target, expected in generate_all().items():
        assert target.read_text() == expected


def test_misc_fish_abbreviations_are_generated_from_xonsh():
    assert MISC_FISH_TARGET.read_text() == render_misc_fish()
    source = (ROOT / "fish/load_last_interactive_only/misc-specific.fish").read_text()
    assert "source $WES_DOTFILES/fish/generated/misc-abbreviations.fish" in source
    completed = subprocess.run(
        [
            "fish", "--no-config", "-c",
            f"set -g WES_DOTFILES {ROOT}; "
            "function reminder_abbr; abbr $argv; end; "
            "source $WES_DOTFILES/fish/load_last_interactive_only/misc-specific.fish; "
            "abbr --show",
        ],
        capture_output=True,
        text=True,
    )
    assert completed.returncode == 0, completed.stderr
    assert "abbr -a -- rsync_quick 'rsync --archive --delete --progress --stats --dry-run'" in completed.stdout
    assert "abbr -a --position anywhere --command string -- -a --all" in completed.stdout
    assert "abbr -a --set-cursor='%' -- fishc" in completed.stdout
    assert "abbr -a --set-cursor='%' -- strace_process" in completed.stdout
    assert "abbr -a -- cdr 'cd \"$(_repo_root)\"'" in completed.stdout
    assert "abbr -a -- pPATH" in completed.stdout
    assert "abbr -a -- date_unixtime" in completed.stdout
    assert len(completed.stdout.splitlines()) == 64


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
    fish_source = next(
        mapping.source.read_text()
        for mapping in MAPPINGS
        if mapping.xonsh_module == "processes"
    )
    processes_module = next(
        content
        for target, content in generate_all().items()
        if target.name == "wes_processes_abbreviations.py"
    )

    assert 'abbr --add agr --set-cursor "abbr | rg_grep -i \'%\'"' in fish_source
    assert "abbr('agr', \"_abbr_list --any '%'\"" in processes_module
    assert "abbr('agrs', \"_abbr_list --prefix '%'\"" in processes_module


def test_pid_abbreviation_expands_anywhere_without_capturing_a_pid():
    fish_source = next(
        mapping.source.read_text()
        for mapping in MAPPINGS
        if mapping.xonsh_module == "processes"
    )
    assert "abbr --position anywhere --add pid -- '$fish_pid'" in fish_source

    abbreviations = registry()
    for command_position in (True, False):
        result, abbreviation = abbreviations.expand(
            context("pid", command_path=("echo",), command_position=command_position)
        )
        assert result.text == "@(os.getpid())"
        assert abbreviation.position == "anywhere"


def test_every_misc_fish_abbreviation_is_assigned_to_one_focused_module():
    entries = registry().abbreviations

    assert len(entries) == generated_abbreviation_count()
    for entry in entries:
        if entry.cursor_marker and isinstance(entry.replacement, str):
            assert entry.replacement.count(entry.cursor_marker) == 1, entry.trigger


def test_every_misc_function_definition_is_assigned_to_a_focused_module():
    functions = []
    for mapping in MAPPINGS:
        # TODO I probably broke this test when I migrated away from FISH_FUNCTIONS
        generated = importlib.import_module(
            f"wes_{mapping.xonsh_module}_abbreviations"
        )
        functions.extend(generated.FISH_FUNCTIONS)
    functions.extend(importlib.import_module("wes_misc_abbreviations").FISH_FUNCTIONS)

    assert len(functions) == 107
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
    abbreviations = reset_registry()

    build_abbrs_for_filetype("x", "xsh", sed_command="gsed")

    result, _ = abbreviations.expand(context("sedx"))
    assert result.text == "gsed -Ei 's///g' (@lines rg -g '*.xsh' --files-with-matches '___')"
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
    assert result.text == "(@lines rg -g '*.xsh' --files-with-matches '___')"

    result, _ = abbreviations.expand(context("rgx"))
    assert result.text == "rg -g '*.xsh'"


def test_build_abbrs_for_filetype_preserves_brace_globs():
    abbreviations = reset_registry()

    build_abbrs_for_filetype("j", "{json,js}", sed_command="sed")

    result, _ = abbreviations.expand(context("rgj"))
    assert result.text == "rg -g '*.{json,js}'"


def test_safe_function_alias_delegates_to_interactive_fish(monkeypatch):
    calls = []

    def fake_command(name, *args, **kwargs):
        calls.append((name, args, kwargs))
        return 4

    monkeypatch.setattr("wes_fish_migration.fish_function_command", fake_command)
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
        "for item in wes_abbreviations.XONSH_ABBREVIATIONS.abbreviations))"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )

    assert completed.returncode == 0, completed.stderr
    dynamic_filetype_count = len(FILETYPE_GLOBS) * 4
    help_count = sum(
        name not in SKIPPED_FISH_FUNCTIONS
        for module_name in [
            *(f"wes_{mapping.xonsh_module}_abbreviations" for mapping in MAPPINGS),
            "wes_misc_abbreviations",
        ]
        for name in importlib.import_module(
            module_name
        ).FISH_FUNCTIONS
    )
    assert completed.stdout.strip() == str(
        generated_abbreviation_count() + dynamic_filetype_count + help_count
    )


def test_fish_help_reminder_and_independent_source_views(monkeypatch):
    registry = reset_registry()
    aliases = {}
    wrap_fish_functions(aliases, ["which_versions"])
    result, _ = registry.expand(context("which_versions??"))
    assert result.text == "_fish_help which_versions"
    assert registry.expand(context("??which_versions")) is None
    calls = []
    monkeypatch.setattr(
        "wes_fish_migration.fish_function_command",
        lambda *args, **kwargs: calls.append((args, kwargs)) or 0,
    )
    output = io.StringIO()
    assert aliases["_fish_help"](["which_versions"], stdout=output) == 0
    assert "Xonsh wrapper: which_versions" in output.getvalue()
    assert "def invoke" in output.getvalue()
    assert "Fish implementation: which_versions" in output.getvalue()
    assert calls[0][0] == ("type", "--color=never", "which_versions")
    del aliases["which_versions"]
    assert aliases["_fish_help"](["which_versions"], stdout=output) == 0
    assert "Source unavailable" in output.getvalue()
    assert len(calls) == 2


def test_fish_help_colors_last_pipeline_command_including_redirects(monkeypatch):
    from types import SimpleNamespace

    monkeypatch.setenv("TERM", "xterm-256color")
    monkeypatch.delenv("NO_COLOR", raising=False)
    reset_registry()
    aliases = {}
    wrap_fish_functions(aliases, ["which_versions"])
    calls = []
    monkeypatch.setattr(
        "wes_fish_migration.fish_function_command",
        lambda *args, **kwargs: calls.append(args) or 0,
    )
    for last, redirect, colored in [(True, None, True), (False, None, False), (True, "file", True)]:
        output = io.StringIO()
        aliases["_fish_help"](
            ["which_versions"], stdout=output,
            spec=SimpleNamespace(last_in_pipeline=last, stdout=redirect),
        )
        assert ("\x1b[" in output.getvalue()) == colored
        assert calls[-1][1] == ("--color=always" if colored else "--color=never")
