import os
import re
import subprocess
import sys
from pathlib import Path

import pytest


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from generate_files_search_abbreviations import TARGET, generate  # noqa: E402
from wes_abbreviations import AbbreviationContext, AbbreviationRegistry  # noqa: E402
from wes_fish_bridge import UnsupportedFishFunctionError  # noqa: E402
from wes_files_search_abbreviations import (  # noqa: E402
    register_files_search_abbreviations,
)
from wes_files_search_functions import (  # noqa: E402
    FISH_BRIDGE_FUNCTIONS,
    NATIVE_FUNCTIONS,
    UNSUPPORTED_FUNCTIONS,
    unsupported_alias,
)


def context(text, *, command_path=(), cursor=None):
    cursor = len(text) if cursor is None else cursor
    token = text[:cursor].rsplit(maxsplit=1)[-1]
    return AbbreviationContext(
        buffer=text,
        cursor=cursor,
        token_start=cursor - len(token),
        token_end=cursor,
        token=token,
        command_path=command_path,
        command_position=cursor == len(token),
    )


def registry():
    result = AbbreviationRegistry()
    register_files_search_abbreviations(result)
    return result


def test_generated_files_search_abbreviations_are_in_sync():
    assert TARGET.read_text() == generate()


def test_every_fish_function_has_an_explicit_migration_strategy():
    source = (
        ROOT / "fish/load_last_interactive_only/files-search-specific.fish"
    ).read_text()
    fish_functions = set(
        re.findall(r"^\s*function\s+([^\s]+)", source, re.MULTILINE)
    )
    assigned = (
        set(FISH_BRIDGE_FUNCTIONS)
        | set(NATIVE_FUNCTIONS)
        | set(UNSUPPORTED_FUNCTIONS)
    )

    assert fish_functions == assigned


def test_fd_depth_and_command_scoped_options():
    abbreviations = registry()

    result, _ = abbreviations.expand(context("fd3", command_path=("fd3",)))
    assert result.text == "fd --max-depth=3"

    result, _ = abbreviations.expand(
        context("fd -l", command_path=("fd",))
    )
    assert result.text == "--list-details"
    assert (
        abbreviations.expand(context("ls -l", command_path=("ls",))) is None
    )


def test_rgu_uses_text_after_cursor_to_preserve_option_editing():
    abbreviations = registry()

    result, _ = abbreviations.expand(context("rgu", command_path=("rgu",)))
    assert result.text == 'rg -u ""'
    assert result.cursor == len('rg -u "')

    result, _ = abbreviations.expand(
        context("rgu existing-pattern", command_path=("rgu",), cursor=3)
    )
    assert result.text == "rg -u"

    result, _ = abbreviations.expand(
        context("rgu --glob '*.py'", command_path=("rgu",), cursor=3)
    )
    assert result.text == 'rg -u ""'


def test_history_abbreviations_use_xonsh_commands():
    abbreviations = registry()

    result, _ = abbreviations.expand(context("hm"))
    assert result.text == "history pull"
    result, _ = abbreviations.expand(context("hd"))
    assert result.text == 'history delete ""'
    assert result.cursor == len('history delete "')


def test_unsupported_stateful_function_abbreviation_fails_loudly():
    abbreviations = registry()

    with pytest.raises(UnsupportedFishFunctionError, match="md_open.*changes directory"):
        abbreviations.expand(context("mdo"))


def test_unsupported_stateful_function_alias_fails_loudly():
    alias = unsupported_alias("mdfind_cd_dir", "changes directory")

    with pytest.raises(UnsupportedFishFunctionError, match="mdfind_cd_dir"):
        alias(["repos"])


def test_ripgrep_searches_hidden_config_without_an_inherited_fish_environment():
    env = os.environ.copy()
    env.pop("RIPGREP_CONFIG_PATH", None)
    env["XONSH_CONFIG_DIR"] = str(ROOT / ".config/xonsh")
    config_rc = ROOT / ".config/xonsh/rc.d/00-env.xsh"
    abbreviations_rc = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    rc = ROOT / ".config/xonsh/rc.d/files-search-specific.xsh"

    completed = subprocess.run(
        [
            "xonsh",
            "--no-rc",
            "-c",
            f"source {config_rc}; source {abbreviations_rc}; source {rc}; rg viinsert",
        ],
        capture_output=True,
        text=True,
        env=env,
        cwd=ROOT,
    )

    assert completed.returncode == 0, completed.stderr
    hidden_matches = [
        line
        for line in completed.stdout.splitlines()
        if line.startswith(".config/xonsh/")
    ]
    assert len(hidden_matches) == 6
