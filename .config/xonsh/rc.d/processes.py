import platform

from wes_filetype_abbreviations import register_filetype_abbreviations
from wes_processes import register_wes_processes

register_wes_processes()
register_filetype_abbreviations()

# TODO SKIPPED_MIGRATION: Fish completions for pstree_grep.
