"""Shared adapter for dynamic abbreviations migrated from Fish's misc file."""

from __future__ import annotations

import platform

from wes_fish_bridge import UnsupportedFishFunctionError, fish_function
from wes_misc_functions import UNSUPPORTED_FISH_FUNCTIONS


def fish_abbreviation(function_name):
    def expand(context, _match):
        reason = UNSUPPORTED_FISH_FUNCTIONS.get(function_name)
        if reason:
            raise UnsupportedFishFunctionError(
                f"Fish abbreviation function {function_name!r} requires a native "
                f"Xonsh migration: {reason}"
            )
        return fish_function(function_name, context.token)

    return expand


def unsupported_abbreviation(name, reason):
    def expand(_context, _match):
        raise UnsupportedFishFunctionError(
            f"Fish abbreviation {name!r} requires a native Xonsh migration: "
            f"{reason}"
        )

    return expand


def platform_abbreviation(darwin, other):
    return darwin if platform.system() == "Darwin" else other
