import importlib.util
from pathlib import Path
import sys

import pytest


ROOT = Path(__file__).parents[2]
MODULE_PATH = ROOT / "tools/xonsh_startup_profile.py"
SPEC = importlib.util.spec_from_file_location("xonsh_startup_profile", MODULE_PATH)
startup_profile = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = startup_profile
SPEC.loader.exec_module(startup_profile)


def test_percentile_interpolates_and_handles_one_value():
    assert startup_profile.percentile([10], 0.95) == 10
    assert startup_profile.percentile([0, 10], 0.5) == 5
    assert startup_profile.percentile([0, 10, 20], 0.95) == pytest.approx(19)


def test_summarize_reports_wall_clock_distribution():
    result = startup_profile.summarize([10, 20, 30, 40, 50])

    assert result.median_ms == 30
    assert result.min_ms == 10
    assert result.p95_ms == pytest.approx(48)
    assert result.runs == 5


def test_xonsh_command_places_options_before_command():
    assert startup_profile.xonsh_command("xonsh", "--no-rc") == [
        "xonsh",
        "--no-rc",
        "-c",
        "exit",
    ]


def test_active_cases_are_centralized_and_exclude_completed_experiments():
    assert set(startup_profile.STARTUP_CASES) == {
        "current",
        "no_rc",
    }
