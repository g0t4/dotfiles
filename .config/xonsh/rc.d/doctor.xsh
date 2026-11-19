"""Executable checks for terminal assumptions relied on by this config."""

from xonsh.built_ins import XSH

aliases = XSH.aliases

import sys

from wes_terminal_doctor import (
    option_status,
    read_iterm_option_profiles,
    select_iterm_profile,
)


def _iterm_option_profile():
    profiles = read_iterm_option_profiles()
    return select_iterm_profile(profiles, @.env.get("ITERM_PROFILE"))


def _xonsh_doctor_report():
    """Report executable assumptions made by the Xonsh configuration."""
    if @.env.get("TERM_PROGRAM") != "iTerm.app":
        print("○ iTerm Option keys: not running under iTerm2")
        return 0
    try:
        profile = _iterm_option_profile()
    except (OSError, RuntimeError, ValueError) as error:
        print(f"✗ iTerm preferences: {error}")
        return 1
    if profile is None:
        print("✗ iTerm profile: could not identify the active profile")
        return 1

    print(f"✓ iTerm profile: {profile.name}")
    left_mark = "✓" if profile.left_is_esc_plus else "✗"
    right_mark = "✓" if profile.right_is_esc_plus else "○"
    print(f"{left_mark} Left Option: {option_status(profile.left)}")
    print(f"{right_mark} Right Option: {option_status(profile.right)}")
    print(f"✓ Prompt Toolkit Vi mode: {bool($VI_MODE)}")
    return 0 if profile.left_is_esc_plus else 1


def _xonsh_doctor_alias(args, stderr=None, **_):
    if args:
        print("usage: xonsh_doctor", file=stderr or sys.stderr)
        return 2
    return _xonsh_doctor_report()


aliases["xonsh_doctor"] = _xonsh_doctor_alias
