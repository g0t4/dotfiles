"""Selection context, native actions, and path handling with temporary files."""
import json
import os
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QItemSelectionModel, QTimer
from PySide6.QtWidgets import QApplication

from action_context import context_path
from pip_rot import Browser


def pump():
    loop = QEventLoop()
    QTimer.singleShot(200, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    nested = root / "nested $ ' dir"
    nested.mkdir()
    file = root / 'hello\nworld.txt'
    file.write_text('clippy!\n')
    other = root / 'other.txt'
    other.write_text('other')
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        pump()
        tab = window.current()
        tab.tree.setCurrentIndex(tab.model.index(str(file)))
        context = json.loads(context_path().read_text())
        assert context['pid'] == os.getpid()
        assert context['paths'] == [str(file)]
        assert context['window_title'] == window.windowTitle()
        assert context_path().stat().st_mode & 0o777 == 0o600
        window.copy_paths()
        assert app.clipboard().text() == str(file)
        window.copy_contents()
        assert app.clipboard().text() == 'clippy!\n'
        tab.tree.selectionModel().select(tab.model.index(str(other)), QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows)
        assert set(json.loads(context_path().read_text())['paths']) == {str(file), str(other)}
        tab.tree.setCurrentIndex(tab.model.index(str(nested)))
        with patch('pip_rot.subprocess.Popen') as popen:
            window.open_terminal()
            assert popen.call_args.args[0] == ['/usr/bin/open', '-a', 'iTerm', str(nested)]
        with patch('pip_rot.QInputDialog.getText', return_value=('new/deep', True)):
            window.new_nested_directory()
        pump()
        assert (nested / 'new/deep').is_dir()
        assert tab.selected() == nested / 'new/deep'
        tab.tree.setCurrentIndex(tab.model.index(str(nested)))
        with patch('pip_rot.QInputDialog.getText', return_value=('../escape', True)), patch('pip_rot.QMessageBox.warning') as warning:
            window.new_nested_directory()
            warning.assert_called_once()
        assert not (root / 'escape').exists()
        window.add_tab(nested)
        assert json.loads(context_path().read_text())['directory'] == str(nested)
        window.close()
        assert not context_path().exists()
print('PASS: process/window context, multi-selection, unusual filenames, clipboard, Terminal args, nested creation and selection, traversal rejection, cleanup')
