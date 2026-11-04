"""New Folder with Selection moves real files and opens the inline editor."""
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QItemSelectionModel, QTimer, Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QLineEdit

from pip_rot import Browser
from transfers import GatherJob


def pump():
    loop = QEventLoop()
    QTimer.singleShot(50, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    (root / 'New Folder').mkdir()
    first = root / 'a file.txt'
    first.write_text('hello')
    second = root / 'subdir'
    second.mkdir()
    (second / 'nested').write_text('world')
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        for _ in range(5):
            pump()
        tab = window.current()
        tab.tree.clearSelection()
        flags = QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows
        for path in (first, second):
            tab.tree.selectionModel().select(tab.model.index(str(path)), flags)
        tab.tree.setFocus()
        window.gather_action.trigger()
        for _ in range(100):
            pump()
            if not window.transfers.busy and isinstance(app.focusWidget(), QLineEdit):
                break
        folder = root / 'New Folder~2'
        assert (folder / first.name).read_text() == 'hello'
        assert (folder / 'subdir/nested').read_text() == 'world'
        assert not first.exists() and not second.exists()
        editor = app.focusWidget()
        assert isinstance(editor, QLineEdit), type(editor)
        assert editor.text() == folder.name
        editor.setText('Collected')
        QTest.keyClick(editor, Qt.Key.Key_Return)
        for _ in range(10):
            pump()
        assert (root / 'Collected/a file.txt').read_text() == 'hello'
        assert (root / 'New Folder').is_dir()
        tab.tree.clearSelection()
        window.gather_selected()
        assert not window.transfers.busy
        assert 'same parent' in window.statusBar().currentMessage()
        # Invalid mixed-parent input must not create a folder or move anything.
        class Signal:
            def emit(self, folder, completed, errors):
                assert folder is None and not completed and errors
        class Owner:
            gathered = Signal()
        GatherJob(Owner(), [root / 'Collected', root / 'Collected/a file.txt']).run()
        # A failed later move keeps earlier items safely in the new folder.
        left, right = root / 'left', root / 'right'
        left.write_text('left')
        right.write_text('right')
        results = []
        class ResultSignal:
            def emit(self, *args):
                results.append(args)
        class ResultOwner:
            gathered = ResultSignal()
        from transfers import transfer_one
        def fail_second(source, target, copy):
            if source == right:
                raise OSError('simulated failure')
            transfer_one(source, target, copy)
        with patch('transfers.transfer_one', side_effect=fail_second):
            GatherJob(ResultOwner(), [left, right]).run()
        created, completed, errors = results.pop()
        assert len(completed) == 1 and errors
        assert (created / 'left').read_text() == 'left' and right.read_text() == 'right'
        # A failure before any moves removes only the empty new folder.
        with patch('transfers.plan_transfer', side_effect=OSError('preflight failure')):
            GatherJob(ResultOwner(), [right]).run()
        created, completed, errors = results.pop()
        assert errors and not completed and not created.exists() and right.exists()
        window.close()
print('gather tests passed')
