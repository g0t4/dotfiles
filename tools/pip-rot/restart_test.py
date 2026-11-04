"""Restart snapshots, cooperative requests, readiness, and failure recovery."""
import json
import os
from pathlib import Path
import tempfile
from types import SimpleNamespace
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer
from PySide6.QtWidgets import QApplication

from action_context import context_path
from pip_rot import Browser
from restart import RestartController, request_path, restore, snapshot


def pump():
    loop = QEventLoop()
    QTimer.singleShot(200, loop.quit)
    loop.exec()


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    one, two = root/'one', root/'two'
    one.mkdir()
    two.mkdir()
    for number in range(100):
        (two/f'row-{number:03}.txt').touch()
    nested = two/'expanded'/'nested'
    nested.mkdir(parents=True)
    (nested/'child.txt').touch()
    file = two/'selected.txt'
    file.write_text('keep')
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(one), str(two)])
        window.show()
        pump()
        tab = window.current()
        tab.tree.expand(tab.model.index(str(nested.parent)))
        pump()
        tab.tree.expand(tab.model.index(str(nested)))
        pump()
        window.current().tree.setCurrentIndex(window.current().model.index(str(file)))
        window.current().tree.verticalScrollBar().setValue(40)
        saved_scroll = window.current().tree.verticalScrollBar().value()
        assert saved_scroll > 0
        state = snapshot(window)
        assert set(state['tabs'][1]['expanded']) == {str(nested.parent), str(nested)}
        # Deleted expanded paths are safely ignored during restore.
        state['tabs'][1]['expanded'].append(str(two/'missing'))
        replacement = Browser([entry['directory'] for entry in state['tabs']])
        restore(replacement, state)
        replacement.show()
        pump()
        assert replacement.tabs.count() == 2 and replacement.tabs.currentIndex() == 1
        assert replacement.current().root == two and replacement.current().selected() == file
        assert replacement.current().tree.isExpanded(replacement.current().model.index(str(nested)))
        assert replacement.current().tree.isExpanded(replacement.current().model.index(str(nested.parent)))
        assert not replacement.current().pending_expansions
        assert replacement.current().tree.verticalScrollBar().value() == saved_scroll
        replacement.close()
        cold = Browser([str(two)])
        cold.show()
        pump()
        assert not cold.current().tree.isExpanded(cold.current().model.index(str(nested.parent)))
        cold.close()
        controller = RestartController(window)
        window.restart_controller = controller
        fake_child = SimpleNamespace(pid=987654321, poll=lambda: None, terminate=lambda: None)
        with patch('restart.subprocess.Popen', return_value=fake_child) as popen:
            request_path().write_text(json.dumps({'version':1,'pid':os.getpid(),'command':'restart'}))
            controller.poll()
            assert popen.call_count == 1 and window.isVisible()
            command = popen.call_args.args[0]
            saved = json.loads(Path(command[-1]).read_text())
            assert saved['tabs'][1]['directory'] == str(two) and saved['active_tab'] == 1
            controller.poll()
            assert window.isVisible(), 'original must remain until replacement is ready'
            ready = context_path().with_name(f'context-{fake_child.pid}.json')
            ready.write_text(json.dumps({'pid':fake_child.pid,'capabilities':['restart']}))
            controller.poll()
            assert not window.isVisible()
            ready.unlink()
            controller.session_path.unlink(missing_ok=True)
        failed = Browser([str(one)])
        failed.show()
        controller = RestartController(failed)
        failed.restart_controller = controller
        with patch('restart.subprocess.Popen', return_value=SimpleNamespace(pid=987654322,poll=lambda:1)):
            controller.restart()
            controller.poll()
            assert failed.isVisible() and 'original window kept open' in failed.statusBar().currentMessage()
        with patch('restart.subprocess.Popen') as popen:
            request_path().write_text(json.dumps({'version':1,'pid':-1,'command':'restart'}))
            controller.poll()
            popen.assert_not_called()
        failed.close()
print('PASS: tabs/active selection restored, JSON request dispatch, wait for readiness, keep original on failure, reject wrong PID')
