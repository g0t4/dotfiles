from pathlib import Path
import sys

ROOT = Path(__file__).parents[2]
XONSH_LIB = ROOT / ".config" / "xonsh" / "lib"

# Make the runtime modules and the abbreviation generators importable in tests.
sys.path.insert(0, str(ROOT / "xonsh"))
sys.path.insert(0, str(XONSH_LIB))
