"""Shell-local profile selection for Clanker's shared LangChain client."""

import math
import os
from dataclasses import dataclass, replace
from pathlib import Path
from tempfile import mkstemp


@dataclass(frozen=True, kw_only=True)
class Profile:
    name: str
    base_url: str
    model: str | None = None
    api_key_env: str | None = None
    return_timings: bool = False
    effort_levels: tuple[str, ...] = ()
    numeric_effort_range: tuple[float, float] | None = None
    reasoning_effort: str | float | None = None
    temperature: float | None = None
    max_output_tokens: int | None = None
    request_timeout: float = 120
    max_rounds: int = 50

    def __post_init__(self):
        effort = self.reasoning_effort
        if isinstance(effort, str):
            if effort not in self.effort_levels:
                raise ValueError(
                    f"{self.name} reasoning_effort choices: {self.effort_levels}"
                )
        elif effort is not None:
            bounds = self.numeric_effort_range
            if (
                not bounds
                or type(effort) not in (int, float)
                or not bounds[0] <= effort <= bounds[1]
            ):
                raise ValueError(
                    f"{self.name} does not support numeric reasoning_effort {effort!r}"
                )
        if self.temperature is not None and (
            type(self.temperature) not in (int, float) or not 0 <= self.temperature <= 2
        ):
            raise ValueError("temperature must be between 0 and 2")
        if (
            type(self.request_timeout) not in (int, float)
            or not math.isfinite(self.request_timeout)
            or self.request_timeout <= 0
        ):
            raise ValueError("request_timeout must be positive and finite")
        if self.max_output_tokens is not None and (
            type(self.max_output_tokens) is not int or self.max_output_tokens < 1
        ):
            raise ValueError("max_output_tokens must be a positive integer")
        if type(self.max_rounds) is not int or self.max_rounds < 1:
            raise ValueError("max_rounds must be a positive integer")

    def client_options(self):
        options = {"timeout": self.request_timeout, "stream_usage": True}
        extra = {}
        if self.return_timings:
            extra["return_timings"] = True
        if isinstance(self.reasoning_effort, str):
            options["reasoning_effort"] = self.reasoning_effort
        elif self.reasoning_effort is not None:
            extra["chat_template_kwargs"] = {"reasoning_effort": self.reasoning_effort}
        if extra:
            options["extra_body"] = extra
        if self.temperature is not None:
            options["temperature"] = self.temperature
        if self.max_output_tokens is not None:
            options["max_tokens"] = self.max_output_tokens
        return options


DEEPSEEK = Profile(
    name="deepseek",
    base_url="http://ask.lan:8014/v1",
    return_timings=True,
    api_key_env="CLANKER_API_KEY",
    effort_levels=("none", "low", "high", "max"),
)
INKLING = Profile(
    name="inkling-2-mini",
    base_url="http://build21:8017/v1",
    model="inkling-2-mini",
    effort_levels=("none", "minimal", "low", "medium", "high", "xhigh", "max"),
    numeric_effort_range=(0, 0.99),
)
DEFAULT_PROFILE = DEEPSEEK.name
INKLING_LOW = replace(INKLING, name="inkling-low", reasoning_effort="low")
PROFILES = {p.name: p for p in (DEEPSEEK, INKLING, INKLING_LOW)}


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


def resolve_profile(xsh, profile=None):
    """Resolve shell defaults once. An explicit Profile is ready to deploy as given."""
    if isinstance(profile, Profile):
        return profile
    name = selected_profile(xsh, profile)
    preset = PROFILES[name]
    if name == DEFAULT_PROFILE:
        return replace(
            preset,
            base_url=xsh.env.get("CLANKER_BASE_URL", preset.base_url),
            model=xsh.env.get("CLANKER_MODEL", preset.model),
        )
    return preset


def get_model(xsh, name=None):
    from langchain_openai_compatible import ChatOpenAICompatible
    from wes.ai.models import connect

    profile = resolve_profile(xsh, name)
    api_key = (
        xsh.env.get(profile.api_key_env, "none") if profile.api_key_env else "none"
    )
    return connect(
        profile.base_url,
        profile.model,
        api_key,
        "$CLANKER_MODEL",
        client_class=ChatOpenAICompatible,
        **profile.client_options(),
    )
