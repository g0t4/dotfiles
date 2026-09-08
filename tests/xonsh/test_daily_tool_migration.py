import importlib
import os
import subprocess
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / '.config/xonsh/lib'))
sys.path.insert(0, str(ROOT / 'xonsh'))

from generate_daily_tool_abbreviations import SOURCES, generate
from wes_abbreviations import AbbreviationContext, reset_registry
from wes_daily_tool_bridges import zsh_alias, network_alias, audio_abbreviation


@pytest.mark.parametrize('domain', SOURCES)
def test_generated_collection_matches_source(domain):
    assert (ROOT / f'.config/xonsh/lib/wes_{domain}_tool_abbreviations.py').read_text() == generate(domain)


@pytest.fixture
def registry():
    registry = reset_registry()
    for domain in SOURCES:
        module = importlib.import_module(f'wes_{domain}_tool_abbreviations')
        getattr(module, f'register_{domain}_abbreviations')()
    return registry


def expand(registry, token, command=None):
    context = AbbreviationContext(token, len(token), 0, len(token), token,
                                  command_path=(command,) if command else (),
                                  command_position=command is None)
    result = registry.expand(context)
    return result[0] if result else None


def test_command_scoped_flags_do_not_leak(registry):
    assert expand(registry, '-d', 'curl').text == '--data'
    assert expand(registry, '-d', 'git') is None
    assert expand(registry, 'no_output', 'ffmpeg').text == '-f null -'
    assert expand(registry, 'no_output', 'echo') is None


def test_static_expansions_and_cursor(registry):
    assert expand(registry, 'gic').text == 'commit_gitignores_for'
    assert expand(registry, 'ghwfl').text == 'gh workflow list'
    assert expand(registry, 'pingd').text == 'ping -d $(_default_gateway)'
    result = expand(registry, 'ffpshow')
    assert result.text == 'ffprobe -loglevel warning  -show_'
    assert result.cursor == len(result.text)
    assert 'filter=whisper && open https://' in expand(registry, 'ff_help_filter_video_whisper').text


def test_bridges_preserve_args_streams_and_exit_status(monkeypatch):
    calls = []
    def run(argv, **kwargs):
        calls.append((argv, kwargs))
        return SimpleNamespace(returncode=17)
    monkeypatch.setattr('wes_daily_tool_bridges.subprocess.run', run)
    monkeypatch.setattr('wes_daily_tool_bridges.find_fish', lambda: '/tools/fish')
    stream = object()
    args = ['two words', '$(do-not-run)']
    assert zsh_alias('gitignores_for')(args, stdout=stream) == 17
    argv, kwargs = calls[-1]
    assert argv == ['/bin/zsh', '-ic', '"$@"', 'xonsh-bridge', 'gitignores_for', *args]
    assert kwargs['stdout'] is stream
    assert network_alias('_default_gateway', ROOT)(args, stdout=stream) == 17
    assert calls[-1][0][-3:] == ['_default_gateway', *args]


@pytest.mark.parametrize('text,expected,cursor', [
    ('ffmpeg -i test.mp4 test.wav', 'ffmpeg -i test.mp4 test.wav', None),
    ('ffmpeg -i % %.wav', 'ffmpeg -i  %.wav', 10),
])
def test_dynamic_cursor_matches_fish(monkeypatch, text, expected, cursor):
    monkeypatch.setattr('wes_daily_tool_bridges.fish_function', lambda *args: text)
    result = audio_abbreviation('_ff_wav', cursor=True)(SimpleNamespace(token='ff_wav'), None)
    assert (result if isinstance(result, str) else result.text) == expected
    assert (None if isinstance(result, str) else result.cursor) == cursor


def test_real_audio_expanders_and_rc_registration(registry, tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    # Empty file suffices: the existing finder selects by extension, not decoding.
    (tmp_path / 'test.mp4').touch()
    assert 'test.mp4' in expand(registry, 'et').text
    assert 'test.wav' in expand(registry, 'ff_wav').text
    assert '-show_streams' in expand(registry, 'ffpshow_streams').text
    rc = ROOT / '.config/xonsh/rc.d'
    code = '; '.join(f'source {rc / name}' for name in ('audio-video.xsh', 'http-network.xsh', 'github-cli.xsh'))
    code += "; assert XSH.aliases['ffmpeg'] == ['ffmpeg', '-hide_banner']; assert callable(XSH.aliases['gitignores_for'])"
    env = os.environ | {'WES_DOTFILES': str(ROOT), 'PYTHONPATH': str(rc.parent / 'lib')}
    result = subprocess.run(['xonsh', '--no-rc', '-c', code], env=env, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
