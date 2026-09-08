"""Stream-preserving adapters for the small Fish/Zsh tool collections."""

import subprocess
from functools import lru_cache
from pathlib import Path

from wes_fish_executable import find_fish
from wes_fish_bridge import fish_function
from wes_abbreviations import AbbreviationResult


def audio_abbreviation(name, *, cursor=False):
    def expand(context, _match):
        text = fish_function(name, context.token)
        # Match Fish: the first marker is optional, and only it is removed.
        marker = text.find("%") if cursor else -1
        if marker < 0:
            return text
        return AbbreviationResult(text[:marker] + text[marker + 1:], cursor=marker)
    return expand


def network_alias(name, dotfiles):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        source = Path(dotfiles) / "fish/load_last_interactive_only/network-specific.fish"
        return subprocess.run(
            [find_fish(), "-c", 'source $argv[1]; $argv[2] $argv[3..]',
             "--", str(source), name, *args],
            stdin=stdin, stdout=stdout, stderr=stderr,
        ).returncode
    return invoke


def zsh_alias(name):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        # Positional arguments preserve spaces and prevent interpolation as code.
        return subprocess.run(
            ["/bin/zsh", "-ic", '"$@"', "xonsh-bridge", name, *args],
            stdin=stdin, stdout=stdout, stderr=stderr,
        ).returncode
    return invoke


@lru_cache(maxsize=1)
def gitignore_templates():
    result = subprocess.run(
        ["/bin/zsh", "-ic", "_gitignoreio_get_command_list"],
        capture_output=True, text=True, timeout=5, check=True,
    )
    return tuple(line for line in result.stdout.splitlines()
                 if line and all(char.isalnum() or char in "+.-_" for char in line))
