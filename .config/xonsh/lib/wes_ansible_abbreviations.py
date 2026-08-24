"""Generated from fish/load_last_interactive_only/ansibles.fish."""

from __future__ import annotations

from wes_abbreviations import AbbreviationRegistry, abbr


FISH_FUNCTIONS = (
    '_ansible-config_options_name_contains',  # Fish line 3
    '_ansible-config_option_details_contains',  # Fish line 8
)


def register_ansible_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'aclsn', '_ansible-config_options_name_contains')  # Fish line 2
    abbr(registry, 'aclsd', '_ansible-config_option_details_contains')  # Fish line 7
    abbr(registry, 'ap', 'ansible-playbook')  # Fish line 14
    abbr(registry, 'apv', 'ansible-playbook -v')  # Fish line 15
    abbr(registry, 'apvv', 'ansible-playbook -vv')  # Fish line 16
    abbr(registry, 'apvvv', 'ansible-playbook -vvv')  # Fish line 17
    abbr(registry, 'aps', 'ansible-playbook --syntax-check')  # Fish line 18
    abbr(registry, 'apc', 'ansible-playbook --check')  # Fish line 19
    abbr(registry, 'apcd', 'ansible-playbook --check --diff')  # Fish line 20
    abbr(registry, 'aplsh', 'ansible-playbook --list-hosts')  # Fish line 22
    abbr(registry, 'aplst', 'ansible-playbook --list-tags')  # Fish line 23
    abbr(registry, 'aplsk', 'ansible-playbook --list-tasks')  # Fish line 24
    abbr(registry, 'al', 'ansible-lint')  # Fish line 26
    abbr(registry, 'ad', 'ansible-doc')  # Fish line 28
    abbr(registry, 'adls', 'ansible-doc --list')  # Fish line 31
    abbr(registry, 'adlsf', 'ansible-doc --list_files')  # Fish line 32
    abbr(registry, 'ads', 'ansible-doc --snippet')  # Fish line 33
    abbr(registry, 'adlst_inventory', 'ansible-doc --list --type inventory')  # Fish line 35
    abbr(registry, 'adlst_become', 'ansible-doc --list --type become')  # Fish line 36
    abbr(registry, 'adlst_cache', 'ansible-doc --list --type cache')  # Fish line 37
    abbr(registry, 'adlst_callback', 'ansible-doc --list --type callback')  # Fish line 38
    abbr(registry, 'adlst_cliconf', 'ansible-doc --list --type cliconf')  # Fish line 39
    abbr(registry, 'adlst_connection', 'ansible-doc --list --type connection')  # Fish line 40
    abbr(registry, 'adlst_httpapi', 'ansible-doc --list --type httpapi')  # Fish line 41
    abbr(registry, 'adlst_lookup', 'ansible-doc --list --type lookup')  # Fish line 42
    abbr(registry, 'adlst_netconf', 'ansible-doc --list --type netconf')  # Fish line 43
    abbr(registry, 'adlst_shell', 'ansible-doc --list --type shell')  # Fish line 44
    abbr(registry, 'adlst_vars', 'ansible-doc --list --type vars')  # Fish line 45
    abbr(registry, 'adlst_module', 'ansible-doc --list --type module')  # Fish line 46
    abbr(registry, 'adlst_strategy', 'ansible-doc --list --type strategy')  # Fish line 47
    abbr(registry, 'adlst_test', 'ansible-doc --list --type test')  # Fish line 48
    abbr(registry, 'adlst_filter', 'ansible-doc --list --type filter')  # Fish line 49
    abbr(registry, 'adlst_role', 'ansible-doc --list --type role')  # Fish line 50
    abbr(registry, 'adlst_keyword', 'ansible-doc --list --type keyword')  # Fish line 51
    abbr(registry, 'a-gc', 'ansible-galaxy collection')  # Fish line 54
    abbr(registry, 'a-gcls', 'ansible-galaxy collection list')  # Fish line 55
    abbr(registry, 'a-gci', 'ansible-galaxy collection install')  # Fish line 56
    abbr(registry, 'a-gcir', 'ansible-galaxy collection install -r requirements.yml')  # Fish line 57
    abbr(registry, 'a-gcd', 'ansible-galaxy collection download')  # Fish line 58
    abbr(registry, 'ac', 'ansible-config')  # Fish line 61
    abbr(registry, 'acl', 'ansible-config list')  # Fish line 62
    abbr(registry, 'acls', 'ansible-config list')  # Fish line 63
    abbr(registry, 'acv', 'ansible-config view')  # Fish line 64
    abbr(registry, 'acd', 'ansible-config dump')  # Fish line 65
    abbr(registry, 'acdo', 'ansible-config dump --only-changed')  # Fish line 66
    abbr(registry, 'aci', 'ansible-config init')  # Fish line 67
    abbr(registry, 'acif', 'ansible-config init --format')  # Fish line 68
    abbr(registry, 'acifi', 'ansible-config init --format ini')  # Fish line 69
    abbr(registry, 'acife', 'ansible-config init --format env')  # Fish line 70
    abbr(registry, 'acifv', 'ansible-config init --format vars')  # Fish line 71
    abbr(registry, 'av', 'ansible-vault')  # Fish line 73
    abbr(registry, 'ai', 'ansible-inventory')  # Fish line 75
    abbr(registry, 'ails', 'ansible-inventory --list --yaml')  # Fish line 77
    abbr(registry, 'ails_vars', 'ansible-inventory --list --yaml --vars')  # Fish line 78
    abbr(registry, 'ails_toml', 'ansible-inventory --list --toml')  # Fish line 79
    abbr(registry, 'ails_toml_vars', 'ansible-inventory --list --toml --vars')  # Fish line 80
    abbr(registry, 'ails_generate_yaml_inventory', 'ansible-inventory --list --yaml -i foo,bar% > inventory.yml', cursor_marker="%")  # Fish line 83
    abbr(registry, 'ails_generate_toml_inventory', 'ansible-inventory --list --toml -i foo,bar% > inventory.yml', cursor_marker="%")  # Fish line 84
    abbr(registry, 'aig', 'ansible-inventory --graph')  # Fish line 86
    abbr(registry, 'aih', 'ansible-inventory --host')  # Fish line 87
    abbr(registry, 'apull', 'ansible-pull')  # Fish line 89
