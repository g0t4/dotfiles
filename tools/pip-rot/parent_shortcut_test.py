"""Shift+P navigates only from the tree; lowercase search and editors survive."""
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer, Qt, QEvent
from PySide6.QtTest import QTest
from PySide6.QtGui import QKeyEvent
from PySide6.QtWidgets import QApplication, QLineEdit

from pip_rot import Browser


def pump():
    loop = QEventLoop()
    QTimer.singleShot(100, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    child = root / 'child'
    child.mkdir()
    for name in ('apple.txt', 'peach.txt'):
        (child / name).touch()
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(child)])
        window.show()
        window.activateWindow()
        pump()
        tab = window.current()
        tab.tree.setCurrentIndex(tab.model.index(str(child / 'apple.txt')))
        tab.tree.setFocus()
        QTest.keyClick(tab.tree, Qt.Key.Key_P)
        pump()
        assert tab.root == child and tab.selected().name == 'peach.txt'
        QTest.keyClick(tab.tree, Qt.Key.Key_P, Qt.KeyboardModifier.ShiftModifier)
        pump()
        assert tab.root == root and window.tabs.count() == 1
        window.move_history(-1)
        pump()
        assert tab.root == child
        window.focus_location()
        window.location.clear()
        app.sendEvent(window.location, QKeyEvent(QEvent.Type.KeyPress, Qt.Key.Key_P, Qt.KeyboardModifier.ShiftModifier, 'P'))
        assert window.location.text() == 'P' and tab.root == child, (window.location.text(), tab.root)
        tab.tree.setCurrentIndex(tab.model.index(str(child / 'apple.txt')))
        tab.tree.setFocus()
        window.rename_selected()
        pump()
        editor = app.focusWidget()
        assert isinstance(editor, QLineEdit) and editor is not window.location
        editor.selectAll()
        app.sendEvent(editor, QKeyEvent(QEvent.Type.KeyPress, Qt.Key.Key_P, Qt.KeyboardModifier.ShiftModifier, 'P'))
        assert editor.text() == 'P' and tab.root == child
        QTest.keyClick(editor, Qt.Key.Key_Escape)
        window.add_tab(child)
        pump()
        QTest.keyClick(window.current().tree, Qt.Key.Key_P, Qt.KeyboardModifier.ShiftModifier)
        pump()
        assert window.current().root == root and tab.root == child
        window.close()
print('PASS: tree-only Shift+P parent navigation, history, lowercase search, text editor isolation and new tabs')
