"""Ansible abbreviations and Fish-backed reporting helpers."""

from wes_ansible_abbreviations import FISH_FUNCTIONS, register_ansible_abbreviations
from wes_misc_functions import register_misc_fish_functions


register_ansible_abbreviations()
register_misc_fish_functions(aliases, FISH_FUNCTIONS)


# TODO SKIPPED_MIGRATION: generated Fish completions under fish/completions/
# for Ansible commands. Evaluate native Xonsh/argcomplete integration separately.
