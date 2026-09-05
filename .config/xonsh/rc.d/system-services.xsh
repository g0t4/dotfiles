"""Service-manager and container-runtime abbreviations."""

from wes_misc_functions import register_misc_fish_functions
from wes_system_services_abbreviations import (
    FISH_FUNCTIONS,
    register_system_services_abbreviations,
)


register_system_services_abbreviations()
register_misc_fish_functions(aliases, FISH_FUNCTIONS)
