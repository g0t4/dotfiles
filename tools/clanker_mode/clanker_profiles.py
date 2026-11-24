"""Shell-local profile selection for Clanker's shared LangChain client."""

from dataclasses import dataclass


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
