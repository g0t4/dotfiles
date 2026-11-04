"""Real inline creation editor plus conservative path conversion boundaries."""
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer, Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QLineEdit

from path_creation import finish_empty_folder
from pip_rot import Browser


def pump():
    loop = QEventLoop()
    QTimer.singleShot(50, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        for _ in range(5):
            pump()
        tab = window.current()
        def new_editor():
            tab.tree.clearSelection()
            tab.tree.setCurrentIndex(tab.model.index(str(root)))
            tab.tree.setFocus()
            window.new_directory()
            for _ in range(100):
                pump()
                editor = app.focusWidget()
                if isinstance(editor, QLineEdit) and editor is not window.location:
                    return editor
            raise AssertionError('No editor')
        def commit(editor, text):
            editor.setText(text)
            QTest.keyClick(editor, Qt.Key.Key_Return)
            for _ in range(10):
                pump()
        editor = new_editor()
        commit(editor, 'drafts/my notes.md')
        assert (root / 'drafts/my notes.md').is_file()
        assert not (root / 'New Folder').exists()
        assert tab.selected() == root / 'drafts/my notes.md'
        assert tab.model.path_edit_source is None
        editor = new_editor()
        commit(editor, 'more/nested/')
        assert (root / 'more/nested').is_dir()
        assert not (root / 'New Folder').exists()
        assert tab.selected() == root / 'more/nested'
        # Cancel disarms path behavior: later ordinary rename cannot use slash.
        editor = new_editor()
        QTest.keyClick(editor, Qt.Key.Key_Escape)
        pump()
        temporary = root / 'New Folder'
        assert temporary.is_dir() and tab.model.path_edit_source is None
        assert not tab.model.setData(tab.model.index(str(temporary)), 'other/path/')
        assert temporary.is_dir()
        # A destination collision keeps both original content and temporary folder.
        (root / 'existing.txt').write_text('precious')
        editor = new_editor()
        commit(editor, 'existing.txt/')
        assert (root / 'existing.txt').read_text() == 'precious'
        assert (root / 'New Folder~2').is_dir()
        # The temporary directory gaining contents invalidates path semantics.
        editor = new_editor()
        fresh = Path(tab.model.filePath(tab.tree.currentIndex()))
        (fresh / 'keep').write_text('keep')
        commit(editor, 'no/way.txt')
        assert (fresh / 'keep').read_text() == 'keep'
        assert not (root / 'no').exists()
        window.close()
    # Standalone safety checks include symlink escape, self nesting and traversal.
    source = root / 'temporary'
    source.mkdir()
    for name in ('../outside/', '/absolute/', 'temporary/inside/', './', 'bad\0name/'):
        try:
            finish_empty_folder(source, name)
            raise AssertionError(name)
        except (ValueError, OSError):
            assert source.is_dir()
    with tempfile.TemporaryDirectory() as outside:
        (root / 'escape').symlink_to(outside, target_is_directory=True)
        try:
            finish_empty_folder(source, 'escape/no.txt')
            raise AssertionError('followed escaping symlink')
        except ValueError:
            assert not (Path(outside) / 'no.txt').exists()
    (source / 'contents').write_text('preserved')
    try:
        finish_empty_folder(source, 'nested/result/')
        raise AssertionError('converted nonempty folder')
    except ValueError:
        assert (source / 'contents').read_text() == 'preserved'
print('PASS: inline file/directory paths, reveal, Escape disarming, collisions, nonempty protection, traversal/self-nesting/symlink escape rejection')
