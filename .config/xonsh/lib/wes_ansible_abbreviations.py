"""Generated from fish/load_last_interactive_only/ansibles.fish."""

from __future__ import annotations

from wes_abbreviations import abbr


FISH_FUNCTIONS = (
    '_ansible-config_options_name_contains',  # Fish line 3
    '_ansible-config_option_details_contains',  # Fish line 8
)


def register_ansible_abbreviations():
    abbr('aclsn', '_ansible-config_options_name_contains')  # Fish line 2
    abbr('aclsd', '_ansible-config_option_details_contains')  # Fish line 7
    abbr('ap', 'ansible-playbook')  # Fish line 14
    abbr('apv', 'ansible-playbook -v')  # Fish line 15
    abbr('apvv', 'ansible-playbook -vv')  # Fish line 16
    abbr('apvvv', 'ansible-playbook -vvv')  # Fish line 17
    abbr('aps', 'ansible-playbook --syntax-check')  # Fish line 18
    abbr('apc', 'ansible-playbook --check')  # Fish line 19
    abbr('apcd', 'ansible-playbook --check --diff')  # Fish line 20
    abbr('aplsh', 'ansible-playbook --list-hosts')  # Fish line 22
    abbr('aplst', 'ansible-playbook --list-tags')  # Fish line 23
    abbr('aplsk', 'ansible-playbook --list-tasks')  # Fish line 24
    abbr('al', 'ansible-lint')  # Fish line 26
    abbr('ad', 'ansible-doc')  # Fish line 28
    abbr('adls', 'ansible-doc --list')  # Fish line 31
    abbr('adlsf', 'ansible-doc --list_files')  # Fish line 32
    abbr('ads', 'ansible-doc --snippet')  # Fish line 33
    abbr('adlst_inventory', 'ansible-doc --list --type inventory')  # Fish line 35
    abbr('adlst_become', 'ansible-doc --list --type become')  # Fish line 36
    abbr('adlst_cache', 'ansible-doc --list --type cache')  # Fish line 37
    abbr('adlst_callback', 'ansible-doc --list --type callback')  # Fish line 38
    abbr('adlst_cliconf', 'ansible-doc --list --type cliconf')  # Fish line 39
    abbr('adlst_connection', 'ansible-doc --list --type connection')  # Fish line 40
    abbr('adlst_httpapi', 'ansible-doc --list --type httpapi')  # Fish line 41
    abbr('adlst_lookup', 'ansible-doc --list --type lookup')  # Fish line 42
    abbr('adlst_netconf', 'ansible-doc --list --type netconf')  # Fish line 43
    abbr('adlst_shell', 'ansible-doc --list --type shell')  # Fish line 44
    abbr('adlst_vars', 'ansible-doc --list --type vars')  # Fish line 45
    abbr('adlst_module', 'ansible-doc --list --type module')  # Fish line 46
    abbr('adlst_strategy', 'ansible-doc --list --type strategy')  # Fish line 47
    abbr('adlst_test', 'ansible-doc --list --type test')  # Fish line 48
    abbr('adlst_filter', 'ansible-doc --list --type filter')  # Fish line 49
    abbr('adlst_role', 'ansible-doc --list --type role')  # Fish line 50
    abbr('adlst_keyword', 'ansible-doc --list --type keyword')  # Fish line 51
    abbr('a-gc', 'ansible-galaxy collection')  # Fish line 54
    abbr('a-gcls', 'ansible-galaxy collection list')  # Fish line 55
    abbr('a-gci', 'ansible-galaxy collection install')  # Fish line 56
    abbr('a-gcir', 'ansible-galaxy collection install -r requirements.yml')  # Fish line 57
    abbr('a-gcd', 'ansible-galaxy collection download')  # Fish line 58
    abbr('ac', 'ansible-config')  # Fish line 61
    abbr('acl', 'ansible-config list')  # Fish line 62
    abbr('acls', 'ansible-config list')  # Fish line 63
    abbr('acv', 'ansible-config view')  # Fish line 64
    abbr('acd', 'ansible-config dump')  # Fish line 65
    abbr('acdo', 'ansible-config dump --only-changed')  # Fish line 66
    abbr('aci', 'ansible-config init')  # Fish line 67
    abbr('acif', 'ansible-config init --format')  # Fish line 68
    abbr('acifi', 'ansible-config init --format ini')  # Fish line 69
    abbr('acife', 'ansible-config init --format env')  # Fish line 70
    abbr('acifv', 'ansible-config init --format vars')  # Fish line 71
    abbr('av', 'ansible-vault')  # Fish line 73
    abbr('ai', 'ansible-inventory')  # Fish line 75
    abbr('ails', 'ansible-inventory --list --yaml')  # Fish line 77
    abbr('ails_vars', 'ansible-inventory --list --yaml --vars')  # Fish line 78
    abbr('ails_toml', 'ansible-inventory --list --toml')  # Fish line 79
    abbr('ails_toml_vars', 'ansible-inventory --list --toml --vars')  # Fish line 80
    abbr('ails_generate_yaml_inventory', 'ansible-inventory --list --yaml -i foo,bar% > inventory.yml', cursor_marker="%")  # Fish line 83
    abbr('ails_generate_toml_inventory', 'ansible-inventory --list --toml -i foo,bar% > inventory.yml', cursor_marker="%")  # Fish line 84
    abbr('aig', 'ansible-inventory --graph')  # Fish line 86
    abbr('aih', 'ansible-inventory --host')  # Fish line 87
    abbr('apull', 'ansible-pull')  # Fish line 89
