"""Service-manager and container-runtime abbreviations."""

from xonsh.built_ins import XSH

aliases = XSH.aliases

from wes_fish_migration import wrap_fish_functions
from wes_system_services_abbreviations import (
    FISH_FUNCTIONS,
    register_system_services_abbreviations,
)


register_system_services_abbreviations()
wrap_fish_functions(aliases, FISH_FUNCTIONS)
