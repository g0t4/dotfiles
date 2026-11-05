"""Reusable command-backed path picker, with the shell's per-directory MRU."""
from dataclasses import dataclass
from pathlib import Path
import os

from PySide6.QtCore import QEvent, QProcess, QTimer, Qt
from PySide6.QtGui import QAction, QKeySequence
from PySide6.QtWidgets import QDialog, QLabel, QLineEdit, QListWidget, QListWidgetItem, QVBoxLayout

from directory_picker import fuzzy_score
from wes_fzf_pickers import FzfMru, ordered_candidates


@dataclass(frozen=True)
class PathProvider:
    key: str
    title: str
    command: tuple[str, ...]
    shortcut: str


def fd_command(*arguments):
    return ('fd', *arguments, '--print0', '--color', 'never')


PROVIDERS = (
    PathProvider('dirs', 'Find Directory', fd_command('--type', 'd', '.'), 'Alt+Shift+D'),
    PathProvider('files', 'Find File', fd_command('--type', 'f', '--type', 'symlink', '.'), 'Alt+Shift+F'),
    PathProvider('both', 'Find File or Directory', fd_command('--type', 'f', '--type', 'd', '--type', 'symlink', '.'), 'Alt+Shift+B'),
    PathProvider('unrestricted', 'Find File (Unrestricted)', fd_command('--type', 'f', '--type', 'symlink', '.', '-u'), 'Alt+Shift+U'),
)


class PathPicker(QDialog):
    """Providers emit NUL-delimited relative paths; no shell evaluation."""
    def __init__(self, root, provider, parent=None, *, mru=None):
        super().__init__(parent)
        self.root = Path(root)
        self.provider = provider
        self.mru = mru or FzfMru()
        self.destination = None
        self.new_tab = False
        self.entries = []
        self.buffer = b''
        self.error = ''
        self.scanning = True
        self.setWindowTitle(f'{provider.title} — {root}')
        self.resize(850, 500)
        layout = QVBoxLayout(self)
        self.query = QLineEdit()
        self.query.setPlaceholderText('Fuzzy search nested paths…')
        self.results = QListWidget()
        self.message = QLabel()
        for widget in (self.query, self.results, self.message):
            layout.addWidget(widget)
        try:
            self.entries = self.mru.read(provider.key, self.root)
        except OSError as error:
            self.error = f'MRU unavailable: {error}'
        self.query.textChanged.connect(self.filter)
        self.query.returnPressed.connect(self.choose)
        self.results.itemActivated.connect(lambda *_: self.choose())
        self.query.installEventFilter(self)
        action = QAction(self)
        action.setShortcut(QKeySequence('Ctrl+Return'))
        action.triggered.connect(lambda: self.choose(True))
        self.addAction(action)
        self.redraw = QTimer(self)
        self.redraw.setSingleShot(True)
        self.redraw.setInterval(75)
        self.redraw.timeout.connect(self.filter)
        self.process = QProcess(self)
        self.process.setWorkingDirectory(str(self.root))
        self.process.readyReadStandardOutput.connect(self.read_output)
        self.process.finished.connect(self.scan_finished)
        self.process.errorOccurred.connect(self.scan_error)
        self.finished.connect(self.stop)
        self.filter()
        self.process.start(provider.command[0], list(provider.command[1:]))
        self.query.setFocus()

    def read_output(self):
        self.buffer += bytes(self.process.readAllStandardOutput())
        pieces = self.buffer.split(b'\0')
        self.buffer = pieces.pop()
        self.entries = ordered_candidates(self.entries, [os.path.normpath(os.fsdecode(p)) for p in pieces])
        if not self.redraw.isActive():
            self.redraw.start()

    def scan_error(self, *_):
        self.error = self.process.errorString()
        self.scanning = False
        self.filter()

    def scan_finished(self, code, *_):
        self.read_output()
        self.scanning = False
        if code:
            self.error = bytes(self.process.readAllStandardError()).decode(errors='replace').strip() or f'Command exited {code}'
        self.filter()

    def filter(self, *_):
        selected = self.results.currentItem()
        selected = selected.data(Qt.ItemDataRole.UserRole) if selected else None
        matches = [(score, order, value) for order, value in enumerate(self.entries)
                   if (score := fuzzy_score(Path(value), self.query.text())) is not None]
        # Like fzf: query quality first, MRU input order breaks ties.
        matches.sort(key=lambda item: (-item[0], item[1]))
        self.results.clear()
        for _, _, value in matches[:300]:
            item = QListWidgetItem(value)
            item.setData(Qt.ItemDataRole.UserRole, value)
            self.results.addItem(item)
            if value == selected:
                self.results.setCurrentItem(item)
        if self.results.currentRow() < 0 and self.results.count():
            self.results.setCurrentRow(0)
        detail = self.error or ('Scanning…' if self.scanning else 'MRU first · fresh paths follow')
        self.message.setText(f'{len(matches)} matches · {detail}\nReturn: navigate/reveal · ⌘Return: new tab · Escape: cancel')

    def eventFilter(self, watched, event):
        if watched is self.query and event.type() == QEvent.Type.KeyPress:
            if event.key() in (Qt.Key.Key_Up, Qt.Key.Key_Down):
                delta = 1 if event.key() == Qt.Key.Key_Down else -1
                self.results.setCurrentRow(max(0, min(self.results.count() - 1, self.results.currentRow() + delta)))
                return True
        return super().eventFilter(watched, event)

    def choose(self, new_tab=False):
        item = self.results.currentItem()
        if not item:
            return
        value = item.data(Qt.ItemDataRole.UserRole)
        destination = self.root / value
        if not destination.exists():
            self.error = 'Path no longer exists; choose another result'
            self.entries.remove(value)
            self.filter()
            return
        try:
            # The shell format is line-delimited; such filenames can be picked,
            # but cannot safely be stored in its shared history.
            if '\n' not in value and '\r' not in value:
                self.mru.record(self.provider.key, value, self.root)
        except OSError as error:
            self.message.setText(f'Could not record MRU: {error}')
        self.destination = destination
        self.new_tab = new_tab
        self.accept()

    def stop(self, *_):
        self.redraw.stop()
        self.process.blockSignals(True)
        if self.process.state() != QProcess.ProcessState.NotRunning:
            self.process.kill()
            self.process.waitForFinished(1000)
