"""macOS-only abbreviations."""

import sys
from pathlib import Path


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from wes_macos_abbreviations import register_macos_abbreviations


if $IS_MACOS:
    register_macos_abbreviations()
