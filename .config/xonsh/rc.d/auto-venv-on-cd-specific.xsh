"""Activate the nearest parent .venv.local or .venv after directory changes."""

import os

from xonsh.events import events

from wes_auto_venv import AutoVenv
from wes_logging import ensure_logger_is_setup, get_wes_logger


ensure_logger_is_setup()
log = get_wes_logger("auto_venv.events")
_wes_auto_venv = AutoVenv(@.env)


@events.on_chdir
def _wes_auto_venv_on_chdir(olddir, newdir, **_):
    log.info("on_chdir olddir=%r newdir=%r", olddir, newdir)
    _wes_auto_venv.update(newdir)


# Activate for the directory in which this interactive shell started.
_wes_auto_venv.update(os.getcwd())
