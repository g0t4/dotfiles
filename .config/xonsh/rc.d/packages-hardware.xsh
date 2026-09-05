"""Package-manager and hardware-inspection abbreviations."""

import platform
import shutil

from wes_packages_hardware_abbreviations import (
    FISH_FUNCTIONS,
    register_packages_hardware_abbreviations,
)
from wes_misc_functions import register_misc_fish_functions


$WATCH_INTERVAL = 0.5
$WATCH_COMMAND = "viddy" if shutil.which("viddy") else "watch"
$XONSH_MAN_COMMAND = "gman" if platform.system() == "Darwin" else "man"
register_packages_hardware_abbreviations()
register_misc_fish_functions(aliases, FISH_FUNCTIONS)
