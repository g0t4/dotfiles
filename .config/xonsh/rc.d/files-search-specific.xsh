"""File-search environment shared with Fish."""

import sys
from pathlib import Path


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from wes_files_search_abbreviations import register_files_search_abbreviations
from wes_files_search_functions import register_files_search_functions


register_files_search_abbreviations()
register_files_search_functions(aliases)

_wes_ripgrep_config = Path($WES_DOTFILES) / ".config/ripgrep/ripgreprc"
if _wes_ripgrep_config.is_file():
    $RIPGREP_CONFIG_PATH = str(_wes_ripgrep_config)
