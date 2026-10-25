"""Connect shell viewers and Rich source previews to the syntax-lab palette."""
import os
import sys
import importlib.util
from pathlib import Path

from rich.syntax import PygmentsSyntaxTheme

from wes_interactive_cat import InteractiveCat

ROOT = Path(os.getenv("WES_DOTFILES"))
SYNTAX_LAB = ROOT / "tools" / "syntax-lab"
sys.path.insert(0, str(SYNTAX_LAB))


def syntax_theme():
    # Read the palette for each preview so edits apply without restarting Xonsh.
    spec = importlib.util.spec_from_file_location("wes_syntax_lab", SYNTAX_LAB / "highlight.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    _, style = module.load_style(SYNTAX_LAB / "palette.json")
    return PygmentsSyntaxTheme(style)


class ThemeBat(InteractiveCat):
    def __call__(self, args, stdin=None, stdout=None, stderr=None, spec=None, **_):
        python = ROOT / ".venv" / "bin" / "python3"
        command = [str(python), str(SYNTAX_LAB / "bat.py")] if python.exists() else [self._command("uv") or "uv", "run", "--script", str(SYNTAX_LAB / "bat.py")]
        # Xonsh's terminal dispatcher may not itself report isatty(). Explicit
        # user --color options follow this default and retain precedence.
        if self._is_terminal_output(stdout, spec) and "NO_COLOR" not in self._env:
            command.append("--color=always")
        return self._execute([*command, *args], stdin=stdin, stdout=stdout, stderr=stderr).returncode
