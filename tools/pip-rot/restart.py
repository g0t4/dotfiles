"""Cooperative restart requests and a small, private session snapshot."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

from PySide6.QtCore import QObject, QTimer

from action_context import context_path


def request_path():
    return context_path().with_name(f'request-{os.getpid()}.json')


def snapshot(window):
    tabs = []
    for index in range(window.tabs.count()):
        tab = window.tabs.widget(index)
        tabs.append({'directory': str(tab.root),
                     'expanded': tab.expanded_paths(),
                     'selected': str(tab.selected()) if tab.tree.selectionModel().selectedRows(0) else None,
                     'scroll': tab.tree.verticalScrollBar().value()})
    return {'version': 1, 'tabs': tabs, 'active_tab': window.tabs.currentIndex(),
            'size': [window.width(), window.height()], 'hidden': window.hidden_action.isChecked()}


def restore(window, session):
    for index, entry in enumerate(session['tabs']):
        tab = window.tabs.widget(index)
        tab.pending_reveal = Path(entry['selected']) if entry['selected'] else None
        tab.restore_scroll = entry['scroll']
        tab.initial_selection_done = False
        tab.pending_expansions = {path for path in entry.get('expanded', [])
                                  if Path(path).is_relative_to(tab.root) and Path(path).is_dir()}
        QTimer.singleShot(0, lambda tab=tab: tab.loaded(str(tab.root)))
    window.hidden_action.setChecked(session.get('hidden', False))
    window.toggle_hidden()
    window.resize(*session.get('size', [1200, 740]))
    window.tabs.setCurrentIndex(min(session.get('active_tab', 0), window.tabs.count() - 1))
    window.update_location()
    window.current().tree.setFocus()


class RestartController(QObject):
    def __init__(self, window):
        super().__init__(window)
        self.window = window
        self.child = None
        self.session_path = None
        self.timer = QTimer(self)
        self.timer.setInterval(200)
        self.timer.timeout.connect(self.poll)
        request_path().unlink(missing_ok=True)
        self.timer.start()

    def poll(self):
        self.poll_status()
        if self.child:
            ready_file = context_path().with_name(f'context-{self.child.pid}.json')
            try:
                ready = json.loads(ready_file.read_text())
            except (OSError, ValueError):
                ready = {}
            if ready.get('pid') == self.child.pid and 'restart' in ready.get('capabilities', []):
                self.window.close()
                return
            if self.child.poll() is not None or time.monotonic() - self.started > 15:
                if self.child.poll() is None:
                    self.child.terminate()
                self.child = None
                if self.session_path:
                    self.session_path.unlink(missing_ok=True)
                self.window.statusBar().showMessage(f'Restart failed; original window kept open. See {self.log_path}', 15000, warning=True)
            return
        filename = request_path()
        if not filename.exists():
            return
        try:
            request = json.loads(filename.read_text())
        except (OSError, ValueError):
            request = {}
        filename.unlink(missing_ok=True)
        if request.get('version') != 1 or request.get('pid') != os.getpid():
            return
        command = request.get('command')
        if command == 'restart':
            self.restart()
        elif command in ('new-folder-inside', 'new-folder-with-selection', 'new-nested-directory-path'):
            # Reject stale picker contexts instead of acting on a different selection.
            if (request.get('paths') != list(map(str, self.window.selected_paths()))
                    or request.get('directory') != str(self.window.current().root)):
                self.window.statusBar().showMessage('Selection changed; reopen the action picker.', 5000, warning=True)
                return
            self.window.show()
            self.window.raise_()
            self.window.activateWindow()
            self.window.current().tree.setFocus()
            callback = {'new-folder-inside': self.window.new_directory,
                        'new-folder-with-selection': self.window.gather_selected,
                        'new-nested-directory-path': self.window.new_nested_directory}[command]
            QTimer.singleShot(100, callback)

    def poll_status(self):
        filename = context_path().with_name(f'status-{os.getpid()}.json')
        try:
            payload = json.loads(filename.read_text())
        except FileNotFoundError:
            return
        except (OSError, ValueError):
            payload = {}
        filename.unlink(missing_ok=True)
        if (payload.get('version') == 1 and payload.get('pid') == os.getpid()
                and isinstance(payload.get('message'), str)):
            self.window.statusBar().showMessage(
                payload['message'], 15000, warning=payload.get('warning') is True,
                success=payload.get('success') is True,
            )

    def restart(self):
        if self.window.transfers.busy:
            self.window.statusBar().showMessage('Let the file transfer finish before restarting.', 5000, warning=True)
            return
        if self.child:
            return
        directory = context_path().parent
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        descriptor, filename = tempfile.mkstemp(prefix='restart-', suffix='.json', dir=directory)
        self.session_path = Path(filename)
        self.log_path = directory / f'restart-{os.getpid()}.log'
        try:
            with os.fdopen(descriptor, 'w') as stream:
                json.dump(snapshot(self.window), stream)
            with self.log_path.open('w') as log:
                self.child = subprocess.Popen(
                    [sys.executable, str(Path(__file__).with_name('pip_rot.py')), '--restore-session', filename],
                    stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT, start_new_session=True,
                )
            self.started = time.monotonic()
            self.window.statusBar().showMessage('Restarting Pip Rot…')
        except OSError as error:
            self.session_path.unlink(missing_ok=True)
            self.window.statusBar().showMessage(f'Could not restart: {error}', 10000, warning=True)

    def close(self):
        self.timer.stop()
        request_path().unlink(missing_ok=True)
