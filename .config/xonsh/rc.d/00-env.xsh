"""Common host and workspace variables shared with Fish."""

import os
import platform
from pathlib import Path


_wes_home = Path(os.path.expanduser("~"))
_wes_is_macos = platform.system() == "Darwin"

# Keep Fish's executable true/false string convention for compatibility with
# tools and snippets shared between shells.
$IS_MACOS = "true" if _wes_is_macos else "false"
$IS_LINUX = "false" if _wes_is_macos else "true"
$IS_ARCH = (
    "true"
    if not _wes_is_macos and Path("/etc/arch-release").is_file()
    else "false"
)

if not ${...}.get("XDG_STATE_HOME"):
    $XDG_STATE_HOME = str(_wes_home / ".local/state")

$WES_REPOS = str(_wes_home / "repos")
$WES_BOOTSTRAP = str(Path($WES_REPOS) / "wes-config/wes-bootstrap")
$WES_DOTFILES = str(Path($WES_REPOS) / "github/g0t4/dotfiles")
$WES_ASK_CAPTURES = str(Path($XDG_STATE_HOME) / "nvim/ask-openai")

$VI_MODE = True

# after running `echo foo` you can do `foo<UP_ARROW>` to select it from history instead of only commands that start with `foo` which is the default behavior
# I use this to find commands based on an argument value instead of the command
$XONSH_HISTORY_MATCH_ANYWHERE = True
