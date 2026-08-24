"""Image, video, screenshot, and media-tool abbreviations."""

from wes_media_abbreviations import FISH_FUNCTIONS, register_media_abbreviations
from wes_misc_functions import register_misc_fish_functions


register_media_abbreviations(XONSH_ABBREVIATIONS)
register_misc_fish_functions(aliases, FISH_FUNCTIONS)
