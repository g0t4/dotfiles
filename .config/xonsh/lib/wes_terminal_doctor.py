"""Terminal preference checks used by the Xonsh startup doctor."""

from __future__ import annotations

import plistlib
import subprocess
from dataclasses import dataclass


ITERM_ESC_PLUS = 2


@dataclass(frozen=True)
class ItermOptionProfile:
    name: str
    left: int | None
    right: int | None

    @property
    def left_is_esc_plus(self) -> bool:
        return self.left == ITERM_ESC_PLUS

    @property
    def right_is_esc_plus(self) -> bool:
        return self.right == ITERM_ESC_PLUS


def parse_iterm_option_profiles(payload: bytes) -> tuple[ItermOptionProfile, ...]:
    preferences = plistlib.loads(payload)
    return tuple(
        ItermOptionProfile(
            name=str(profile.get("Name", "<unnamed>")),
            left=profile.get("Option Key Sends"),
            right=profile.get("Right Option Key Sends"),
        )
        for profile in preferences.get("New Bookmarks", ())
    )


def read_iterm_option_profiles() -> tuple[ItermOptionProfile, ...]:
    completed = subprocess.run(
        ["/usr/bin/defaults", "export", "com.googlecode.iterm2", "-"],
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        error = completed.stderr.decode(errors="replace").strip()
        raise RuntimeError(error or "could not read iTerm2 preferences")
    return parse_iterm_option_profiles(completed.stdout)


def select_iterm_profile(
    profiles: tuple[ItermOptionProfile, ...], active_name: str | None
) -> ItermOptionProfile | None:
    if active_name:
        matching = [profile for profile in profiles if profile.name == active_name]
        if len(matching) == 1:
            return matching[0]
    if len(profiles) == 1:
        return profiles[0]
    return None


def option_status(value: int | None) -> str:
    return "Esc+" if value == ITERM_ESC_PLUS else f"not Esc+ (value={value!r})"
