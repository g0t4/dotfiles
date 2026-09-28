from pathlib import Path
import sys

XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))
from wes_fish_bridge import fish_function

class TestFishBridge:
    def test_repo_root(self):
        assert fish_function("_repo_root") == "/Users/wesdemos/repos/github/g0t4/dotfiles"

    def test_abbr_function_gdlcX_with_argument(self):
        assert fish_function("gdlcX", "gdlc2") == "git log --patch HEAD~2..HEAD~1"
