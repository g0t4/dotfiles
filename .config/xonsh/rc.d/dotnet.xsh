""".NET abbreviations and Fish-backed version helpers."""

from xonsh.built_ins import XSH
from wes_dotnet_abbreviations import FISH_FUNCTIONS, register_dotnet_abbreviations
from wes_fish_migration import register_misc_fish_functions

register_dotnet_abbreviations()
register_misc_fish_functions(XSH.aliases, FISH_FUNCTIONS)
