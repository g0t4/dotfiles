"""A directory jumper over the same z history used by Xonsh."""
from pathlib import Path
import sys

from PySide6.QtCore import QObject, QRunnable, QThreadPool, Qt, Signal, QEvent
from PySide6.QtWidgets import QComboBox, QDialog, QLabel, QLineEdit, QListWidget, QListWidgetItem, QVBoxLayout
from PySide6.QtGui import QAction, QKeySequence

# Reuse the shell's backend, including its authoritative database configuration.
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / '.config/xonsh/lib'))
from wes_fish_z import FishZ  # noqa: E402


class Job(QRunnable):
    def __init__(self, callback):
        super().__init__()
        self.callback = callback

    def run(self):
        self.callback()


class DirectoryHistory(QObject):
    loaded = Signal(int, object, str)
    error = Signal(str)

    def __init__(self, parent=None, backend=None):
        super().__init__(parent)
        self.backend = backend or FishZ()
        # Serialize our reads/writes; keep shell startup and filesystem checks off the GUI thread.
        self.pool = QThreadPool(self)
        self.pool.setMaxThreadCount(1)
        self.generation = 0

    def load(self, recent=True):
        self.generation += 1
        generation = self.generation

        def query():
            try:
                entries = self.backend.entries(recent=recent)
                self.loaded.emit(generation, [entry.path for entry in sorted(entries, key=lambda e: e.frecency, reverse=True)], '')
            except Exception as error:
                self.loaded.emit(generation, [], str(error))

        self.pool.start(Job(query))
        return generation

    def record(self, path):
        def write():
            try:
                if not self.backend.record(path):
                    self.error.emit('Could not record directory in shared z history')
            except Exception as error:
                self.error.emit(f'Could not record directory in shared z history: {error}')
        self.pool.start(Job(write))


def fuzzy_score(path, query):
    """Match each query word as an ordered subsequence; prefer tight basename matches."""
    text = str(path).casefold()
    score = 0
    for token in query.casefold().split():
        position = -1
        first = None
        for character in token:
            position = text.find(character, position + 1)
            if position < 0:
                return None
            if first is None:
                first = position
        score += len(token) * 10 - (position - first)  # compact matches
        if token in path.name.casefold():
            score += 50
        if token in text:
            score += 20
    return score


class DirectoryPicker(QDialog):
    def __init__(self, history, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Jump to Directory')
        self.resize(850, 500)
        self.history = history
        self.entries = []
        self.destination = None
        self.new_tab = False
        layout = QVBoxLayout(self)
        self.query = QLineEdit()
        self.query.setPlaceholderText('Fuzzy search your shared z directories…')
        self.order = QComboBox()
        self.order.addItems(['Most recent', 'Frequent + recent (z)'])
        self.results = QListWidget()
        self.message = QLabel('Return: navigate · ⌘Return: new tab · Escape: cancel')
        for widget in (self.query, self.order, self.results, self.message):
            layout.addWidget(widget)
        self.query.textChanged.connect(self.filter)
        self.query.returnPressed.connect(self.choose)
        self.query.installEventFilter(self)
        self.results.itemActivated.connect(lambda *_: self.choose())
        self.order.currentIndexChanged.connect(self.reload)
        history.loaded.connect(self.loaded)
        open_tab = QAction(self)
        open_tab.setShortcut(QKeySequence('Ctrl+Return'))
        open_tab.triggered.connect(lambda: self.choose(True))
        self.addAction(open_tab)
        self.reload()
        self.query.setFocus()

    def reload(self, *_):
        self.message.setText('Loading shared z history…')
        self.entries = []
        self.filter()
        self.request = self.history.load(recent=self.order.currentIndex() == 0)

    def loaded(self, generation, entries, error):
        if generation != self.request:
            return
        self.entries = entries
        self.filter()
        if error:
            self.message.setText(f'Could not read z history: {error}')

    def filter(self, *_):
        query = self.query.text()
        matches = [(score, order, path) for order, path in enumerate(self.entries)
                   if (score := fuzzy_score(path, query)) is not None]
        matches.sort(key=lambda item: (-item[0], item[1]))
        self.results.clear()
        home = str(Path.home())
        for _, _, path in matches[:300]:
            text = str(path)
            if text.startswith(home + '/'):
                text = '~' + text[len(home):]
            item = QListWidgetItem(text)
            item.setData(Qt.ItemDataRole.UserRole, str(path))
            item.setToolTip(str(path))
            self.results.addItem(item)
        if matches:
            self.results.setCurrentRow(0)
        self.message.setText(f'{len(matches)} directories · Return: navigate · ⌘Return: new tab · Escape: cancel')

    def eventFilter(self, watched, event):
        if watched is self.query and event.type() == QEvent.Type.KeyPress:
            if event.key() in (Qt.Key.Key_Up, Qt.Key.Key_Down):
                delta = 1 if event.key() == Qt.Key.Key_Down else -1
                self.results.setCurrentRow(max(0, min(self.results.count() - 1, self.results.currentRow() + delta)))
                return True
        return super().eventFilter(watched, event)

    def choose(self, new_tab=False):
        item = self.results.currentItem()
        if item:
            self.destination = Path(item.data(Qt.ItemDataRole.UserRole))
            self.new_tab = new_tab
            self.accept()
