"""Load the nearest .config.xsh on startup and after changing directories."""

import os

from xonsh.built_ins import XSH
from xonsh.events import events

import wes_abbreviations
from wes_local_config import LocalConfigManager


_wes_local_config = LocalConfigManager(
    ctx=XSH.ctx,
    env=XSH.env,
    registry=wes_abbreviations.XONSH_ABBREVIATIONS,
    execx=XSH.builtins.execx,
)


@events.on_chdir
def _wes_local_config_on_chdir(olddir, newdir, **_):
    _wes_local_config.update(newdir)


_wes_local_config.update(os.getcwd())
