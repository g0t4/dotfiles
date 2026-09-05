"""Cloud, local-model, logging, and structured-data abbreviations."""

from wes_cloud_ai_abbreviations import FISH_FUNCTIONS, register_cloud_ai_abbreviations
from wes_misc_functions import register_misc_fish_functions


register_cloud_ai_abbreviations()
register_misc_fish_functions(aliases, FISH_FUNCTIONS)


# TODO SKIPPED_MIGRATION: per-file devtools log abbreviations generated from
# ~/.local/share/devtools/*.log at Fish startup.
