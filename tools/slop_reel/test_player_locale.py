"""Exercise the native Qt/libmpv boundary in an isolated process."""

import os
import subprocess
import sys
from pathlib import Path

import pytest


@pytest.mark.parametrize("numeric_locale", ["en_US.UTF-8", "de_DE.UTF-8"])
def test_player_restores_numeric_locale_after_qt(numeric_locale):
    script = f"""
import locale
from PySide6.QtWidgets import QApplication
from player import Player
app = QApplication([])
locale.setlocale(locale.LC_NUMERIC, {numeric_locale!r})
assert locale.setlocale(locale.LC_NUMERIC) != 'C'
other_categories = {{category: locale.setlocale(category) for category in
                    (locale.LC_CTYPE, locale.LC_TIME, locale.LC_MONETARY)}}
player = Player('unused.mp4')
try:
    assert locale.setlocale(locale.LC_NUMERIC) == 'C'
    assert locale.atof('1.25') == 1.25
    assert all(locale.setlocale(category) == value for category, value in other_categories.items())
finally:
    player.close_player()
"""
    result = subprocess.run(
        [sys.executable, "-c", script],
        cwd=Path(__file__).parent,
        env={**os.environ, "LC_ALL": numeric_locale},
        check=False,
        capture_output=True,
        text=True,
        timeout=20,
    )
    assert result.returncode == 0, result.stderr
    assert "Non-C locale detected" not in result.stderr
