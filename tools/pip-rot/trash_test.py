"""Use a fake trash executable to verify intent, arguments, and asynchronous handling."""
import json
import os
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer, Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication

from pip_rot import Browser, finder_trash_executable


def pump():
    loop = QEventLoop()
    QTimer.singleShot(150, loop.quit)
    loop.exec()


with patch.dict(os.environ, {"PATH": "/usr/bin:/bin"}):
    assert finder_trash_executable() == '/opt/homebrew/bin/trash'

app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    file = root / "video $ ' name.txt"
    file.touch()
    log = root / 'args.json'
    fake = root / 'trash'
    fake.write_text(f'#!{os.sys.executable}\nimport json, sys\nfrom pathlib import Path\nPath({str(log)!r}).write_text(json.dumps(sys.argv[1:]))\n')
    fake.chmod(0o700)
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        pump()
        tab = window.current()
        tab.tree.clearSelection()
        with patch('pip_rot.finder_trash_executable', return_value=str(fake)):
            window.trash_selected()
            assert not window.trash_processes and not log.exists()
            tab.tree.setCurrentIndex(tab.model.index(str(file)))
            window.focus_location()
            QTest.keyClick(window.location, Qt.Key.Key_Backspace, Qt.KeyboardModifier.ControlModifier)
            pump()
            assert not log.exists(), 'text-field shortcut must not trash selected files'
            tab.tree.setFocus()
            pump()
            QTest.keyClick(tab.tree, Qt.Key.Key_Backspace, Qt.KeyboardModifier.ControlModifier)
            for _ in range(30):
                pump()
                if not window.trash_processes:
                    break
        assert json.loads(log.read_text()) == ['-F', str(file)]
        assert file.exists(), 'test executable must not trash anything'
        assert window.trash_action.isEnabled()
        window.close()
print('PASS: no-selection refusal, literal argument handling, Finder Put Back flag, async completion')
