from pathlib import Path
import sys

XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))
from wes_fish_bridge import fish_function


def test_fish_bridge_does_not_have_ansi_escape_codes(monkeypatch):
    fish_function("_repo_root")
    assert fish_function("_repo_root") == "/Users/wesdemos/repos/github/g0t4/dotfiles"
