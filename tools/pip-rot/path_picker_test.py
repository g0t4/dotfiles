"""Real fd/Qt integration and shared shell MRU compatibility."""
import hashlib
from pathlib import Path
import tempfile
import time
import sys
import os
from unittest.mock import patch

from PySide6.QtWidgets import QApplication
from PySide6.QtTest import QTest

from path_picker import PathPicker, PathProvider, PROVIDERS, FzfMru
from pip_rot import Browser

app = QApplication([])


def wait(predicate):
    deadline = time.monotonic() + 5
    while not predicate():
        app.processEvents()
        if time.monotonic() > deadline:
            raise AssertionError('Timed out')
        QTest.qWait(10)


with tempfile.TemporaryDirectory() as temporary:
    base = Path(temporary)
    root = base / 'root'
    root.mkdir()
    nested = root / 'nested space'
    nested.mkdir()
    file = nested / 'sample.txt'
    file.write_text('hello')
    (root / '.hidden').write_text('hidden')
    mru = FzfMru(base / 'mru')
    # Fish's pwd | sha1sum key and newline-delimited relative path format.
    cache = mru.path('dirs', root)
    assert cache.name == hashlib.sha1(f'{root}\n'.encode()).hexdigest()
    cache.write_text('nested space\nmissing\n')
    picker = PathPicker(root, PROVIDERS[0], mru=mru)
    picker.show()
    wait(lambda: not picker.scanning)
    assert picker.entries == ['nested space'], picker.entries
    QTest.keyClicks(picker.query, 'ntsp')
    assert picker.results.count() == 1
    picker.choose(True)
    assert picker.destination == nested and picker.new_tab
    assert cache.read_text() == 'nested space\nmissing\n'

    picker = PathPicker(root, PROVIDERS[1], mru=mru)
    wait(lambda: not picker.scanning)
    assert 'nested space/sample.txt' in picker.entries
    assert '.hidden' not in picker.entries
    picker.query.setText('smtxt')
    picker.choose()
    assert picker.destination == file
    assert mru.read('files', root)[0] == 'nested space/sample.txt'
    # A new shell/backend object sees the same selection; cwd scopes are independent.
    assert FzfMru(base / 'mru').read('files', root) == ['nested space/sample.txt']
    assert mru.read('files', nested) == []

    picker = PathPicker(root, PROVIDERS[3], mru=mru)
    wait(lambda: not picker.scanning)
    assert '.hidden' in picker.entries
    picker.reject()
    assert picker.destination is None

    # Real Hammerspoon launch PATH: fd lives in Nix, outside the GUI PATH.
    with patch.dict(os.environ, {'PATH': '/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin'}):
        picker = PathPicker(root, PROVIDERS[1], mru=mru)
        wait(lambda: not picker.scanning)
        assert not picker.error, picker.error
        assert Path(picker.command[0]).is_absolute(), picker.command
        assert 'nested space/sample.txt' in picker.entries
        assert picker.results.count() > 0
        picker.reject()

    # A non-fd producer reuses the same UI, and NUL framing preserves newlines.
    odd = root / 'line\nbreak.txt'
    odd.touch()
    command = (sys.executable, '-c',
               "import sys; sys.stdout.buffer.write(b'line\\nbreak.txt\\0nested space/sample.txt\\0')")
    custom = PathProvider('custom', 'Custom', command, '')
    picker = PathPicker(root, custom, mru=mru)
    wait(lambda: not picker.scanning)
    assert picker.entries == ['line\nbreak.txt', 'nested space/sample.txt'], picker.entries
    picker.choose()
    assert picker.destination == odd
    assert mru.read('custom', root) == []

    # Providers are replaceable; subprocess arguments stay literal (no shell).
    custom = PathProvider('custom', 'Custom', ('/no/such/program',), '')
    picker = PathPicker(root, custom, mru=mru)
    wait(lambda: not picker.scanning)
    assert picker.error
    picker.reject()

    with patch('pip_rot.PathPicker') as factory:
        window = Browser([root], record_history=False)
        window.show()
        chosen = factory.return_value
        chosen.exec.return_value = True
        chosen.destination = file
        chosen.new_tab = False
        window.pick_path(PROVIDERS[1])
        wait(lambda: window.current().selected() == file)
        assert window.current().root == nested
        chosen.new_tab = True
        chosen.destination = root
        window.pick_path(PROVIDERS[0])
        assert window.tabs.count() == 2 and window.current().root == root
        shortcuts = [action.shortcut().toString() for action in window.findChildren(type(window.tree_parent_action))]
        for provider in PROVIDERS:
            assert shortcuts.count(provider.shortcut) == 1, (provider.shortcut, shortcuts)
        window.close()
    # Cancelling a running producer kills it rather than leaving orphaned scans.
    slow = PathProvider('slow', 'Slow', ('/bin/sleep', '30'), '')
    picker = PathPicker(root, slow, mru=mru)
    picker.reject()
    assert picker.process.state() == picker.process.ProcessState.NotRunning
print('Path picker tests passed')
