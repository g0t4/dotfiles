"""Activate the nearest parent .venv.local or .venv after directory changes."""

import os
import sys
from pathlib import Path


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from wes_auto_venv import AutoVenv


_wes_auto_venv = AutoVenv(${...})


@events.on_chdir
def _wes_auto_venv_on_chdir(olddir, newdir, **_):
    _wes_auto_venv.update(newdir)


# Activate for the directory in which this interactive shell started.
_wes_auto_venv.update(os.getcwd())
