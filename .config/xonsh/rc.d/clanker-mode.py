"""Clanker runs inside this Xonsh process; dependencies load only when invoked."""
from pathlib import Path

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
aliases['clanker'] = _clank_alias
from wes_abbreviations import abbr
abbr('c', 'clank!') # ! treats everything after it as an argument (that way if you do `clank hello and goodbye` you don't get a command failure b/c goodbye isn't real + with `clank! hello and goodbyte` the model gets your entire prompt
abbr('cm', 'clank manage')
abbr('cmr', 'clank manage restore')
abbr('cmn', 'clank manage rename') # cm re[n]ame (b/c I suspect restore might become more useful, or at least w.r.t. rename)
abbr('cml', 'clank manage list')
abbr('cmc', 'clank manage compact')
abbr('cmm', 'clank manage messages')
abbr('cms', 'clank manage save')


from clanker_profiles import initialize_profile
from xonsh.built_ins import XSH
from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import RichCompletion, contextual_command_completer
from xonsh.events import events


initialize_profile(XSH)


@contextual_command_completer
def _clanker_completer(command):
    if command.command not in {'clank', 'clanker'} or command.arg_index < 1:
        return None
    from clanker_completion import shell_candidates

    saved = Path.home() / '.local/state/nvim/ask-openai/clanker_mode/saved'
    args = [arg.value for arg in command.args]
    return (
        RichCompletion(
            value,
            prefix_len=len(command.raw_prefix),
            append_closing_quote=False,
            display=display,
            description=description,
            append_space=True,
            provider='clanker',
        )
        for value, display, description in shell_candidates(
            args, command.arg_index, command.prefix, saved
        )
    )


add_one_completer('clanker', _clanker_completer, 'start')


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
