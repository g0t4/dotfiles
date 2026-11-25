"""Shell-local profile selection for Clanker's shared LangChain client."""

import os
from dataclasses import dataclass
from pathlib import Path
from tempfile import mkstemp


@dataclass(frozen=True)
class Profile:
    base_url: str
    model: str | None = None
    return_timings: bool = False


DEFAULT_PROFILE = "deepseek"
PROFILES = {
    DEFAULT_PROFILE: Profile("http://ask.lan:8014/v1", return_timings=True),
    "inkling-2-mini": Profile("http://build21:8017/v1", "inkling-2-mini"),
}


def selected_profile(xsh, name=None):
    name = xsh.env.get("CLANKER_PROFILE", DEFAULT_PROFILE) if name is None else name
    if name not in PROFILES:
        raise ValueError(
            f"Unknown Clanker profile {name!r}. Choose from {', '.join(PROFILES)}"
        )
    return name


def preference_path(xsh):
    state = xsh.env.get("XDG_STATE_HOME") or Path.home() / ".local/state"
    return Path(state) / "clanker_mode" / "profile"


def initialize_profile(xsh):
    try:
        saved = preference_path(xsh).read_text(encoding="utf-8").strip()
    except (OSError, UnicodeError):
        return
    if saved in PROFILES:
        xsh.env["CLANKER_PROFILE"] = saved


def switch_profile(xsh, name):
    name = selected_profile(xsh, name)
    path = preference_path(xsh)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = mkstemp(dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write((name + "\n").encode("utf-8"))
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)
    xsh.env["CLANKER_PROFILE"] = name


def get_model(xsh, name=None):
    from ai_shared.models import connect

    name = selected_profile(xsh, name)
    profile = PROFILES[name]
    base_url, model_id = profile.base_url, profile.model
    api_key = "none"
    if name == DEFAULT_PROFILE:
        base_url = xsh.env.get("CLANKER_BASE_URL", base_url)
        model_id = xsh.env.get("CLANKER_MODEL", model_id)
        api_key = xsh.env.get("CLANKER_API_KEY", api_key)
    model = connect(base_url, model_id, api_key, "$CLANKER_MODEL")
    model.stream_usage = True
    if profile.return_timings:
        model.extra_body = {**(model.extra_body or {}), "return_timings": True}
    return model
