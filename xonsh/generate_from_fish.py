#!/usr/bin/env python3
"""Generate one-to-one Xonsh modules from dedicated Fish source files."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from fish_to_xonsh import generate
from fish_to_xonsh_policy import (
    DEDUPLICATED_ABBREVIATIONS,
    declaration,
    should_skip,
)


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "fish/load_last_interactive_only"
TARGET_DIR = ROOT / ".config/xonsh/lib"


@dataclass(frozen=True)
class FishMapping:
    fish_file: str
    xonsh_module: str

    @property
    def source(self) -> Path:
        return FISH_DIR / self.fish_file

    @property
    def target(self) -> Path:
        return TARGET_DIR / f"wes_{self.xonsh_module}_abbreviations.py"


MAPPINGS = (
    FishMapping("system-services-specific.fish", "system_services"),
    FishMapping("kubernetes-specific.fish", "kubernetes"),
    FishMapping("processes-specific.fish", "processes"),
    FishMapping("cloud-ai-specific.fish", "cloud_ai"),
    FishMapping("media-specific.fish", "media"),
    FishMapping("packages-hardware-specific.fish", "packages_hardware"),
)


def render(mapping: FishMapping) -> str:
    return generate(
        mapping.source,
        title=f"{mapping.xonsh_module.replace('_', ' ').title()} abbreviations "
        f"generated from Fish {mapping.fish_file}.",
        function_name=f"register_{mapping.xonsh_module}_abbreviations",
        declaration_factory=declaration,
        should_skip=should_skip,
        deduplicated_names=frozenset(DEDUPLICATED_ABBREVIATIONS),
    )


def generate_all() -> dict[Path, str]:
    return {mapping.target: render(mapping) for mapping in MAPPINGS}


if __name__ == "__main__":
    for target, content in generate_all().items():
        target.write_text(content)
