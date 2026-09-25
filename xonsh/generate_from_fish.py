#!/usr/bin/env python3
"""Generate one-to-one Xonsh modules from dedicated Fish source files."""

from __future__ import annotations

from pathlib import Path
import re

from fish_to_xonsh import (
    FishMapping,
    generate_wrapped,
)

ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "fish/load_last_interactive_only"
ZSH_DIR = ROOT / "zsh/compat_fish"
XONSH_DIR = ROOT / ".config/xonsh/lib"

# long term everything will be in xonsh so this is fine for a stopgap
GIT_VALUE_SUBSTITUTIONS = {
    '"$(_repo_root)"': "$(_repo_root)",
    "$GIT_FULLY_AUTO_REBASE": "GIT_SEQUENCE_EDITOR=true",
    re.compile(r"\$_unpushed_commits([^_]|$)"): "'HEAD@{push}~1..HEAD'",
    "$_unpushed_commits_without_last_pushed": "'HEAD@{push}..HEAD'",
    r"\$(git rev-list --all)": "$(git rev-list --all)",
}

MAPPINGS = (
    FishMapping(FISH_DIR / "system-services-specific.fish", XONSH_DIR / "wes_system_services.py"),
    FishMapping(FISH_DIR / "kubernetes-specific.fish", XONSH_DIR / "wes_kubernetes.py"),
    FishMapping(FISH_DIR / "processes-specific.fish", XONSH_DIR / "wes_processes.py"),
    FishMapping(FISH_DIR / "cloud-ai-specific.fish", XONSH_DIR / "wes_cloud_ai.py"),
    FishMapping(FISH_DIR / "media-specific.fish", XONSH_DIR / "wes_media.py"),
    FishMapping(FISH_DIR / "packages-hardware-specific.fish", XONSH_DIR / "wes_packages_hardware.py"),
    FishMapping(FISH_DIR / "dotnet.fish", XONSH_DIR / "wes_dotnet.py"),
    FishMapping(FISH_DIR / "python-specific.fish", XONSH_DIR / "wes_python.py"),
    FishMapping(FISH_DIR / "ansibles.fish", XONSH_DIR / "wes_ansible.py"),
    FishMapping(FISH_DIR / "docker-specific.fish", XONSH_DIR / "wes_docker.py"),
    FishMapping(FISH_DIR / "git.fish", XONSH_DIR / "wes_git.py", VALUE_SUBSTITUTIONS=GIT_VALUE_SUBSTITUTIONS),

    FishMapping(ZSH_DIR / "hashicorp.zsh", XONSH_DIR / "wes_hashicorp.py"),
)


def generate_all():
    for m in MAPPINGS:
        m.xonsh_module.write_text(generate_wrapped(m, call_register=False))


if __name__ == "__main__":
    generate_all()
