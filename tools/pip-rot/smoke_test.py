"""Run with QT_QPA_PLATFORM=offscreen uv run --project tools/pip-rot python tools/pip-rot/smoke_test.py."""
import tempfile
from pathlib import Path

from PySide6.QtCore import QEventLoop, QTimer
from PySide6.QtWidgets import QApplication

from pip_rot import Browser


def wait_for_files():
    loop = QEventLoop()
    QTimer.singleShot(500, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    child = root / "nested $ ' movie folder"
    child.mkdir()
    movie = child / 'movie.mp4'
    movie.touch()
    (root / '.hidden').touch()
    window = Browser([str(root)])
    wait_for_files()
    tab = window.current()
    assert tab.root == root
    assert tab.model.rowCount(tab.tree.rootIndex()) == 1
    tab.tree.setCurrentIndex(tab.model.index(str(child)))
    window.tab_selected()
    assert window.tabs.count() == 2 and window.current().root == child
    window.add_path(movie, True)
    wait_for_files()
    assert window.current().selected() == movie
    assert not window.current().model.isReadOnly()
    window.hidden_action.setChecked(True)
    window.toggle_hidden()
    window.close_tab(2)
    assert window.tabs.count() == 2
    window.go_parent()
    assert window.current().root == root
    wait_for_files()
    assert window.current().model.rowCount(window.current().tree.rootIndex()) == 2
    window.cycle_tab(-1)
    assert window.tabs.currentIndex() == 0
    window.close()
print('PASS: tree loading, scoped tabs, reveal selection, hidden files, closing, parent navigation, tab switching')
