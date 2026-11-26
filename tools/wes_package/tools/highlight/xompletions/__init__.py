"""Native Xonsh completion for highlight."""


def xonsh_complete(ctx):
    from xonsh.cli_utils import ArgparseCompleter

    from ..__main__ import build_parser

    yield from ArgparseCompleter(build_parser(), command=ctx).complete()
