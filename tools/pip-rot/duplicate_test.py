"""Sibling numbering, collision races, real copying, and Command D inline editing."""
from pathlib import Path
import subprocess
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer, Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QLineEdit

from pip_rot import Browser
from transfers import copy_then_publish, duplicate_target, name_parts, rename_exclusive


def pump():
    loop = QEventLoop()
    QTimer.singleShot(150, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    source = root/'lesson 12.txt'
    source.write_text('original contents')
    assert duplicate_target(source).name == 'lesson 12~2.txt'
    occupied = root/'lesson 12~2.txt'
    occupied.write_text('existing copy')
    assert duplicate_target(source).name == 'lesson 12~3.txt'
    assert duplicate_target(occupied).name == 'lesson 12~3.txt'
    assert duplicate_target(root/'.env').name == '.env~2'
    assert duplicate_target(root/'unused~7.txt').name == 'unused~2.txt'
    assert duplicate_target(root/'archive.tar.gz').name == 'archive~2.tar.gz'
    folder = root/'folder.v2'
    folder.mkdir()
    (folder/'inside').write_text('folder data')
    assert duplicate_target(folder).name == 'folder.v2~2'
    # If another process takes the chosen name, reuse the staged copy with the next number.
    raced = False
    def competing_rename(src, target):
        global raced
        if not raced:
            raced = True
            target.write_text('competing file')
        return rename_exclusive(src, target)
    with patch('transfers.rename_exclusive', side_effect=competing_rename), patch('transfers.subprocess.run', wraps=subprocess.run) as copier:
        target = copy_then_publish(source, duplicate_target(source), lambda: duplicate_target(source))
        assert copier.call_count == 1
    assert target.name == 'lesson 12~4.txt' and target.read_text() == 'original contents'
    assert (root/'lesson 12~3.txt').read_text() == 'competing file'
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        pump()
        tab = window.current()
        tab.tree.setCurrentIndex(tab.model.index(str(source)))
        tab.tree.setFocus()
        QTest.keyClick(tab.tree, Qt.Key.Key_D, Qt.KeyboardModifier.ControlModifier)
        for _ in range(40):
            pump()
            if not window.transfers.busy and isinstance(app.focusWidget(), QLineEdit):
                break
        expected = root/'lesson 12~5.txt'
        assert expected.read_text() == source.read_text()
        editor = app.focusWidget()
        assert isinstance(editor, QLineEdit), type(editor)
        assert editor.text() == expected.name and editor.selectedText() == 'lesson 12~5'
        QTest.keyClick(editor, Qt.Key.Key_Escape)
        pump()
        assert expected.exists() and tab.selected() == expected
        assert occupied.read_text() == 'existing copy'
        # Duplicating a directory remains a sibling copy, not a merge.
        tab.tree.setCurrentIndex(tab.model.index(str(folder)))
        tab.tree.setFocus()
        window.duplicate_selected()
        for _ in range(40):
            pump()
            if not window.transfers.busy and (root/'folder.v2~2').exists():
                break
        assert (root/'folder.v2~2/inside').read_text() == 'folder data'
        editor = app.focusWidget()
        assert isinstance(editor, QLineEdit) and editor.selectedText() == 'folder.v2~2'
        QTest.keyClick(editor, Qt.Key.Key_Escape)
        pump()
        tab.tree.setCurrentIndex(tab.model.index(str(source)))
        tab.tree.setFocus()
        window.duplicate_selected()
        window.focus_location()
        for _ in range(40):
            pump()
            if not window.transfers.busy:
                break
        assert (root/'lesson 12~6.txt').exists()
        assert app.focusWidget() is window.location, 'background duplicate must not steal focus'
        tab.tree.clearSelection()
        window.duplicate_selected()
        assert not window.transfers.busy
        assert source.read_text() == 'original contents'
        assert name_parts(expected) == ('lesson 12~5', '.txt')
        window.close()
print('PASS: ~N naming, numbered copies, archives/dotfiles/folders, atomic collision retry without recopy, Command D, inline basename edit, Escape keeps copy, originals unchanged')
