"""Warnings stay prominent without stealing keyboard focus; expiry resets styling."""
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QItemSelectionModel, QTimer
from PySide6.QtWidgets import QApplication

from pip_rot import Browser


def pump(milliseconds=150):
    loop = QEventLoop()
    QTimer.singleShot(milliseconds, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    one, two = root/'one.txt', root/'two.txt'
    one.touch()
    two.touch()
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        pump()
        tree = window.current().tree
        model = window.current().model
        tree.setCurrentIndex(model.index(str(one)))
        tree.selectionModel().select(model.index(str(two)), QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows)
        tree.setFocus()
        focus = app.focusWidget()
        window.duplicate_selected()
        status = window.statusBar()
        assert status.property('warning') is True
        assert status.currentMessage().startswith('⚠ Select exactly one')
        assert app.focusWidget() is focus and app.activeModalWidget() is None
        assert not window.transfers.busy
        status.showMessage('Working…')
        assert status.property('warning') is False and status.styleSheet() == status.NORMAL_STYLE
        status.showMessage('Test expiration', 1, warning=True)
        pump(40)
        assert not status.currentMessage() and status.property('warning') is False
        assert status.styleSheet() == status.NORMAL_STYLE
        status.showMessage('Files are identical', success=True)
        assert status.property('success') is True
        assert status.styleSheet() == status.SUCCESS_STYLE
        assert status.currentMessage() == '✓ Files are identical'
        assert app.focusWidget() is focus
        status.showMessage('Working…')
        assert status.property('success') is False
        assert status.styleSheet() == status.NORMAL_STYLE
        status.showMessage('Success expires', 1, success=True)
        pump(40)
        assert status.property('success') is False and status.styleSheet() == status.NORMAL_STYLE
        status.showMessage('Success clears', success=True)
        status.clearMessage()
        assert status.property('success') is False and status.styleSheet() == status.NORMAL_STYLE
        status.showMessage('Another warning', warning=True)
        status.clearMessage()
        assert status.property('warning') is False
        window.close()
print('PASS: duplicate rejection uses warning band, no focus/modal interruption, routine updates/expiry/clear reset style')
