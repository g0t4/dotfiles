import test_setup  # noqa: F401

import sqlite3
import subprocess
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from wes_file_history import FileHistory
from wes_fish_z import FishZ
from wes_history_diagnostics import diagnose, filesystem


def z_snapshot(tmp_path, records=()):
    return SimpleNamespace(diagnostic_snapshot=lambda: (str(tmp_path / 'z-data'), list(records)))


def test_inspection_preserves_missing_records_and_explains_sources(tmp_path):
    history = FileHistory(tmp_path / 'history.sqlite3')
    present = tmp_path / 'quote " & <report>.pdf'
    present.write_bytes(b'hello')
    history.record(present, source='pip-rot')
    history.record(present, source='launcher')
    missing = tmp_path / 'old.pdf'
    missing.touch()
    history.record(missing, source='pip-rot')
    missing.unlink()
    missing_dir = tmp_path / 'old-directory'
    z = z_snapshot(tmp_path, [{'path': str(missing_dir), 'rank': 3, 'last_visit': 1000}])
    before = history.database.read_bytes()
    report = diagnose('', history, z)
    assert history.database.read_bytes() == before
    entries = {entry['path']: entry for entry in report['entries']}
    info = entries[str(present)]
    assert info['filesystem']['size'] == 5
    assert info['filesystem']['permissions'].startswith('-')
    assert info['sources'][0]['opens'] == 2
    assert {origin['source'] for origin in info['sources'][0]['recorded_by']} == {'pip-rot', 'launcher'}
    assert entries[str(missing)]['normal_search'] == 'Hidden: missing'
    assert entries[str(missing_dir)]['normal_search'] == 'Hidden: missing'
    history.forget(present)
    assert str(present) not in history.sources()


def test_legacy_database_is_read_without_migration_then_new_opens_add_sources(tmp_path):
    history = FileHistory(tmp_path / 'old.sqlite3')
    path = tmp_path / 'old.txt'
    path.touch()
    with sqlite3.connect(history.database) as connection:
        connection.execute('CREATE TABLE files (path TEXT PRIMARY KEY, opens INTEGER, last_open REAL)')
        connection.execute('INSERT INTO files VALUES (?, 8, 1000)', (str(path),))
    before = history.database.read_bytes()
    origin = diagnose('old.txt', history, z_snapshot(tmp_path))['entries'][0]['sources'][0]
    assert origin['recorded_by'] == [{'source': 'before source tracking', 'opens': 8}]
    assert history.database.read_bytes() == before
    history.record(path, source='pip-rot')
    origin = diagnose('old.txt', history, z_snapshot(tmp_path))['entries'][0]['sources'][0]
    assert origin['opens'] == 9
    assert origin['recorded_by'][-1]['opens'] == 8


def test_explicit_untracked_path_does_not_create_a_history_store(tmp_path):
    history = FileHistory(tmp_path / 'absent/history.sqlite3')
    path = tmp_path / 'untracked'
    path.mkdir()
    entry = diagnose(str(path), history, z_snapshot(tmp_path))['entries'][0]
    assert entry['normal_search'] == 'Not tracked'
    assert entry['sources'] == []
    assert entry['filesystem']['kind'] == 'directory'
    assert not history.database.parent.exists()


def test_z_snapshot_uses_configured_database_and_keeps_missing_paths(tmp_path):
    database = tmp_path / 'configured z data'
    database.write_text('/missing/project|9|1234\nmalformed\n/bad|no|score\n')
    before = database.read_bytes()
    calls = []
    def runner(argv, **kwargs):
        calls.append(argv)
        return subprocess.CompletedProcess(argv, 0, str(database), '')
    name, entries = FishZ(runner=runner, fish_executable='/test/fish').diagnostic_snapshot()
    assert name == str(database)
    assert entries == [{'path': '/missing/project', 'rank': 9.0, 'last_visit': 1234.0}]
    assert calls == [['/test/fish', '-c', 'printf "%s" "$Z_DATA"']]
    assert database.read_bytes() == before


def test_unavailable_store_is_reported_without_hiding_other_sources(tmp_path):
    broken = SimpleNamespace(sources=lambda: (_ for _ in ()).throw(OSError('unreadable')))
    report = diagnose('lost', broken, z_snapshot(tmp_path, [{'path': '/lost', 'rank': 1, 'last_visit': 1000}]))
    assert report['entries'][0]['path'] == '/lost'
    assert 'unreadable' in report['warnings'][0]


def test_stat_distinguishes_broken_symlink_and_permission_error(tmp_path):
    link = tmp_path / 'broken'
    link.symlink_to('missing-target')
    assert filesystem(link)['status'] == 'missing'
    assert filesystem(link)['symlink_target'] == 'missing-target'
    with patch('wes_history_diagnostics.os.stat', side_effect=PermissionError('denied')):
        assert filesystem(tmp_path)['status'] == 'unavailable'


def test_z_entry_replaced_by_file_is_explained_as_hidden(tmp_path):
    path = tmp_path / 'used-to-be-directory'
    path.touch()
    report = diagnose(str(path), FileHistory(tmp_path / 'no.sqlite3'), z_snapshot(tmp_path, [
        {'path': str(path), 'rank': 1, 'last_visit': 1000},
    ]))
    assert report['entries'][0]['normal_search'] == 'Hidden: z history entry is no longer a directory'
