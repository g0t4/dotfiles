"""Tree parent/sibling keys preserve root/history, search and text editors."""
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer, Qt, QEvent
from PySide6.QtGui import QKeyEvent
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QLineEdit

from pip_rot import Browser


def pump():
    loop = QEventLoop()
    QTimer.singleShot(100, loop.quit)
    loop.exec()


def punctuation(widget, key, text):
    app.sendEvent(widget, QKeyEvent(QEvent.Type.KeyPress, key, Qt.KeyboardModifier.ShiftModifier, text))
    app.sendEvent(widget, QKeyEvent(QEvent.Type.KeyRelease, key, Qt.KeyboardModifier.ShiftModifier, text))
    pump()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    child = root / 'child'
    child.mkdir()
    branch = child / 'aaa-branch'
    branch.mkdir()
    (branch / 'deep.txt').touch()
    for name in ('apple.txt', 'peach.txt'):
        (child / name).touch()
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        pump()
        tab = window.current()
        for path in (child, branch):
            tab.tree.expand(tab.model.index(str(path)))
            pump()
        history = len(tab.history)
        tab.tree.setCurrentIndex(tab.model.index(str(child / 'apple.txt')))
        tab.tree.setFocus()
        QTest.keyClick(tab.tree, Qt.Key.Key_P)
        pump()
        assert tab.selected() == child / 'peach.txt'
        QTest.keyClick(tab.tree, Qt.Key.Key_P, Qt.KeyboardModifier.ShiftModifier)
        pump()
        assert tab.selected() == child and tab.root == root
        assert tab.tree.isExpanded(tab.model.index(str(child)))
        # First sibling (a folder) has expanded descendants; skip them.
        tab.tree.setCurrentIndex(tab.model.index(str(branch)))
        punctuation(tab.tree, Qt.Key.Key_Greater, '>')
        assert tab.selected() == child / 'apple.txt', tab.selected()
        punctuation(tab.tree, Qt.Key.Key_Less, '<')
        assert tab.selected() == branch
        punctuation(tab.tree, Qt.Key.Key_Less, '<')
        assert tab.selected() == branch, 'no wrap before first sibling'
        tab.tree.setCurrentIndex(tab.model.index(str(child / 'peach.txt')))
        punctuation(tab.tree, Qt.Key.Key_Greater, '>')
        assert tab.selected() == child / 'peach.txt', 'no wrap after last sibling'
        tab.tree.setCurrentIndex(tab.model.index(str(child)))
        QTest.keyClick(tab.tree, Qt.Key.Key_P, Qt.KeyboardModifier.ShiftModifier)
        assert tab.selected() == child and tab.root == root, 'hidden root is the boundary'
        assert len(tab.history) == history
        window.focus_location()
        window.location.clear()
        for key, text in ((Qt.Key.Key_P, 'P'), (Qt.Key.Key_Less, '<'), (Qt.Key.Key_Greater, '>')):
            punctuation(window.location, key, text)
        assert window.location.text() == 'P<>' and tab.root == root
        tab.tree.setCurrentIndex(tab.model.index(str(child / 'apple.txt')))
        tab.tree.setFocus()
        window.rename_selected()
        pump()
        editor = app.focusWidget()
        assert isinstance(editor, QLineEdit) and editor is not window.location
        editor.selectAll()
        for key, text in ((Qt.Key.Key_P, 'P'), (Qt.Key.Key_Less, '<'), (Qt.Key.Key_Greater, '>')):
            punctuation(editor, key, text)
        assert editor.text() == 'P<>' and tab.root == root
        QTest.keyClick(editor, Qt.Key.Key_Escape)
        # Root-up stays separate, using the existing Command+Up shortcut.
        QTest.keyClick(tab.tree, Qt.Key.Key_Up, Qt.KeyboardModifier.ControlModifier)
        pump()
        assert tab.root == root.parent
        window.move_history(-1)
        pump()
        assert tab.root == root
        window.add_tab(root)
        pump()
        second = window.current()
        second.tree.expand(second.model.index(str(child)))
        pump()
        second.tree.setCurrentIndex(second.model.index(str(child / 'peach.txt')))
        QTest.keyClick(second.tree, Qt.Key.Key_P, Qt.KeyboardModifier.ShiftModifier)
        pump()
        assert second.selected() == child and second.root == root
        window.close()
print('PASS: tree parent/sibling selection, expanded descendants skipped, boundaries, root/history unchanged, lowercase search, editor isolation, new tabs and Command Up root navigation')
