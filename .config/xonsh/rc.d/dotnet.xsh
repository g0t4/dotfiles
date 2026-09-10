""".NET abbreviations and Fish-backed version helpers."""

from xonsh.built_ins import XSH
from wes_dotnet_abbreviations import FISH_FUNCTIONS, register_dotnet_abbreviations
from wes_misc_functions import register_misc_fish_functions

register_dotnet_abbreviations()
register_misc_fish_functions(XSH.aliases, FISH_FUNCTIONS)
