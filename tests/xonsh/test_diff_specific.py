import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_diff import (  # noqa: E402
    ProcessSubstitutionFiles,
    command_output_files,
    copied_patch_sides,
    diff_expansion,
    last_commands,
    sanitize_icdiff_label,
)


def test_command_outputs_exist_for_the_duration_and_are_removed_afterward():
    paths = []

    def write(command, path):
        path.write_text(f"output from {command}\n")

    with command_output_files(("first", "second"), write) as current_paths:
        paths = list(current_paths)
        assert [path.read_text() for path in paths] == [
            "output from first\n",
            "output from second\n",
        ]

    assert all(not path.exists() for path in paths)


def test_command_output_files_cleans_up_when_execution_fails():
    paths = []

    def fail(_command, path):
        paths.append(path)
        raise RuntimeError("boom")

    try:
        with command_output_files(("first",), fail):
            pass
    except RuntimeError:
        pass

    assert paths and all(not path.exists() for path in paths)


def test_last_commands_ignores_blank_entries_and_preserves_oldest_first():
    assert last_commands(["old", "", "new", "   "], count=2) == ("old", "new")


def test_diff_expansions_quote_each_whole_command():
    history = ["echo 'old value'", "printf '%s\\n' new"]

    assert diff_expansion(history) == (
        "diff_two_commands 'echo '\"'\"'old value'\"'\"'' "
        "'printf '\"'\"'%s\\n'\"'\"' new'"
    )
    assert diff_expansion(history, suffix=" | sort -h").endswith(
        "'printf '\"'\"'%s\\n'\"'\"' new | sort -h'"
    )


def test_diff_expansion_requires_two_commands():
    assert diff_expansion(["only one"]) is None


def test_icdiff_labels_do_not_interpolate_braces():
    assert sanitize_icdiff_label("awk '{print $1}'") == "awk '_print $1_'"


def test_pipeline_process_substitution_lives_until_postcommand_cleanup(tmp_path):
    substitutions = ProcessSubstitutionFiles()
    source = (tmp_path / "source").open("wb+")
    source.write(b"hello from stdin\n")
    source.seek(0)

    path = substitutions.from_stream(source)
    assert path.read_bytes() == b"hello from stdin\n"

    substitutions.cleanup()
    assert not path.exists()
    assert substitutions.paths == []


def test_copied_patch_sides_preserve_context_for_visual_diffing():
    patch = " context\n-old\n+new\n more context\n"
    assert copied_patch_sides(patch) == (
        " context\n+new\n more context\n",
        " context\n-old\n more context\n",
    )
