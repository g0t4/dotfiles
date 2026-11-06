"""Exercise navigation history against real temporary directories."""
import tempfile
from pathlib import Path
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer
from PySide6.QtWidgets import QApplication

from pip_rot import Browser


def pump():
    loop = QEventLoop()
    QTimer.singleShot(150, loop.quit)
    loop.exec()


def visit(window, path):
    window.location.setText(str(path))
    window.go_location()
    pump()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    a, b, c = [root / name for name in ('a', 'b', 'c')]
    for folder in (a, b, c):
        folder.mkdir()
    for number in range(100):
        (b / f"file-{number:03}.txt").touch()
    window = Browser([str(root)])
    window.show()
    pump()
    tab = window.current()
    tab.tree.setCurrentIndex(tab.model.index(str(b)))
    assert not window.back_action.isEnabled()
    tab.tree.setCurrentIndex(tab.model.index(str(a)))
    window.open_selected()
    pump()
    assert tab.root == a and window.tabs.count() == 1
    window.move_history(-1)
    pump()
    assert tab.root == root and tab.selected() == a
    tab.tree.setCurrentIndex(tab.model.index(str(b)))
    visit(window, a)
    visit(window, b)
    assert window.current() is tab and window.tabs.count() == 1
    assert window.back_action.isEnabled() and not window.forward_action.isEnabled()
    tab.tree.verticalScrollBar().setValue(40)
    scroll = tab.tree.verticalScrollBar().value()
    assert scroll > 0
    window.back_action.trigger()
    pump()
    assert tab.root == a and window.forward_action.isEnabled()
    window.forward_action.trigger()
    pump()
    assert tab.root == b and tab.tree.verticalScrollBar().value() == scroll
    window.back_action.trigger()
    pump()
    window.back_action.trigger()
    pump()
    assert tab.root == root and tab.selected() == b
    window.forward_action.trigger()
    assert tab.root == a
    visit(window, c)
    assert [entry.root for entry in tab.history] == [root, a, c]
    assert not window.forward_action.isEnabled()
    visit(window, c)
    assert len(tab.history) == 3
    window.add_tab(b)
    assert not window.back_action.isEnabled() and not window.forward_action.isEnabled()
    window.tabs.setCurrentIndex(0)
    assert window.back_action.isEnabled()
    window.go_parent()
    pump()
    assert tab.root == root and tab.selected() == c
    window.move_history(-1)
    assert tab.root == c
    window.move_history(-1)
    assert tab.root == a
    c.rmdir()
    with patch('pip_rot.QMessageBox.warning') as warning:
        window.move_history(1)
        warning.assert_called_once()
    assert tab.root == a and tab.history_index == 1
    movie = b / 'file-000.txt'
    window.add_path(movie, True)
    pump()
    count = window.tabs.count()
    with patch('file_history.QDesktopServices.openUrl', return_value=True) as open_url, patch('file_history.FileHistory') as file_history:
        window.open_selected()
        assert open_url.call_args.args[0].toLocalFile() == str(movie)
        file_history.return_value.record.assert_called_once_with(movie, source='pip-rot')
        file_history.return_value.record.reset_mock()
        window.current().open_file(window.current().model.index(str(movie)))
        file_history.return_value.record.assert_called_once_with(str(movie), source='pip-rot')
    assert window.tabs.count() == count
    window.close()
print('PASS: back/forward, selection restore, branching, duplicate suppression, tab isolation, parent history, missing directory')
