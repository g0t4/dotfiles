"""File-search environment shared with Fish."""

from pathlib import Path


_wes_ripgrep_config = Path($WES_DOTFILES) / ".config/ripgrep/ripgreprc"
if _wes_ripgrep_config.is_file():
    $RIPGREP_CONFIG_PATH = str(_wes_ripgrep_config)
