# I want a wes_paths with a singleton that has dottable properties for various paths
import os
from pathlib import Path
from xonsh.built_ins import XSH

assert XSH.env
# just use os.getenv... STFU xonsh-lsp
XDG_STATE_HOME = Path(os.getenv("XDG_STATE_HOME", "~/.local/state")).expanduser()

# NEVER copy these paths elsewhere, always use this module for latest value as they can change depending on context (i.e. separate worktrees)
home = Path("~").expanduser()
repos = home / "repos"
dotfiles = repos / "github/g0t4/dotfiles"
bootstrap = repos / "wes-config/wes-bootstrap"
dropbox = home / "dropbox"
sync = home / "sync"
ask_captures = XDG_STATE_HOME / "nvim/ask-openai"
