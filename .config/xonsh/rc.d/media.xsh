"""Image, video, screenshot, and media-tool abbreviations."""

from xonsh.built_ins import XSH

aliases = XSH.aliases

from wes_media_abbreviations import FISH_FUNCTIONS, register_media_abbreviations
from wes_fish_migration import wrap_fish_functions


register_media_abbreviations()
wrap_fish_functions(aliases, FISH_FUNCTIONS)
