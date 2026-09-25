"""Public .NET inventory and its Fish-backed Xonsh registration."""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / "xonsh"))
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_abbreviations import reset_registry
from wes_dotnet import register_wes_dotnet


# TODO codex please update what we should keep and nuke rest
# TODO regenerate with xonsh/generate_from_fish.py if we want to keep this test
# def test_dotnet_generated_inventory_is_in_sync():
#     assert TARGET.read_text() == generate()
#     assert "/Users/" not in generate()
#     assert "wes-bootstrap" not in generate()


def test_dotnet_abbreviations_and_function_inventory():
    registry = reset_registry()
    register_wes_dotnet()
    replacements = {entry.trigger: entry.replacement for entry in registry.abbreviations}
    assert replacements["dnb"] == "dotnet build"
    assert replacements["dn9"] == "dotnet_version 9.0"
    assert replacements["dnd9"] == "diff_dotnet 8.0 9.0"
    # TODO validate via registered functions instead of FISH_FUNCTIONS
    # assert "dotnet_version" in FISH_FUNCTIONS
    # assert "diff_dotnet" in FISH_FUNCTIONS
