import plistlib
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_terminal_doctor import (  # noqa: E402
    option_status,
    parse_iterm_option_profiles,
    select_iterm_profile,
)


def payload(*profiles):
    return plistlib.dumps({"New Bookmarks": list(profiles)})


def test_parses_option_encoding_and_selects_active_profile():
    profiles = parse_iterm_option_profiles(
        payload(
            {
                "Name": "Recording 1080p",
                "Option Key Sends": 2,
                "Right Option Key Sends": 0,
            }
        )
    )

    selected = select_iterm_profile(profiles, "Recording 1080p")
    assert selected is not None
    assert selected.left_is_esc_plus
    assert not selected.right_is_esc_plus
    assert option_status(selected.left) == "Esc+"
    assert option_status(selected.right) == "not Esc+ (value=0)"


def test_sole_profile_is_unambiguous_without_an_active_profile_name():
    profiles = parse_iterm_option_profiles(
        payload({"Name": "Only", "Option Key Sends": 2})
    )

    assert select_iterm_profile(profiles, None) == profiles[0]


def test_multiple_profiles_require_one_exact_name_match():
    profiles = parse_iterm_option_profiles(
        payload(
            {"Name": "One", "Option Key Sends": 2},
            {"Name": "Two", "Option Key Sends": 0},
        )
    )

    assert select_iterm_profile(profiles, "Two") == profiles[1]
    assert select_iterm_profile(profiles, "Missing") is None
