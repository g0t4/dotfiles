import test_setup

import os
import subprocess
import sys

from wes_command_usage import Store, analyze, explain_source


def run_capture(tmp_path, source, *, audit=True):
    db = tmp_path / 'capture.sqlite3'
    wrapper = tmp_path / 'runner.xsh'
    wrapper.write_text(f'''from wes_command_usage import Recorder
r = Recorder({str(db)!r}, session='test-session', python_io={audit!r}).install()
try:
    r.execute({source!r})
finally:
    r.close()
''')
    env = dict(os.environ, PYTHONPATH=str(test_setup.XONSH_LIB), XDG_STATE_HOME=str(tmp_path / 'state'))
    completed = subprocess.run([sys.executable, '-m', 'xonsh', '--no-rc', str(wrapper)],
                               cwd=tmp_path, env=env, capture_output=True, text=True, timeout=20)
    return completed, Store(db)


def test_live_expansion_aliases_redirects_pipeline_and_python_io(tmp_path):
    (tmp_path/'a.txt').write_text('a')
    (tmp_path/'b.txt').write_text('b')
    completed, store = run_capture(tmp_path, '''files = ['a.txt', 'b.txt']
aliases['mycat'] = ['cat']
mycat @(files) > output.txt
cat *.txt | wc -c
from pathlib import Path
Path('python.txt').write_text('hello')
''')
    assert completed.returncode == 0, completed.stderr
    events = store.events()
    invocations = [e for e in events if e['kind'] == 'invocation']
    assert any(e['alias'] == 'mycat' and e['argv'][1:] == ['a.txt', 'b.txt'] for e in invocations)
    assert any('b.txt' in e['argv'] for e in invocations)
    assert any(e['streams']['stdout']['path'] == 'output.txt' for e in invocations)
    assert {e['pipeline_index'] for e in invocations} >= {0, 1}
    assert any(e['kind'] == 'python_io_attempt' and 'python.txt' in e['paths'] for e in events)
    assert all(e['origin'] == 'cli' and e['session'] == 'test-session' for e in events)
    first = store.rebuild()
    assert first == store.rebuild() == analyze(events)['resources']
    assert any(r['path'] == str(tmp_path/'output.txt') for r in first)
    with store.connect() as db:
        assert db.execute('SELECT COUNT(*) FROM resources').fetchone()[0] == len(first)


def test_hidden_child_io_is_unknown_and_cwd_changes_are_real(tmp_path):
    (tmp_path/'pyproject.toml').write_text('secret input')
    (tmp_path/'subdir').mkdir()
    build = tmp_path/'build.sh'
    build.write_text('#!/bin/sh\ncat pyproject.toml >/dev/null\nprintf hidden > hidden.bin\n')
    build.chmod(0o755)
    completed, store = run_capture(tmp_path, '''$[./build.sh]
$[cd subdir]
$[touch created.txt]
''')
    assert completed.returncode == 0, completed.stderr
    result = analyze(store.events())
    assert any(r['path'] == str(tmp_path/'subdir/created.txt') for r in result['resources'])
    assert not any(r['path'].endswith(('hidden.bin', 'pyproject.toml')) for r in result['resources'])
    assert result['unknown']
    assert (tmp_path/'hidden.bin').exists()


def test_failure_and_background_are_not_reported_as_success(tmp_path):
    completed, store = run_capture(tmp_path, 'import subprocess\ntry:\n    $[false]\nexcept subprocess.CalledProcessError:\n    pass\n$[sleep 0.05 &]\n')
    assert completed.returncode == 0, completed.stderr
    events = store.events()
    assert any(e['kind'] == 'invocation' and e['background'] for e in events)
    # Launch is not completion. No invented per-invocation successful exit.
    assert all('returncode' not in e for e in events if e['kind'].startswith('invocation'))


def test_audit_can_be_disabled_and_reset_drops_everything(tmp_path):
    completed, store = run_capture(tmp_path, "open('python.txt', 'w').close()", audit=False)
    assert completed.returncode == 0, completed.stderr
    assert not any(e['kind'] == 'python_io_attempt' for e in store.events())
    store.rebuild()
    store.reset()
    assert store.events() == []
    assert store.rebuild() == []


def test_static_analysis_never_evaluates_dynamic_expressions(tmp_path):
    target = tmp_path/'must-not-exist'
    result = explain_source(f"cat @(open({str(target)!r}, 'w'))")
    assert result['commands']
    assert 'unresolved' in str(result['commands'])
    assert not target.exists()
    assert explain_source('cat a.txt | jq .')['commands'] == [['cat', 'a.txt'], ['jq', '.']]
    assert explain_source('cat "unterminated')['unknown']


