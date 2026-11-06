"""Immediate folder creation, inline rename, and contextual launcher requests."""
import json
import os
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer, Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QLineEdit

from pip_rot import Browser
from restart import RestartController, request_path


def pump():
    loop = QEventLoop()
    QTimer.singleShot(50, loop.quit)
    loop.exec()


def wait_editor():
    for _ in range(100):
        pump()
        editor = app.focusWidget()
        if isinstance(editor, QLineEdit) and editor is not window.location:
            return editor
    raise AssertionError('No inline editor')


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    parent = root / 'inside'
    parent.mkdir()
    (parent / 'New Folder').mkdir()
    file = parent / 'file.txt'
    file.write_text('untouched')
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        for _ in range(5):
            pump()
        tab = window.current()
        tab.tree.setCurrentIndex(tab.model.index(str(parent)))
        tab.tree.setFocus()
        QTest.keyClick(tab.tree, Qt.Key.Key_N, Qt.KeyboardModifier.ControlModifier | Qt.KeyboardModifier.ShiftModifier)
        editor = wait_editor()
        assert editor.text() == 'New Folder~2'
        assert (parent / 'New Folder~2').is_dir()
        assert tab.tree.isExpanded(tab.model.index(str(parent)))
        editor.setText('Renamed')
        QTest.keyClick(editor, Qt.Key.Key_Return)
        for _ in range(5):
            pump()
        assert (parent / 'Renamed').is_dir()
        assert file.read_text() == 'untouched'
        # File selection creates beside that file, rather than inside the root.
        tab.tree.setCurrentIndex(tab.model.index(str(file)))
        tab.tree.setFocus()
        window.new_directory()
        editor = wait_editor()
        assert editor.text() == 'New Folder~2'
        QTest.keyClick(editor, Qt.Key.Key_Escape)
        assert (parent / 'New Folder~2').is_dir()
        controller = RestartController(window)
        window.restart_controller = controller
        controller.timer.stop()
        tab.tree.setCurrentIndex(tab.model.index(str(parent)))
        paths = list(map(str, window.selected_paths()))
        def request(command, selected=paths):
            request_path().write_text(json.dumps(dict(version=1, pid=os.getpid(), command=command,
                                                       paths=selected, directory=str(root))))
            controller.poll()
            for _ in range(5):
                pump()
        # The request reaches the native action using the frozen picker context.
        with patch.object(window, 'new_directory') as create:
            request('new-folder-inside')
            create.assert_called_once()
        with patch.object(window, 'gather_selected') as gather:
            request('new-folder-with-selection')
            gather.assert_called_once()
        with patch.object(window, 'new_path') as nested:
            request('new-path')
            nested.assert_called_once()
        request('edit-directory-notes')
        assert tab.tree.notes.editing == str(parent)
        assert app.focusWidget() is tab.tree.notes.input
        assert not (parent / '.rotten.md').exists()
        tab.tree.notes.input.setPlainText('# Launcher notes')
        count = window.tabs.count()
        QTest.keyClick(tab.tree.notes.input, Qt.Key.Key_Return, Qt.KeyboardModifier.ControlModifier)
        assert window.tabs.count() == count  # Save must beat the window's new-tab shortcut.
        assert (parent / '.rotten.md').read_text() == '# Launcher notes'
        assert tab.tree.notes.editing is None
        with patch.object(window, 'new_directory') as create:
            request('new-folder-inside', [str(file)])
            create.assert_not_called()
        assert 'Selection changed' in window.statusBar().currentMessage()
        window.close()
print('PASS: immediate folder creation, collision numbering, selected-folder/file semantics, inline rename, launcher commands and stale context rejection')
