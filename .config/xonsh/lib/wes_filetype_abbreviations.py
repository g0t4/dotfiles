"""Native Xonsh version of Fish's ``build_abbrs_for_filetype`` helper."""

from __future__ import annotations

from wes_abbreviations import abbr


FILETYPE_GLOBS = (
    ("f", "fish"),
    ("j", "{json,js}"),
    ("l", "lua"),
    ("m", "md"),
    ("p", "py"),
    ("t", "ts"),
    ("r", "rs"),
    ("y", "{yaml,yml}"),
    ("x", "xsh"),
)


def build_abbrs_for_filetype(
    filetype_letter: str,
    glob_end: str,
    *,
    sed_command: str,
) -> None:
    """Register the four Fish-style abbreviations for one file type."""
    rg_filter = f"(rg -g '*.{glob_end}' --files-with-matches '___')"

    abbr(
        f"sed{filetype_letter}",
        f"{sed_command} -Ei 's/%//g' {rg_filter}",
        cursor_marker="%",
    )
    abbr(
        f"*{filetype_letter}",
        f"-g '*.{glob_end}'",
        position="anywhere",
        commands=("rg",),
    )
    abbr(
        f"*{filetype_letter}",
        rg_filter,
        position="anywhere",
        commands=(sed_command,),
    )
    abbr(f"rg{filetype_letter}", f"rg -g '*.{glob_end}'")


def register_filetype_abbreviations(
    sed_command: str
) -> None:
    for filetype_letter, glob_end in FILETYPE_GLOBS:
        build_abbrs_for_filetype(
            filetype_letter,
            glob_end,
            sed_command=sed_command,
        )
