"""Folder event delivery stays in-process and queues startup requests."""
from pathlib import Path
from unittest.mock import Mock
from PySide6.QtGui import QFileOpenEvent
from macos_app import Application

app = Application([])
app.open_paths = Mock()
app.sendEvent(app, QFileOpenEvent('/tmp/first folder'))
assert app.pending == [Path('/tmp/first folder')]
assert not app.open_paths.called
app.ready = True
app.sendEvent(app, QFileOpenEvent('/tmp/second folder'))
app.open_paths.assert_called_once_with([Path('/tmp/second folder')])
assert app.pending == [Path('/tmp/first folder')]
print('PASS: startup queued, subsequent folder delivered without spawning processes')
