"""A directory jumper over the same z history used by Xonsh."""
import asyncio
import json
from pathlib import Path
import sys

from PySide6.QtCore import QObject, QRunnable, QThreadPool, Qt, Signal, QEvent, QTimer
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
        self.semantic_search = None

    def load(self, recent=True):
        self.generation += 1
        generation = self.generation

        def query():
            try:
                entries = self.backend.entries(recent=recent)
                self.loaded.emit(generation, [entry.path for entry in sorted(entries, key=lambda e: e.frecency, reverse=True)], '')
            except Exception as error:
                self.loaded.emit(generation, [], str(error) or type(error).__name__)

        self.pool.start(Job(query))
        return generation

    def semantic(self, query):
        self.generation += 1
        generation = self.generation

        def search():
            if generation != self.generation:
                return
            try:
                from wes_semantic_history import InferenceClient
                from wes_semantic_z import SemanticZ
                if self.semantic_search is None:
                    self.semantic_search = SemanticZ(InferenceClient())
                matches = asyncio.run(self.semantic_search.retrieve(
                    query, self.backend.entries(recent=False), limit=100))
                self.loaded.emit(generation, [match.path for match in matches], '')
            except Exception as error:
                self.loaded.emit(generation, [], str(error) or type(error).__name__)

        self.pool.start(Job(search))
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
    def __init__(self, history, parent=None, *, standalone=False):
        super().__init__(parent)
        self.base_title = 'Directory Launcher' if standalone else 'Jump to Directory'
        self.setWindowTitle(self.base_title)
        self.resize(850, 500)
        self.history = history
        self.entries = []
        self.destination = None
        self.new_tab = False
        self.standalone = standalone
        self.action = 'use'
        self.semantic_mode = False
        self.debounce = QTimer(self)
        self.debounce.setSingleShot(True)
        self.debounce.setInterval(350)
        self.debounce.timeout.connect(self.search_semantic)
        layout = QVBoxLayout(self)
        self.query = QLineEdit()
        self.query.setPlaceholderText('Fuzzy search your shared z directories…')
        self.order = QComboBox()
        self.order.addItems(['Most recent', 'Frequent + recent (z)'])
        self.results = QListWidget()
        self.message = QLabel('Return: navigate · ⌘Return: new tab · Escape: cancel')
        for widget in (self.query, self.order, self.results, self.message):
            layout.addWidget(widget)
        self.query.textChanged.connect(self.query_changed)
        self.query.returnPressed.connect(self.choose)
        self.query.installEventFilter(self)
        self.results.itemActivated.connect(lambda *_: self.choose())
        self.order.currentIndexChanged.connect(self.reload)
        history.loaded.connect(self.loaded)
        open_tab = QAction(self)
        open_tab.setShortcut(QKeySequence('Ctrl+Return'))
        open_tab.triggered.connect(lambda: self.choose(True, action='open' if self.standalone else 'use'))
        self.addAction(open_tab)
        if standalone:
            copy_path = QAction(self)
            copy_path.setShortcut(QKeySequence('Alt+Return'))
            copy_path.triggered.connect(lambda: self.choose(action='copy'))
            self.addAction(copy_path)
        toggle = QAction(self)
        control = 'Meta' if sys.platform == 'darwin' else 'Ctrl'
        toggle.setShortcut(QKeySequence(f'{control}+R'))
        toggle.triggered.connect(self.toggle_semantic)
        self.addAction(toggle)
        quit_action = QAction(self)
        quit_action.setShortcut(QKeySequence('F9'))
        quit_action.triggered.connect(self.reject)
        self.addAction(quit_action)
        self.finished.connect(self.stop_search)
        self.reload()
        self.query.setFocus()

    def stop_search(self, *_):
        self.debounce.stop()
        self.history.generation += 1
        self.request = None

    def toggle_semantic(self):
        self.semantic_mode = not self.semantic_mode
        self.debounce.stop()
        self.order.setEnabled(not self.semantic_mode)
        self.query.setPlaceholderText('Describe the directory…' if self.semantic_mode
                                      else 'Fuzzy search your shared z directories…')
        self.setWindowTitle(self.base_title + (' — semantic (zr)' if self.semantic_mode else ''))
        self.reload()

    def query_changed(self, *_):
        if self.semantic_mode:
            self.request = None  # Invalidate an in-flight query immediately.
            self.results.clear()
            self.message.setText('Searching semantic z… · Ctrl+R: fuzzy search')
            self.debounce.start()
        else:
            self.filter()

    def search_semantic(self):
        if not self.query.text().strip():
            self.message.setText('Describe a directory · Ctrl+R: fuzzy search')
            return
        self.request = self.history.semantic(self.query.text())

    def reload(self, *_):
        if self.semantic_mode:
            self.query_changed()
            return
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
            source = 'Semantic search unavailable' if self.semantic_mode else 'Could not read z history'
            self.message.setText(f'{source}: {error} · Ctrl+R: switch search mode')

    def filter(self, *_):
        query = self.query.text()
        matches = ([(0, order, path) for order, path in enumerate(self.entries)]
                   if self.semantic_mode else
                   [(score, order, path) for order, path in enumerate(self.entries)
                    if (score := fuzzy_score(path, query)) is not None])
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
        action = 'use folder · ⌘Return: Pip Rot · ⌥Return: copy path' if self.standalone else 'navigate · ⌘Return: new tab'
        mode = 'fuzzy' if self.semantic_mode else 'semantic (zr)'
        self.message.setText(f'{len(matches)} directories · Return: {action} · Ctrl+R: {mode} · Escape: cancel')

    def eventFilter(self, watched, event):
        if watched is self.query and event.type() == QEvent.Type.KeyPress:
            if event.key() in (Qt.Key.Key_Up, Qt.Key.Key_Down):
                delta = 1 if event.key() == Qt.Key.Key_Down else -1
                self.results.setCurrentRow(max(0, min(self.results.count() - 1, self.results.currentRow() + delta)))
                return True
        return super().eventFilter(watched, event)

    def choose(self, new_tab=False, *, action='use'):
        item = self.results.currentItem()
        if item:
            self.destination = Path(item.data(Qt.ItemDataRole.UserRole))
            self.new_tab = new_tab
            self.action = action
            self.accept()


def main():
    from PySide6.QtWidgets import QApplication
    app = QApplication(sys.argv[:1])
    app.setApplicationName('Pip Rot Directory Picker')
    history = DirectoryHistory()
    picker = DirectoryPicker(history, standalone=True)
    picker.show()
    picker.raise_()
    picker.activateWindow()
    accepted = picker.exec()
    if accepted and picker.destination:
        history.record(picker.destination)
        history.pool.waitForDone()
        print(json.dumps({'path': str(picker.destination), 'action': picker.action}), flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
