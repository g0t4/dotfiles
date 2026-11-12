"""Clanker runs inside this Xonsh process; dependencies load only when invoked."""
_clanker_path = str(XONSH_LIB.resolve().parents[2] / 'tools' / 'clanker_mode')
if _clanker_path not in sys.path:
    sys.path.insert(0, _clanker_path)


def _clank_alias(args, stdin=None, stdout=None, stderr=None):
    from clanker_mode import clank
    return clank(args, stdin=stdin, stdout=stdout, stderr=stderr)


_clank_alias.__xonsh_threadable__ = False
aliases['clank'] = _clank_alias
from wes_abbreviations import abbr
abbr('c', 'clank')
