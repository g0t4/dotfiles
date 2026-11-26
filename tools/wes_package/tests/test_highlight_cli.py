from pathlib import Path
import re
import subprocess
import sys
from types import SimpleNamespace


ROOT = Path(__file__).parents[1]


def run_highlight(
    *args: str, input: str | None = None
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "tools.highlight", *args],
        cwd=ROOT,
        input=input,
        capture_output=True,
        text=True,
    )


def test_yaml_is_explicitly_highlighted() -> None:
    source = "services:\n  app:\n    image: example:latest\n"

    result = run_highlight("-", "--language", "yaml", "--force-color", input=source)

    assert result.returncode == 0, result.stderr
    assert "\x1b[38;2;" in result.stdout
    assert re.sub(r"\x1b\[[0-9;]*m", "", result.stdout) == source


def test_unknown_language_reports_an_error_without_bat_fallback() -> None:
    result = run_highlight("-", "--language", "definitely-not-a-lexer", input="text\n")

    assert result.returncode == 2
    assert "no lexer for alias" in result.stderr.lower()
    assert "stock bat" not in result.stderr.lower()


def test_language_completion_includes_yaml() -> None:
    from tools.highlight.__main__ import complete_languages

    assert "yaml" in set(complete_languages())


def test_language_completion_filters_the_xonsh_prefix() -> None:
    from tools.highlight.__main__ import complete_languages

    completer = SimpleNamespace(command=SimpleNamespace(prefix="ya"))

    assert list(complete_languages(completer=completer)) == ["yaml"]


def test_markdown_fences_use_shared_lexers(tmp_path) -> None:
    source = (
        "# Example\n\n"
        "```sh title=demo\ngit status\n```\n\n"
        "```python\nreturn 42\n```\n\n"
        "```unknown-language\nunknown body\n```\n"
    )
    path = tmp_path / "example.md"
    path.write_text(source)

    for result in (
        run_highlight(str(path), "--force-color"),
        run_highlight("-", "-l", "md", "--force-color", input=source),
    ):
        assert result.returncode == 0, result.stderr
        assert "38;2;130;176;223mgit" in result.stdout
        assert "38;2;179;148;227mreturn" in result.stdout
        assert re.sub(r"\x1b\[[0-9;]*m", "", result.stdout) == source


def test_markdown_table_padding_is_opt_in_and_skips_fences(tmp_path) -> None:
    table = "| 名 | Note |\n| :---: | ---: |\n| x | a\\|b |\n"
    fenced = "````md\n```\n" + table + "````\n"
    source = table + "\n" + fenced
    path = tmp_path / "table.md"
    path.write_text(source)
    assert run_highlight(str(path)).stdout == source

    result = run_highlight(str(path), "--pad-tables", "--force-color")
    assert result.returncode == 0, result.stderr
    plain = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout)
    assert plain == (
        "│ 名    │ Note │\n├───────┼──────┤\n│ x     │ a\\|b │\n\n" + fenced
    )
    assert path.read_text() == source


def test_padded_tables_wrap_to_explicit_width_on_stdout() -> None:
    from rich.cells import cell_len

    source = "| ID | Note |\n| --- | --- |\n| 1 | cedar oak maple |\n"
    result = run_highlight("-", "-l", "md", "--pad-tables", "--width", "15", input=source)
    assert result.returncode == 0, result.stderr
    assert result.stdout.splitlines() == [
        "│ ID  │ Note  │",
        "├─────┼───────┤",
        "│ 1   │ cedar │",
        "│     │ oak   │",
        "│     │ maple │",
    ]
    assert all(cell_len(line) == 15 for line in result.stdout.splitlines())
    unbounded = run_highlight("-", "-l", "md", "--pad-tables", input=source)
    assert "cedar oak maple" in unbounded.stdout


def test_pad_tables_width_counts_wide_characters_and_indentation() -> None:
    from rich.cells import cell_len
    from wes_syntax.markdown_tables import pad_tables

    source = "  | ID | Note |\r\n  | --- | --- |\r\n  | 1 | 名名名名名 |"
    wrapped = pad_tables(source, max_width=16)

    assert wrapped.count("\r\n") == 2
    assert not wrapped.endswith("\n")
    assert wrapped.count("名") == 5
    assert all(cell_len(line) == 16 for line in wrapped.splitlines())
    assert pad_tables(source, max_width=15) == pad_tables(source)
    assert pad_tables(source, max_width=80) == pad_tables(source)
