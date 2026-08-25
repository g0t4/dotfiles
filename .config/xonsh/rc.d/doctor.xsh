"""Executable checks for terminal assumptions relied on by this config."""

import sys

from wes_terminal_doctor import (
    option_status,
    read_iterm_option_profiles,
    select_iterm_profile,
)


${...}.setdefault("XONSH_ITERM_OPTION_KEY_CHECK", True)


def _iterm_option_profile():
    profiles = read_iterm_option_profiles()
    return select_iterm_profile(profiles, ${...}.get("ITERM_PROFILE"))


def _xonsh_doctor_report():
    """Report executable assumptions made by the Xonsh configuration."""
    if ${...}.get("TERM_PROGRAM") != "iTerm.app":
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


if (
    bool(${...}.get("XONSH_ITERM_OPTION_KEY_CHECK", True))
    and ${...}.get("TERM_PROGRAM") == "iTerm.app"
):
    try:
        _wes_iterm_profile = _iterm_option_profile()
    except (OSError, RuntimeError, ValueError):
        _wes_iterm_profile = None
    if _wes_iterm_profile is not None and not _wes_iterm_profile.left_is_esc_plus:
        print(
            "xonsh: warning: iTerm2 Left Option must send Esc+; run xonsh_doctor",
            file=sys.stderr,
        )
