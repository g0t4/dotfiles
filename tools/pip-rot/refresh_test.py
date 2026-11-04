"""Refresh a deliberately stale model while preserving tree state."""
from pathlib import Path
import tempfile
import time
from unittest.mock import patch

from PySide6.QtCore import QItemSelectionModel, Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QFileSystemModel

from pip_rot import Browser

app = QApplication([])


def wait(predicate):
    deadline = time.monotonic() + 4
    while not predicate():
        assert time.monotonic() < deadline, 'tree did not finish loading'
        QTest.qWait(20)


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    nested = root / 'folder' / 'nested'
    nested.mkdir(parents=True)
    for number in range(100):
        (nested / f'{number:03}.txt').touch()
    with patch('action_context.Path.home', return_value=root):
        window = Browser([directory])
        window.show()
        window.activateWindow()
        tab = window.current()
        wait(lambda: tab.initial_selection_done)
        for path in [nested.parent, nested]:
            tab.tree.expand(tab.model.index(str(path)))
            wait(lambda path=path: tab.model.rowCount(tab.model.index(str(path))) > 0)
        selected = [nested / '020.txt', nested / '021.txt']
        tab.tree.setCurrentIndex(tab.model.index(str(selected[0])))
        tab.tree.selectionModel().select(tab.model.index(str(selected[1])),
            QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows)
        tab.tree.verticalScrollBar().setValue(12)
        scroll = tab.tree.verticalScrollBar().value()
        history = list(tab.history)
        old = tab.model
        # Disable watching so a real filesystem mutation leaves this model stale.
        old.setOption(QFileSystemModel.Option.DontWatchForChanges)
        created = nested / 'new.txt'
        created.touch()
        (nested / '099.txt').unlink()
        tab.tree.setFocus()
        QTest.qWait(20)
        QTest.keyClick(tab.tree, Qt.Key.Key_F5)
        wait(lambda: tab.model is not old and tab.refresh_state is None)
        assert tab.tree.isExpanded(tab.model.index(str(nested.parent)))
        assert tab.tree.isExpanded(tab.model.index(str(nested)))
        actual = {tab.model.filePath(i) for i in tab.tree.selectionModel().selectedRows(0)}
        assert actual == set(map(str, selected)), actual
        assert tab.selected() == selected[0]
        assert tab.tree.verticalScrollBar().value() == scroll
        assert tab.history == history
        assert tab.model.index(str(created)).isValid()
        assert not tab.model.index(str(nested / '099.txt')).isValid()
        assert tab.model.rowCount(tab.model.index(str(nested))) == 100
        # Connections survive model replacement; repeated refresh works too.
        window.refresh_current()
        wait(lambda: tab.refresh_state is None)
        assert tab.tree.isExpanded(tab.model.index(str(nested)))
        # Simulate missed watcher delivery for a completed drag/drop move.
        destination = root / 'destination'
        destination.mkdir()
        tab.model.setOption(QFileSystemModel.Option.DontWatchForChanges)
        source = selected[0]
        moved = destination / source.name
        source.rename(moved)
        window.transfer_finished([(source, moved, False)], [])
        wait(lambda: tab.refresh_state is None)
        assert not tab.model.index(str(source)).isValid()
        assert tab.model.index(str(moved)).isValid()
        assert tab.tree.isExpanded(tab.model.index(str(nested)))
        # A completion during an in-flight refresh schedules another fresh read.
        tab.refresh()
        window.transfer_finished([(selected[1], destination / selected[1].name, True)], [])
        assert tab.refresh_again
        wait(lambda: tab.refresh_state is None and not tab.refresh_again)
        log = (root / '.local/share/devtools/pip-rot.log').read_text()
        assert 'refresh-start' in log and 'refresh-finished' in log
        assert 'transfer-finished' in log
        assert 'loaded_rows=' in log and str(nested) in log
        window.close()
print('PASS: F5 reloads stale model, nested expansions, multi-selection, current row, scroll, history, repeated refresh')
