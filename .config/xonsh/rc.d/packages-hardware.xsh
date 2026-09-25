"""Package-manager and hardware-inspection abbreviations."""

import platform
import shutil

from wes_packages_hardware_abbreviations import (
    register_wes_packages_hardware_abbreviations,
)


$WATCH_INTERVAL = 0.5
$WATCH_COMMAND = "viddy" if shutil.which("viddy") else "watch"
$XONSH_MAN_COMMAND = "gman" if platform.system() == "Darwin" else "man"
register_wes_packages_hardware_abbreviations()
