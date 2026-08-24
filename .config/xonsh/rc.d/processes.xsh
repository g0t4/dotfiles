"""Process inspection, search, and tracing abbreviations."""

import platform

from wes_misc_functions import register_misc_fish_functions
from wes_processes_abbreviations import FISH_FUNCTIONS, register_processes_abbreviations


$XONSH_SED_COMMAND = "gsed" if platform.system() == "Darwin" else "sed"
register_processes_abbreviations(XONSH_ABBREVIATIONS)
register_misc_fish_functions(aliases, FISH_FUNCTIONS)


# TODO SKIPPED_MIGRATION: Fish completions for pstree_grep.
# TODO SKIPPED_MIGRATION: build_abbrs_for_filetype dynamically defines sed/rg
# abbreviations from seven file-type mappings.
