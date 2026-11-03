"""Preview dispatch, keyboard focus, switching, and helper cleanup."""
import json
from pathlib import Path
import sys
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer, Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication

from pip_rot import Browser
from preview import PreviewController, preview_command


def pump():
    loop = QEventLoop()
    QTimer.singleShot(120, loop.quit)
    loop.exec()


def until(predicate):
    for _ in range(40):
        pump()
        if predicate():
            return
    raise AssertionError('Preview state did not settle')


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    first, second = root / "one $ ' file.txt", root / 'two.txt'
    first.touch()
    second.touch()
    helper = root / 'helper.py'
    log = root / 'calls.jsonl'
    helper.write_text('import json,sys,time\n'
                      f'with open({str(log)!r},"a") as f: f.write(json.dumps(sys.argv[1:])+"\\n")\n'
                      'time.sleep(60)\n')
    assert preview_command([first]) == ['/usr/bin/qlmanage', '-p', str(first)]
    with patch('action_context.Path.home', return_value=root), patch('preview.preview_command', side_effect=lambda paths: [sys.executable, str(helper), *map(str, paths)]):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        pump()
        tab = window.current()
        tab.tree.clearSelection()
        window.preview_selected()
        assert window.preview.process is None
        tab.tree.setCurrentIndex(tab.model.index(str(first)))
        window.focus_location()
        QTest.keyClick(window.location, Qt.Key.Key_Space)
        assert window.preview.process is None
        tab.tree.setFocus()
        pump()
        QTest.keyClick(tab.tree, Qt.Key.Key_Space)
        until(lambda: log.exists())
        assert json.loads(log.read_text().splitlines()[0]) == [str(first)]
        QTest.keyClick(tab.tree, Qt.Key.Key_Space)
        until(lambda: window.preview.process is None)
        window.preview_selected()
        until(lambda: len(log.read_text().splitlines()) == 2)
        tab.tree.setCurrentIndex(tab.model.index(str(second)))
        window.preview_selected()
        until(lambda: len(log.read_text().splitlines()) == 3)
        assert json.loads(log.read_text().splitlines()[-1]) == [str(second)]
        window.close()
        assert window.preview.process is None
    controller = PreviewController()
    errors = []
    controller.error.connect(errors.append)
    with patch('preview.preview_command', return_value=['/nonexistent/pip-rot-preview']):
        controller.toggle([first])
        until(lambda: bool(errors))
        assert controller.process is None
print('PASS: Quick Look default, tree-only Space, empty selection, toggle, switching, literal paths, cleanup, launch error')
