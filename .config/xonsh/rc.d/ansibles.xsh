"""Ansible abbreviations and Fish-backed reporting helpers."""

from xonsh.built_ins import XSH

aliases = XSH.aliases

from wes_ansible_abbreviations import FISH_FUNCTIONS, register_ansible_abbreviations
from wes_fish_migration import wrap_fish_functions


register_ansible_abbreviations()
wrap_fish_functions(aliases, FISH_FUNCTIONS)


# TODO SKIPPED_MIGRATION: generated Fish completions under fish/completions/
# for Ansible commands. Evaluate native Xonsh/argcomplete integration separately.
