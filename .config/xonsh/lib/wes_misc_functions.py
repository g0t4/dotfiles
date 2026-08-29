"""Xonsh callable-alias adapters for functions still implemented by Fish."""

from __future__ import annotations

from wes_fish_bridge import UnsupportedFishFunctionError, fish_function_command


UNSUPPORTED_FISH_FUNCTIONS = {
    "_abbr_ze": "reads and rewrites the current command buffer",
    "_define_devtools_abbrs": "defines abbreviations in the current shell",
    "_expand_watch_last": "reads the current shell history",
    "_k3s_autocomplete": "reads the current command buffer",
    "cd2": "changes the current shell directory",
    "custom-kill-command-word": "rewrites the current command buffer",
    "toggle-git_commit_command": "rewrites the current command buffer",
    "toggle-grc": "rewrites the current command buffer",
    "toggle_show_verbose_prompt": "changes current-shell prompt state",
    "use_nvim_from_source": "changes current-shell environment variables",
}

SKIPPED_FISH_FUNCTIONS = {
    # This is a Fish variable event handler, not a user-facing command.
    "on_change_show_verbose_prompt",
    # z.xsh already provides a state-aware bridge that changes Xonsh's cwd.
    "z",
    # processes.xsh installs the native current-shell implementation.
    "build_abbrs_for_filetype",
    # python-specific.xsh installs a native wrapper that can change Xonsh's cwd.
    "wcl",
}


def fish_command_alias(function_name):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        return fish_function_command(
            function_name,
            *args,
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
        )

    return invoke


def unsupported_fish_alias(function_name, reason):
    def invoke(_args, **_):
        raise UnsupportedFishFunctionError(
            f"Fish function {function_name!r} requires a native Xonsh migration: "
            f"{reason}"
        )

    return invoke


def register_misc_fish_functions(aliases, function_names):
    for function_name in function_names:
        if function_name in SKIPPED_FISH_FUNCTIONS:
            continue
        reason = UNSUPPORTED_FISH_FUNCTIONS.get(function_name)
        aliases[function_name] = (
            unsupported_fish_alias(function_name, reason)
            if reason
            else fish_command_alias(function_name)
        )
