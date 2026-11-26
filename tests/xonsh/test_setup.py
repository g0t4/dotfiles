import os
from pathlib import Path
import sys

REPO_ROOT = Path(os.getenv("WES_DOTFILES"))
XONSH_LIB = REPO_ROOT / ".config" / "xonsh" / "lib"

# Make the runtime modules and the abbreviation generators importable in tests.
sys.path.insert(0, str(REPO_ROOT / "xonsh"))
sys.path.insert(0, str(XONSH_LIB))
