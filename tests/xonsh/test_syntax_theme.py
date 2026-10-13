from test_setup import ROOT

import os
from pathlib import Path
import re
import subprocess
import sys

from wes_interactive_cat import InteractiveCat
from wes_syntax_theme import ThemeBat, syntax_theme
from pygments.token import Keyword

WRAPPER = ROOT / "tools/syntax-lab/bat.py"


def run_bat(*args, input=None, env=None):
    return subprocess.run([sys.executable, str(WRAPPER), *args], input=input, capture_output=True, text=True, env=env)


def test_python_and_lua_use_palette_without_bold_or_background():
    for language, source in (("py", 'def greet():\n    return "hello\\n"\n'), ("lua", 'local function greet() return "hello\\n" end\n')):
        result = run_bat("-pl", language, "--color=always", input=source)
        assert result.returncode == 0, result.stderr
        assert "38;2;179;148;227" in result.stdout  # accepted purple keywords
        assert "38;2;217;189;131" in result.stdout  # amber escapes
        assert re.sub(r"\x1b\[[0-9;]*m", "", result.stdout) == source
        assert not re.search(r"\x1b\[(?:1m|1;|48;)", result.stdout)


def test_redirected_file_and_no_color_stay_plain(tmp_path):
    path = tmp_path / "sample.py"
    source = 'print("hello")\n'
    path.write_text(source)
    assert run_bat(str(path)).stdout == source
    assert run_bat("-lpy", input=source, env={**os.environ, "NO_COLOR": "1"}).stdout == source


def test_fallback_preserves_arguments_input_and_exit_status(tmp_path):
    stock = tmp_path / "bat"
    stock.write_text(f"#!{sys.executable}\nimport sys\nprint(repr(sys.argv[1:]))\nprint(sys.stdin.read(), end='')\nsys.exit(7)\n")
    stock.chmod(0o755)
    env = {**os.environ, "PATH": str(tmp_path)}
    for args in (("-l", "json"), ("-l", "python", "--style=full"), ("--help",), ("-l", "lua", "--paging=always")):
        result = run_bat(*args, input="untouched stdin", env=env)
        assert result.returncode == 7
        assert result.stdout == repr(list(args)) + "\nuntouched stdin"


def test_shell_dispatch_uses_theme_and_keeps_explicit_color_override():
    class Env(dict):
        def detype(self):
            return dict(os.environ)

    class Spec:
        last_in_pipeline = True
        captured = "hiddenobject"
        captured_stdout = object()

    calls = []
    def run(argv, **kwargs):
        calls.append(argv)
        return subprocess.CompletedProcess(argv, 0)

    bat = ThemeBat(env=Env(), run=run)
    bat(["--color=never", "sample.py"], spec=Spec())
    assert calls[0][-3:] == ["--color=always", "--color=never", "sample.py"]
    cat = InteractiveCat(env=Env(), bat=bat)
    cat._show_file(Path("sample.lua"), spec=Spec())
    assert calls[1][-3:] == ["--color=always", "--", "sample.lua"]
    assert syntax_theme().get_style_for_token(Keyword).color.triplet == (179, 148, 227)


def test_reload_file_installs_aliases_and_routes_a_real_pipeline():
    rc = ROOT / '.config/xonsh/rc.d/syntax-theme.xsh'
    command = f'$XONSH_INTERACTIVE = True; source {rc}; source {rc}; echo \'print("hello")\' | bat -pl py --color=always'
    result = subprocess.run([sys.executable, '-m', 'xonsh', '--no-rc', '-c', command], capture_output=True, text=True, env={**os.environ, 'PYTHONPATH': str(ROOT / '.config/xonsh/lib')})
    assert result.returncode == 0, result.stderr
    assert '\x1b[38;2;' in result.stdout
