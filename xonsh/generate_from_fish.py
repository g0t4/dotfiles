#!/usr/bin/env python3
"""Generate one-to-one Xonsh modules from dedicated Fish source files."""

from __future__ import annotations

from pathlib import Path

from fish_to_xonsh_policy import (
    DEDUPLICATED_ABBREVIATIONS,
    FishMapping,
    declaration,
    generate_wrapped,
    should_skip,
)


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "fish/load_last_interactive_only"
XONSH_DIR = ROOT / ".config/xonsh/lib"

MAPPINGS = (
    FishMapping(FISH_DIR / "system-services-specific.fish", XONSH_DIR / "wes_system_services_abbreviations.py"),
    FishMapping(FISH_DIR / "kubernetes-specific.fish", XONSH_DIR / "wes_kubernetes_abbreviations.py"),
    FishMapping(FISH_DIR / "processes-specific.fish", XONSH_DIR / "wes_processes_abbreviations.py"),
    FishMapping(FISH_DIR / "cloud-ai-specific.fish", XONSH_DIR / "wes_cloud_ai_abbreviations.py"),
    FishMapping(FISH_DIR / "media-specific.fish", XONSH_DIR / "wes_media_abbreviations.py"),
    FishMapping(FISH_DIR / "packages-hardware-specific.fish", XONSH_DIR / "wes_packages_hardware_abbreviations.py"),
)


if __name__ == "__main__":
    for m in MAPPINGS:
        m.xonsh_module.write_text(generate_wrapped(m, call_register=False))
