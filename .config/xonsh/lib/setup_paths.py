from pathlib import Path
import sys

# add libraries to system path
XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))
# sys.path.insert(0, str(ROOT / "xonsh"))

ROOT = Path(__file__).parents[2]

