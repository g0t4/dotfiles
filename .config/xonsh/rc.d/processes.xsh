"""Process inspection, search, and tracing abbreviations."""

import platform

from wes_filetype_abbreviations import (
    build_abbrs_for_filetype,
    register_filetype_abbreviations,
)
from wes_misc_functions import register_misc_fish_functions
from wes_processes_abbreviations import FISH_FUNCTIONS, register_processes_abbreviations


$XONSH_SED_COMMAND = "gsed" if platform.system() == "Darwin" else "sed"
register_processes_abbreviations()
register_filetype_abbreviations(
    sed_command=$XONSH_SED_COMMAND
)
register_misc_fish_functions(aliases, FISH_FUNCTIONS)


def _build_abbrs_for_filetype_alias(args, **_):
    if len(args) != 2:
        raise ValueError("usage: build_abbrs_for_filetype LETTER GLOB_END")
    build_abbrs_for_filetype(
        args[0],
        args[1],
        sed_command=$XONSH_SED_COMMAND,
    )


aliases["build_abbrs_for_filetype"] = _build_abbrs_for_filetype_alias


# TODO SKIPPED_MIGRATION: Fish completions for pstree_grep.
