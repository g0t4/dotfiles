"""Real SQLite persistence, concurrent writers, ranking, and accepted-open integration."""
import concurrent.futures
import os
from pathlib import Path
import sys
import tempfile
from unittest.mock import patch
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / '.config/xonsh/lib'))
from wes_file_history import FileHistory, search
from file_history import open_tracked_file

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    history = FileHistory(root / 'history.sqlite3')
    file = root / 'a "quote"\nreport.pdf'
    file.touch()
    other = root / 'report backup.pdf'
    other.touch()
    assert history.entries() == []
    assert not history.record(root)
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        assert all(pool.map(history.record, [file] * 20))
    assert history.entries()[0][1] == 20
    history.record(other)
    assert search('quote report', history)[0]['path'] == str(file)
    assert search('report backup.pdf', history)[0]['path'] == str(other)
    assert not search('unmatched', history)
    assert search('', history)[0]['path'] == str(other)  # most recent first
    directory = root / 'reports'
    directory.mkdir()
    dirs = [SimpleNamespace(path=directory, frecency=42)]
    assert any(item['kind'] == 'directory' for item in search('reports', history, dirs))
    assert not history.record(directory)
    with patch('wes_file_history.time.time', return_value=1000):
        history.record(file)
        history.record(other)
        assert search('report', history)[0]['path'] == str(file)  # equal matches favor usage
    file.unlink()
    assert all(item['path'] != str(file) for item in search('', history))
    assert len(history.entries()) == 2  # disconnected/missing paths aren't purged
    file.touch()
    with patch('file_history.QDesktopServices.openUrl', return_value=False), patch('file_history.FileHistory', return_value=history):
        assert not open_tracked_file(file)
    assert history.entries()[0][1] == 21
    with patch('file_history.QDesktopServices.openUrl', return_value=True), patch('file_history.FileHistory', return_value=history):
        assert open_tracked_file(file)
    assert history.entries()[0][1] == 22
    with patch('file_history.QDesktopServices.openUrl', return_value=True), patch('file_history.FileHistory') as backend:
        backend.return_value.record.side_effect = OSError('unwritable')
        assert open_tracked_file(file)
    history.forget(file)
    assert len(history.entries()) == 1
print('PASS: concurrent writes, persistence, unusual paths, ranking, missing files, accepted opens, storage failure, forgetting')
