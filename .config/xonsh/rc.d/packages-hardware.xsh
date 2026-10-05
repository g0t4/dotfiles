"""Package-manager and hardware-inspection abbreviations."""

import platform
import shutil

from wes_packages_hardware import (
    register_wes_packages_hardware,
)


$WATCH_INTERVAL = 0.5
$WATCH_COMMAND = "viddy" if shutil.which("viddy") else "watch"
register_wes_packages_hardware()
