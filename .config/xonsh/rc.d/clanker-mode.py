"""Clanker runs inside this Xonsh process; dependencies load only when invoked."""
_clanker_path = str(XONSH_LIB.resolve().parents[2] / 'tools' / 'clanker_mode')
if _clanker_path not in sys.path:
    sys.path.insert(0, _clanker_path)


def _clank_alias(args, stdin=None, stdout=None, stderr=None):
    import warnings

    # LangSmith 0.14.17 uses this deprecated asyncio helper during import.
    # Hide only that notice; restore filters before running user/agent code.
    with warnings.catch_warnings():
        warnings.filterwarnings(
            'ignore',
            message=r"'asyncio\.iscoroutinefunction' is deprecated and slated for removal in Python 3\.16; use inspect\.iscoroutinefunction\(\) instead$",
            category=DeprecationWarning,
            module=r'langsmith\._internal\._beta_decorator$',
        )
        from clanker_mode import clank
    return clank(args, stdin=stdin, stdout=stdout, stderr=stderr)


_clank_alias.__xonsh_threadable__ = False
aliases['clank'] = _clank_alias
from wes_abbreviations import abbr
abbr('c', 'clank')


from xonsh.built_ins import XSH
from xonsh.events import events


@events.on_transform_command
def _clanker_literal_syntax_fallback(cmd, **kwargs):
    """Treat syntax-invalid clank submissions as literal natural language."""
    if not cmd or not cmd.startswith('clank'):
        return
    if len(cmd) == 5 or not cmd[5].isspace():
        return
    try:
        XSH.execer.compile(cmd, mode='single', glbs=XSH.ctx)
    except SyntaxError:
        # A Python call bypasses shell expansion, comments and quoting. Its
        # different prefix also makes repeated transform events idempotent.
        prompt = cmd[5:].lstrip().rstrip('\n')
        return f'_clank_alias([{prompt!r}])\n'
