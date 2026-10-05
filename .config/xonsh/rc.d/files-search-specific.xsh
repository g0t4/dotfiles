from xonsh.built_ins import XSH

import platform
from pathlib import Path

from wes_files_search_abbreviations import register_files_search_abbreviations
from wes_files_search_functions import register_files_search_functions

register_files_search_abbreviations()
register_files_search_functions(XSH.aliases)

_wes_ripgrep_config = Path($WES_DOTFILES) / ".config/ripgrep/ripgreprc"
if _wes_ripgrep_config.is_file():
    $RIPGREP_CONFIG_PATH = str(_wes_ripgrep_config)
