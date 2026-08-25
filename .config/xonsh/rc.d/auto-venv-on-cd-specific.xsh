"""Activate the nearest parent .venv.local or .venv after directory changes."""

import os
import sys
from pathlib import Path


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from wes_auto_venv import AutoVenv
from wes_logging import DEFAULT_LOG_PATH, configure_logging, get_logger


${...}.setdefault("XONSH_LOG", str(DEFAULT_LOG_PATH))
configure_logging(
    str(${...}["XONSH_LOG"]), clear_iterm_scrollback=True
)
_auto_venv_log = get_logger("auto_venv.events")
_wes_auto_venv = AutoVenv(${...})


@events.on_chdir
def _wes_auto_venv_on_chdir(olddir, newdir, **_):
    _auto_venv_log.info("on_chdir olddir=%r newdir=%r", olddir, newdir)
    _wes_auto_venv.update(newdir)


# Activate for the directory in which this interactive shell started.
_wes_auto_venv.update(os.getcwd())
