"""HTTP abbreviations and Fish-owned network helpers."""

from xonsh.built_ins import XSH
from wes_http_tool_abbreviations import register_http_abbreviations
from wes_network_tool_abbreviations import SOURCE_FUNCTIONS, register_network_abbreviations
from wes_daily_tool_bridges import network_alias

register_http_abbreviations()
register_network_abbreviations()
for _network_function in SOURCE_FUNCTIONS:
    XSH.aliases[_network_function] = network_alias(_network_function, $WES_DOTFILES)
