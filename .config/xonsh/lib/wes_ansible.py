"""generated from Fish"""

from __future__ import annotations

import re
import os
import platform

from xonsh.built_ins import XSH
from wes_abbreviations import abbr
from wes_fish_migration import (
    wrap_fish_functions,
    abbr_from_fish_function,
    platform_abbreviation,
    unsupported_abbreviation,
)


def register_wes_ansible():
    fish_funcs = (
        '_ansible-config_options_name_contains',
        '_ansible-config_option_details_contains',
    )
    wrap_fish_functions(XSH.aliases, fish_funcs)
    abbr('aclsn', '_ansible-config_options_name_contains')
    abbr('aclsd', '_ansible-config_option_details_contains')
    abbr('ap', 'ansible-playbook')
    abbr('apv', 'ansible-playbook -v')
    abbr('apvv', 'ansible-playbook -vv')
    abbr('apvvv', 'ansible-playbook -vvv')
    abbr('aps', 'ansible-playbook --syntax-check')
    abbr('apc', 'ansible-playbook --check')
    abbr('apcd', 'ansible-playbook --check --diff')
    abbr('aplsh', 'ansible-playbook --list-hosts')
    abbr('aplst', 'ansible-playbook --list-tags')
    abbr('aplsk', 'ansible-playbook --list-tasks')
    abbr('al', 'ansible-lint')
    abbr('ad', 'ansible-doc')
    abbr('adls', 'ansible-doc --list')
    abbr('adlsf', 'ansible-doc --list_files')
    abbr('ads', 'ansible-doc --snippet')
    abbr('adlst_inventory', 'ansible-doc --list --type inventory')
    abbr('adlst_become', 'ansible-doc --list --type become')
    abbr('adlst_cache', 'ansible-doc --list --type cache')
    abbr('adlst_callback', 'ansible-doc --list --type callback')
    abbr('adlst_cliconf', 'ansible-doc --list --type cliconf')
    abbr('adlst_connection', 'ansible-doc --list --type connection')
    abbr('adlst_httpapi', 'ansible-doc --list --type httpapi')
    abbr('adlst_lookup', 'ansible-doc --list --type lookup')
    abbr('adlst_netconf', 'ansible-doc --list --type netconf')
    abbr('adlst_shell', 'ansible-doc --list --type shell')
    abbr('adlst_vars', 'ansible-doc --list --type vars')
    abbr('adlst_module', 'ansible-doc --list --type module')
    abbr('adlst_strategy', 'ansible-doc --list --type strategy')
    abbr('adlst_test', 'ansible-doc --list --type test')
    abbr('adlst_filter', 'ansible-doc --list --type filter')
    abbr('adlst_role', 'ansible-doc --list --type role')
    abbr('adlst_keyword', 'ansible-doc --list --type keyword')
    abbr('a-gc', 'ansible-galaxy collection')
    abbr('a-gcls', 'ansible-galaxy collection list')
    abbr('a-gci', 'ansible-galaxy collection install')
    abbr('a-gcir', 'ansible-galaxy collection install -r requirements.yml')
    abbr('a-gcd', 'ansible-galaxy collection download')
    abbr('ac', 'ansible-config')
    abbr('acl', 'ansible-config list')
    abbr('acls', 'ansible-config list')
    abbr('acv', 'ansible-config view')
    abbr('acd', 'ansible-config dump')
    abbr('acdo', 'ansible-config dump --only-changed')
    abbr('aci', 'ansible-config init')
    abbr('acif', 'ansible-config init --format')
    abbr('acifi', 'ansible-config init --format ini')
    abbr('acife', 'ansible-config init --format env')
    abbr('acifv', 'ansible-config init --format vars')
    abbr('av', 'ansible-vault')
    abbr('ai', 'ansible-inventory')
    abbr('ails', 'ansible-inventory --list --yaml')
    abbr('ails_vars', 'ansible-inventory --list --yaml --vars')
    abbr('ails_toml', 'ansible-inventory --list --toml')
    abbr('ails_toml_vars', 'ansible-inventory --list --toml --vars')
    abbr('ails_generate_yaml_inventory', 'ansible-inventory --list --yaml -i foo,bar% > inventory.yml', cursor_marker="%")
    abbr('ails_generate_toml_inventory', 'ansible-inventory --list --toml -i foo,bar% > inventory.yml', cursor_marker="%")
    abbr('aig', 'ansible-inventory --graph')
    abbr('aih', 'ansible-inventory --host')
    abbr('apull', 'ansible-pull')


