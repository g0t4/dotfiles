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
