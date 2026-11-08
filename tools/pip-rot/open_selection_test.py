"""Multi-selection opens reach the default app together, with accepted-open history."""
from pathlib import Path
import tempfile
from types import SimpleNamespace
from unittest.mock import patch

from PySide6.QtCore import QItemSelectionModel, QEventLoop, QTimer
from PySide6.QtWidgets import QApplication

from file_history import open_tracked_files
from pip_rot import Browser

app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    paths = [root / 'first take.mp4', root / 'second "take".mp4']
    for path in paths:
        path.touch()
    with patch('file_history.subprocess.run', return_value=SimpleNamespace(returncode=0)) as opener, \
            patch('file_history.FileHistory') as history:
        assert open_tracked_files(paths)
        assert opener.call_args.args[0] == ['/usr/bin/open', *map(str, paths)]
        assert [call.args[0] for call in history.return_value.record.call_args_list] == paths
    with patch('file_history.subprocess.run', return_value=SimpleNamespace(returncode=1, stderr='failed')), \
            patch('file_history.FileHistory') as history:
        assert not open_tracked_files(paths)
        history.assert_not_called()
    with patch('file_history.subprocess.run', side_effect=OSError('unavailable')):
        assert not open_tracked_files(paths)
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        tab = window.current()
        for _ in range(20):
            loop = QEventLoop()
            QTimer.singleShot(25, loop.quit)
            loop.exec()
            if all(tab.model.index(str(path)).isValid() for path in paths):
                break
        selection = tab.tree.selectionModel()
        flags = QItemSelectionModel.SelectionFlag
        for path in paths:
            index = tab.model.index(str(path))
            assert index.isValid()
            selection.select(index, flags.Select | flags.Rows)
        selection.setCurrentIndex(index, flags.NoUpdate)
        with patch('pip_rot.open_tracked_files', return_value=True) as opener:
            window.open_selected()
            assert set(opener.call_args.args[0]) == set(paths)
            opener.assert_called_once()
            opener.reset_mock()
            tab.open_file(index)
            assert set(opener.call_args.args[0]) == set(paths)
            opener.assert_called_once()
        selection.clearSelection()
        selection.select(index, flags.Select | flags.Rows)
        with patch('pip_rot.open_tracked_files', return_value=True) as opener:
            window.open_selected()
            opener.assert_called_once_with([paths[-1]])
        window.close()
print('PASS: multi-selection keyboard/double-click, singleton, batch arguments, history, failed handoffs')
