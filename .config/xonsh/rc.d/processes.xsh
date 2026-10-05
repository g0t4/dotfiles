import platform

from wes_filetype_abbreviations import (
    build_abbrs_for_filetype,
    register_filetype_abbreviations,
)
from wes_processes import register_wes_processes


register_wes_processes()
register_filetype_abbreviations()


def _build_abbrs_for_filetype_alias(args, **_):
    if len(args) != 2:
        raise ValueError("usage: build_abbrs_for_filetype LETTER GLOB_END")
    build_abbrs_for_filetype(
        args[0],
        args[1],
    )


aliases["build_abbrs_for_filetype"] = _build_abbrs_for_filetype_alias


# TODO SKIPPED_MIGRATION: Fish completions for pstree_grep.
