"""Launch the independent Slop Reel desktop app with its own environment."""
from xonsh.built_ins import XSH
from wes_abbreviations import abbr
XSH.aliases['slop-reel'] = [str(XONSH_LIB.resolve().parents[2] / 'tools' / 'slop_reel' / 'slop-reel')]
abbr('sr', 'slop-reel')
