from pathlib import Path
import sys


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_ai_autosuggest_state import (  # noqa: E402
    autosuggest_state_path,
    read_autosuggest_enabled,
    write_autosuggest_enabled,
)


def test_missing_state_defaults_to_enabled(tmp_path):
    env = {"XONSH_AI_AUTOSUGGEST_STATE": tmp_path / "missing"}

    assert read_autosuggest_enabled(env) is True


def test_state_round_trips_atomically(tmp_path):
    path = tmp_path / "nested/state"
    env = {"XONSH_AI_AUTOSUGGEST_STATE": path}

    write_autosuggest_enabled(env, False)
    assert read_autosuggest_enabled(env) is False
    write_autosuggest_enabled(env, True)

    assert read_autosuggest_enabled(env) is True
    assert path.read_text() == "on\n"


def test_default_state_path_honors_xdg_state_home(tmp_path):
    assert autosuggest_state_path({"XDG_STATE_HOME": tmp_path}) == (
        tmp_path / "xonsh/ai-autosuggest"
    )
