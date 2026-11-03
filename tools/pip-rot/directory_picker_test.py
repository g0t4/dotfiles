"""Shared z adapter, asynchronous loading/recording, fuzzy picker and navigation."""
from pathlib import Path
from types import SimpleNamespace
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QTimer
from PySide6.QtWidgets import QApplication

from directory_picker import DirectoryHistory, DirectoryPicker, fuzzy_score
from pip_rot import Browser


def pump():
    loop = QEventLoop()
    QTimer.singleShot(100, loop.quit)
    loop.exec()


class Backend:
    def __init__(self, paths):
        self.paths = paths
        self.records = []
        self.queries = []

    def entries(self, *, recent=False):
        self.queries.append(recent)
        return [SimpleNamespace(path=p, frecency=i if recent else -i) for i, p in enumerate(self.paths)]

    def record(self, path):
        self.records.append(path)
        return True


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    one, two = root/'course-alert-fatigue', root/'dotfiles'
    one.mkdir()
    two.mkdir()
    backend = Backend([one, two])
    history = DirectoryHistory(backend=backend)
    history.record(one)
    picker = DirectoryPicker(history)
    for _ in range(30):
        pump()
        if picker.results.count():
            break
    assert backend.records == [one]
    assert backend.queries == [True]
    assert picker.entries == [two, one]
    picker.query.setText('crs fat')
    assert picker.results.count() == 1
    picker.choose(True)
    assert picker.destination == one and picker.new_tab
    assert fuzzy_score(one, 'zzzz') is None
    assert fuzzy_score(two, 'dot') is not None
    picker.order.setCurrentIndex(1)
    for _ in range(30):
        pump()
        if len(backend.queries) == 2 and picker.entries:
            break
    assert backend.queries[-1] is False
    picker.close()
    with patch('action_context.Path.home', return_value=root), patch('pip_rot.DirectoryHistory', return_value=history):
        window = Browser([str(root)], record_history=True)
        pump()
        with patch('pip_rot.DirectoryPicker') as fake:
            fake.return_value.exec.return_value = True
            fake.return_value.destination = one
            fake.return_value.new_tab = False
            window.jump_directory()
            assert window.current().root == one and window.tabs.count() == 1
            window.move_history(-1)
            assert window.current().root == root
            fake.return_value.destination = two
            fake.return_value.new_tab = True
            window.jump_directory()
            assert window.current().root == two and window.tabs.count() == 2
        pump()
        assert backend.records[-4:] == [root, one, root, two]
        window.close()
print('PASS: async shared backend, recent/frecency ordering, fuzzy filtering, new-tab intent, current-tab history, shared visit recording')
