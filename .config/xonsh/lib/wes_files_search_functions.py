"""Callable aliases migrated from Fish's files-search-specific config."""

from __future__ import annotations

import subprocess
import sys

from wes_fish_bridge import (
    FishFunctionError,
    UnsupportedFishFunctionError,
    fish_function,
    fish_function_command,
)


STREAMED_FISH_FUNCTIONS = (
    "rgimages",
    "rgimages-global",
)

CAPTURED_FISH_FUNCTIONS = (
    "lua_list_all_requires",
    "lua_strip_require_around",
    "lua_modify_requires_to_all_use_single_quote",
    "lua_requires_with_single_quotes",
    "lua_requires_with_double_quotes",
    "lua_requires_with_no_quotes",
)

FISH_BRIDGE_FUNCTIONS = STREAMED_FISH_FUNCTIONS + CAPTURED_FISH_FUNCTIONS

NATIVE_FUNCTIONS = (
    "_abbr_expand_fdX",
    "delta_rg",
    "fd",
    "rg_grep",
)

UNSUPPORTED_FUNCTIONS = {
    "_abbr_expand_rgu": "requires the active Xonsh command buffer",
    "command_line_after_cursor_is_not_an_option_dash": (
        "requires the active Xonsh command buffer"
    ),
    "md_open": "may change directory from an interactive fzf picker",
    "mdfind_cd_dir": "changes directory from an interactive fzf picker",
}


def fish_alias(function_name):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        return fish_function_command(
            function_name,
            *args,
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
        )

    return invoke


def captured_fish_alias(function_name):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        input_text = stdin.read() if stdin is not None else None
        try:
            output = fish_function(function_name, *args, input_text=input_text)
        except FishFunctionError as error:
            print(error, file=stderr or sys.stderr)
            return 1
        if output:
            print(output, file=stdout or sys.stdout)
        return 0

    return invoke


def unsupported_alias(function_name, reason):
    def invoke(_args, **_):
        raise UnsupportedFishFunctionError(
            f"{function_name}: TODO SKIPPED_MIGRATION: {reason}"
        )

    return invoke


def fd_depth_alias(args, stdout=None, stderr=None, **_):
    if len(args) != 1 or not args[0].startswith("fd") or not args[0][2:].isdigit():
        print("usage: _abbr_expand_fdX fd<depth>", file=stderr)
        return 2
    print(f"fd --max-depth={args[0][2:]}", file=stdout)
    return 0


def register_files_search_functions(aliases):
    aliases["fd"] = ["fd", "--hidden"]
    aliases["delta_rg"] = ["delta", "--features", "rg"]
    aliases["rg_grep"] = [
        "rg",
        # force color for now, ideally would use smth like spec.last_in_pipeline
        # that said, part of me likes keeping color from grep matches in subsequent pipeline stages... hrmmm
        "--color",
        "always",
        "--no-config",
        "--no-heading",
        "--hidden",
        "--smart-case",
        "--no-filename",
        "--no-line-number",
        "--no-column",
    ]
    # TODO is this an ok spot to add new functions too?
    aliases["grep"] = [
        "grep",
        # fish itself overrides grep with a function to add color auto
        # so, replicating that here:
        "--color=auto",
    ]
    # PRN override ripgrep to add color by default too? i.e. RIPGREP_CONFIG_PATH
    for function_name in STREAMED_FISH_FUNCTIONS:
        aliases[function_name] = fish_alias(function_name)
    for function_name in CAPTURED_FISH_FUNCTIONS:
        aliases[function_name] = captured_fish_alias(function_name)

    aliases["_abbr_expand_fdX"] = fd_depth_alias
    for function_name, reason in UNSUPPORTED_FUNCTIONS.items():
        aliases[function_name] = unsupported_alias(function_name, reason)
