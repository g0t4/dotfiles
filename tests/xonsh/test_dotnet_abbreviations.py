"""Public .NET inventory and its Fish-backed Xonsh registration."""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / "xonsh"))
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from generate_dotnet_abbreviations import SOURCE, TARGET, generate
from wes_abbreviations import reset_registry
from wes_dotnet_abbreviations import FISH_FUNCTIONS, register_dotnet_abbreviations


def test_dotnet_generated_inventory_is_in_sync():
    assert TARGET.read_text() == generate()
    assert "/Users/" not in generate()
    assert "wes-bootstrap" not in generate()


def test_dotnet_abbreviations_and_function_inventory():
    registry = reset_registry()
    register_dotnet_abbreviations()
    replacements = {entry.trigger: entry.replacement for entry in registry.abbreviations}
    assert replacements["dnb"] == "dotnet build"
    assert replacements["dn9"] == "dotnet_version 9.0"
    assert replacements["dnd9"] == "diff_dotnet 8.0 9.0"
    assert "dotnet_version" in FISH_FUNCTIONS
    assert "diff_dotnet" in FISH_FUNCTIONS


def test_dotnet_fish_helpers_load_without_private_config():
    from wes_fish_executable import find_fish

    result = subprocess.run(
        [find_fish(), "--no-config", "-c",
         "source $argv[1]; functions --query $argv[2..]",
         "--", str(SOURCE), *FISH_FUNCTIONS],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr


def test_dotnet_xonsh_registration_without_private_config():
    result = subprocess.run(
        ["xonsh", "--no-rc", "-c",
         f"import sys; sys.path.insert(0, {str(ROOT / '.config/xonsh/lib')!r}); "
         f"source {ROOT / '.config/xonsh/rc.d/dotnet.xsh'}; "
         "from xonsh.built_ins import XSH; "
         "assert 'dotnet_version' in XSH.aliases"],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr
