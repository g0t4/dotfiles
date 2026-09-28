"""Public .NET inventory and its Fish-backed Xonsh registration."""

import test_setup

import subprocess

from wes_abbreviations import reset_registry
from wes_dotnet import register_wes_dotnet


def test_dotnet_abbreviations_and_function_inventory():
    registry = reset_registry()
    register_wes_dotnet()
    replacements = {entry.trigger: entry.replacement for entry in registry.abbreviations}
    assert replacements["dnb"] == "dotnet build"
    assert replacements["dn9"] == "dotnet_version 9.0"
    assert replacements["dnd9"] == "diff_dotnet 8.0 9.0"
    from xonsh.built_ins import XSH
    assert "dotnet_version" in XSH.aliases
    assert "diff_dotnet" in XSH.aliases