def test_interactive_rc_hooks_record_failed_command_and_distinct_operations(tmp_path):
    rc = test_setup.ROOT / '.config/xonsh/rc.d/command-usage.xsh'
    env = dict(os.environ, PYTHONPATH=str(test_setup.XONSH_LIB), XDG_STATE_HOME=str(tmp_path/'state'),
               XONSH_COMMAND_USAGE='True', XONSH_COMMAND_USAGE_PYTHON_IO='True')
    completed = subprocess.run([sys.executable, '-m', 'xonsh', '-i', '--rc', str(rc), '--shell-type', 'dumb'],
        input='touch from-interactive.txt\nfalse\nexit\n', cwd=tmp_path, env=env,
        capture_output=True, text=True, timeout=20)
    store = Store(tmp_path/'state/command-usage/events.sqlite3')
    events = store.events()
    assert any(e['kind'] == 'invocation' and 'from-interactive.txt' in e['argv'] for e in events), completed.stderr
    assert any(e['kind'] == 'operation_finish' and e['returncode'] == 1 for e in events)
    assert len({e['operation'] for e in events if e['kind'] == 'operation_start'}) >= 2


def test_python_failed_io_and_descriptor_paths_are_not_claimed_as_success(tmp_path):
    completed, store = run_capture(tmp_path, '''import os
try:
    open('absent.txt')
except FileNotFoundError:
    pass
os.mkdir('directory')
fd = os.open('directory', os.O_RDONLY)
try:
    os.remove('absent-relative', dir_fd=fd)
except FileNotFoundError:
    pass
os.close(fd)
''')
    assert completed.returncode == 0, completed.stderr
    result = analyze(store.events())
    assert any(r['path'].endswith('absent.txt') and r['evidence'] == 'python-audit-attempt' for r in result['resources'])
    assert not any(r['path'].endswith('absent-relative') for r in result['resources'])
    assert any('descriptor' in u['reason'] for u in result['unknown'])


def test_failed_execution_flushes_events(tmp_path):
    completed, store = run_capture(tmp_path, '$[false]')
    assert completed.returncode != 0
    assert any(e['kind'] == 'operation_finish' and e['returncode'] == 1 for e in store.events())


def test_callable_alias_and_environment_expansion(tmp_path):
    (tmp_path/'input.txt').write_text('data')
    completed, store = run_capture(tmp_path, '''$CAPTURE_INPUT = 'input.txt'
def inspect_args(args, stdin=None):
    return 0
aliases['inspect-args'] = inspect_args
inspect-args $CAPTURE_INPUT
''')
    assert completed.returncode == 0, completed.stderr
    invocations = [e for e in store.events() if e['kind'] == 'invocation']
    event = next(e for e in invocations if e['alias'] == 'inspect-args')
    assert event['argv'] == ['inspect-args', 'input.txt']
    assert event['resolved_args'] == ['input.txt']
    assert event['observed_arguments']['input.txt']['exists']
    assert any(r['path'] == str(tmp_path/'input.txt') for r in store.rebuild())


def test_incompatible_store_requires_reset_not_migration(tmp_path):
    from wes_command_usage.__main__ import main
    import sqlite3
    path = tmp_path/'old.sqlite3'
    with sqlite3.connect(path) as db:
        db.execute('PRAGMA user_version=999')
    import pytest
    with pytest.raises(RuntimeError, match='reset'):
        Store(path)
    assert main(['--database', str(path), 'reset']) == 0
    assert Store(path).events() == []


def test_storage_failure_cannot_break_the_command(tmp_path):
    completed, store = run_capture(tmp_path, '''from unittest.mock import patch
with patch.object(r.store, 'append', side_effect=OSError('storage unavailable')):
    $[touch still-created.txt]
    r.flush()
''')
    assert completed.returncode == 0, completed.stderr
    assert (tmp_path/'still-created.txt').exists()
    assert 'storage unavailable' in completed.stderr


def test_historical_evidence_is_pure_and_has_no_runtime_expansion():
    event = dict(id='imported-1', kind='invocation', acquisition='historical', origin='cli',
                 cwd='/old/work', session='import', argv=['cat', '*.txt'], timestamp=1)
    assert not analyze([event])['resources']
    assert analyze([event])['unknown']
    assert event['argv'] == ['cat', '*.txt']
