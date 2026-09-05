import re
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from generate_files_abbreviations import TARGET, generate  # noqa: E402
from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
from wes_files_abbreviations import register_files_abbreviations  # noqa: E402


def context(token, *, command_position=True, command_path=()):
    return AbbreviationContext(
        buffer=token,
        cursor=len(token),
        token_start=0,
        token_end=len(token),
        token=token,
        command_position=command_position,
        command_path=command_path,
    )


def registry():
    result = reset_registry()
    register_files_abbreviations()
    return result


def test_generated_module_is_in_sync_with_files_fish_source():
    assert TARGET.read_text() == generate()


def test_inventory_contains_static_regex_scoped_and_cursor_abbreviations():
    entries = registry().abbreviations

    assert len(entries) == 55
    assert any(isinstance(entry.trigger, re.Pattern) for entry in entries)
    assert any(entry.commands == ("dust",) for entry in entries)
    assert sum(entry.cursor_marker is not None for entry in entries) == 2


def test_dot_abbreviations_are_native_and_preserve_anywhere_scope():
    files = registry()

    result, _ = files.expand(context("...."))
    assert result.text == "cd ../../../"

    result, _ = files.expand(context("...", command_position=False))
    assert result.text == "../../"


def test_dust_variable_is_resolved_during_generation():
    result, _ = registry().expand(context("dust_HOME_2G"))

    assert result.text == "dust --number-of-lines 500 ~/ +2G"


def test_command_scoped_dust_abbreviation_only_applies_to_dust():
    files = registry()

    assert files.expand(
        context("-n", command_position=False, command_path=("dust",))
    )
    assert files.expand(
        context("-n", command_position=False, command_path=("ls",))
    ) is None


def test_files_rc_loads_and_cd_to_file_changes_xonsh_directory(tmp_path):
    file = tmp_path / "example.txt"
    file.touch()
    env = os.environ.copy()
    env["XONSH_CONFIG_DIR"] = str(ROOT / ".config/xonsh")
    env["FILES_TEST_DIR"] = str(tmp_path)
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    files_rc = ROOT / ".config/xonsh/rc.d/files-specific.xsh"

    completed = subprocess.run(
        [
            "xonsh",
            "--no-rc",
            "-c",
            (
                f"source {abbreviations}; source {files_rc}; "
                "cd $FILES_TEST_DIR; cd example.txt; print($PWD)"
            ),
        ],
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.strip() == str(tmp_path)
