"""Common host and workspace variables shared with Fish."""

import os
import platform
from pathlib import Path


_home = Path(os.path.expanduser("~"))

# these are NOT env vars traditionally, these are xonsh only
#  that is part of the confusion with xonsh, that you cannot differentiate "internal" or xonsh only variables from env vars...
#  these are not used by downstream subprocesses to determine OS, I guess they could be but I don't already so just use boolean values in xonsh
#  that way `if $IS_MACOS:` just works
_is_darwin = platform.system() == "Darwin"
$IS_MACOS = _is_darwin
$IS_LINUX = not _is_darwin
$IS_ARCH = not _is_darwin and Path("/etc/arch-release").is_file()

if not "XDG_STATE_HOME" in @.env:
    $XDG_STATE_HOME = str(_home / ".local/state")
if not "XDG_DATA_HOME" in @.env:
    $XDG_DATA_HOME = str(_home / ".local/share")
if not "XDG_CONFIG_HOME" in @.env:
    $XDG_CONFIG_HOME = str(_home / ".config")
if not "XDG_CACHE_HOME" in @.env:
    $XDG_CACHE_HOME = str(_home / ".cache")

$WES_REPOS = str(_home / "repos")
$WES_BOOTSTRAP = str(Path($WES_REPOS) / "wes-config/wes-bootstrap")
$WES_DOTFILES = str(Path($WES_REPOS) / "github/g0t4/dotfiles")
$WES_ASK_CAPTURES = str(Path($XDG_STATE_HOME) / "nvim/ask-openai")

$VI_MODE = True

# after running `echo foo` you can do `foo<UP_ARROW>` to select it from history instead of only commands that start with `foo` which is the default behavior
# I use this to find commands based on an argument value instead of the command
$XONSH_HISTORY_MATCH_ANYWHERE = True
