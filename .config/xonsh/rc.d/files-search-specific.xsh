"""File-search environment shared with Fish."""

from pathlib import Path


_wes_config_dir = Path($XONSH_CONFIG_DIR).resolve().parent
_wes_ripgrep_config = _wes_config_dir / "ripgrep/ripgreprc"
if _wes_ripgrep_config.is_file():
    $RIPGREP_CONFIG_PATH = str(_wes_ripgrep_config)
