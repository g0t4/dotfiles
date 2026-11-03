"""Rename through the real Qt delegate, including Escape and editing shortcuts."""
import json
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer, Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QLineEdit

from action_context import context_path
from pip_rot import Browser


def pump():
    loop = QEventLoop()
    QTimer.singleShot(150, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    original = root / 'old.txt'
    original.write_text('keep contents')
    existing = root / 'existing.txt'
    existing.write_text('keep existing')
    folder = root / 'folder'
    folder.mkdir()
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        pump()
        tab = window.current()
        tab.tree.setCurrentIndex(tab.model.index(str(original)))
        tab.tree.setFocus()
        QTest.keyClick(tab.tree, Qt.Key.Key_R, Qt.KeyboardModifier.ControlModifier)
        pump()
        editor = app.focusWidget()
        assert isinstance(editor, QLineEdit)
        editor.selectAll()
        QTest.keyClicks(editor, 'new name.txt')
        assert window.preview.process is None, 'Space in an editor must not open preview'
        QTest.keyClick(editor, Qt.Key.Key_Return)
        pump()
        renamed = root/'new name.txt'
        assert renamed.read_text() == 'keep contents' and not original.exists()
        assert tab.selected() == renamed
        assert json.loads(context_path().read_text())['paths'] == [str(renamed)], context_path().read_text()
        window.rename_selected()
        pump()
        editor = app.focusWidget()
        assert isinstance(editor, QLineEdit)
        editor.setText('cancelled.txt')
        QTest.keyClick(editor, Qt.Key.Key_Escape)
        pump()
        assert renamed.exists() and not (root/'cancelled.txt').exists()
        # Collision must preserve both files and report the failed rename.
        assert not tab.model.setData(tab.model.index(str(renamed)), 'existing.txt')
        assert renamed.read_text() == 'keep contents' and existing.read_text() == 'keep existing'
        assert 'Could not rename' in window.statusBar().currentMessage()
        assert not tab.model.setData(tab.model.index(str(renamed)), '../outside.txt')
        tab.tree.setCurrentIndex(tab.model.index(str(folder)))
        window.rename_selected()
        pump()
        editor = app.focusWidget()
        assert isinstance(editor, QLineEdit)
        editor.setText('renamed folder')
        QTest.keyClick(editor, Qt.Key.Key_Return)
        pump()
        assert (root/'renamed folder').is_dir() and not folder.exists()
        tab.tree.clearSelection()
        window.rename_selected()
        assert not isinstance(app.focusWidget(), QLineEdit)
        window.add_tab(root)
        tab = window.current()
        window.focus_location()
        QTest.keyClick(window.location, Qt.Key.Key_F8)
        pump()
        assert window.tabs.count() == 1 and app.focusWidget() is window.current().tree
        QTest.keyClick(window.current().tree, Qt.Key.Key_F9)
        pump()
        assert not window.isVisible()
print('PASS: Command R inline rename, spaces, contents/selection/context preserved, Escape, collisions, invalid paths, folder rename, explicit selection, F8 tab close/focus and F9 window close')
