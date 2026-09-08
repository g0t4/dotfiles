"""Generated from fish/load_last_interactive_only/network-specific.fish; edit Fish/Zsh and rerun the generator."""

from wes_abbreviations import abbr

SOURCE_FUNCTIONS = ('_default_gateway', '_my_ip4', '_my_ip6', '_ssh_exit_all_sockets')


def register_network_abbreviations():
    abbr('trace1', 'traceroute -n 1.1.1.1')  # Source line 1
    abbr('tr6', 'traceroute -n -6')  # Source line 2
    abbr('ping1', 'ping -d 1.1.1.1')  # Source line 4
    abbr('ping8', 'ping -d 8.8.8.8')  # Source line 5
    abbr('pingd', 'ping -d $(_default_gateway)')  # Source line 9
    abbr('p6', 'ping -d -6')  # Source line 10
