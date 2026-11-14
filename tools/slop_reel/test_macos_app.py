"""Desktop lifecycle contracts without requiring OpenGL or a desktop session."""

import os
import subprocess
import sys
from pathlib import Path


def test_desktop_file_events_and_quit(tmp_path):
    script = r"""
import sys
from pathlib import Path
from unittest.mock import patch
from PySide6.QtCore import Qt, QMimeData, QPointF, QUrl, Signal, QTimer
from PySide6.QtGui import QFileOpenEvent, QDropEvent, QKeyEvent
from PySide6.QtCore import QEvent
from PySide6.QtWidgets import QMainWindow
from macos_app import Application

class Review(QMainWindow):
    review_closed = Signal(object)
    def __init__(self, path):
        super().__init__()
        self.path, self.closed = path, False
    def closeEvent(self, event):
        self.closed = True
        self.review_closed.emit(self)
        event.accept()

root = Path(sys.argv[1])
first = root / 'first video.mp4'
second = root / 'second video.mov'
first.touch()
second.touch()
app = Application([], window_factory=Review)
app.setQuitOnLastWindowClosed(False)
# A Dock launch needs a usable welcome screen, not an argument-parser error.
app.start()
app.processEvents()
assert app.welcome.isVisible()
assert not app.windows
# Open With in a running app, and reopening the same file retains the review.
app.sendEvent(app, QFileOpenEvent(str(first)))
one = app.windows[0]
assert one.path == first.resolve() and not app.welcome.isVisible()
app.sendEvent(app, QFileOpenEvent(QUrl.fromLocalFile(str(first))))
assert app.windows == [one]
# One picker selection can open multiple videos without duplicating reviews.
with patch('macos_app.QFileDialog.getOpenFileNames', return_value=([str(first), str(second)], '')):
    app.choose_videos()
assert len(app.windows) == 2
two = app.windows[1]
assert two.path == second.resolve()
with patch('macos_app.QMessageBox.warning') as warning:
    app.open_paths([root / 'missing.mp4'])
    assert warning.call_count == 1 and len(app.windows) == 2
# Drag/drop paths remain literal, including spaces.
mime = QMimeData()
mime.setUrls([QUrl.fromLocalFile(str(first))])
drop = QDropEvent(QPointF(0,0), Qt.DropAction.CopyAction, mime, Qt.MouseButton.LeftButton, Qt.KeyboardModifier.NoModifier)
app.welcome.dropEvent(drop)
assert drop.isAccepted() and len(app.windows) == 2
# File-menu actions are present on each review.
file_menu = one.menuBar().actions()[0].menu()
assert [action.text() for action in file_menu.actions()] == ['Open Video…', 'Close Window', 'Quit Slop Reel']
# Closing a window releases it from the application; a later open makes a new one.
one.close()
assert one.closed and app.windows == [two]
app.open_paths([first])
three = app.windows[1]
assert three is not one
# Startup Finder events queue until Qt startup, and merge with CLI paths.
app.close_reviews()
assert two.closed and three.closed and not app.windows
app.ready = False
app.sendEvent(app, QFileOpenEvent(str(first)))
assert app.pending == [str(first)] and not app.windows
app.start([first, second])
app.processEvents()
assert [w.path for w in app.windows] == [first.resolve(), second.resolve()]
remaining = list(app.windows)
# F9 through the actual event loop quits all windows, including with multiple
# reviews open. aboutToQuit must close each window, not merely stop Qt's loop.
def press_quit():
    event = QKeyEvent(QEvent.Type.KeyPress, Qt.Key.Key_F9, Qt.KeyboardModifier.NoModifier)
    app.sendEvent(remaining[0], event)
QTimer.singleShot(0, press_quit)
QTimer.singleShot(3000, lambda: sys.exit('F9 did not quit'))
app.exec()
assert all(w.closed for w in remaining) and not app.windows
print('PASS: startup and running file events, deduplication, picker, drop, menus, F9 and multi-window cleanup')
"""
    result = subprocess.run(
        [sys.executable, "-c", script, str(tmp_path)],
        cwd=Path(__file__).parent,
        env={**os.environ, "QT_QPA_PLATFORM": "offscreen"},
        check=False,
        capture_output=True,
        text=True,
        timeout=20,
    )
    assert result.returncode == 0, result.stdout + result.stderr
