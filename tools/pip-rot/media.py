"""Lazy, bounded video metadata probes; no recursive filesystem scan."""
import math
from pathlib import Path
import shutil
import subprocess

from PySide6.QtCore import QModelIndex, QObject, QRunnable, QThreadPool, Qt, Signal
from PySide6.QtWidgets import QFileSystemModel

from file_icons import FileIcons

VIDEO_SUFFIXES = frozenset('.mp4 .m4v .mov .mkv .avi .webm .mpg .mpeg .mts .m2ts .ts .vob .wmv .flv .ogv .3gp'.split())


def format_duration(seconds):
    if seconds is None:
        return '—'
    total = int(seconds + 0.5)
    hours, remainder = divmod(total, 3600)
    minutes, seconds = divmod(remainder, 60)
    return f'{hours}:{minutes:02}:{seconds:02}' if hours else f'{minutes}:{seconds:02}'


def probe_duration(executable, path):
    try:
        result = subprocess.run(
            [executable, '-v', 'error', '-show_entries', 'format=duration',
             '-of', 'default=noprint_wrappers=1:nokey=1', str(path)],
            capture_output=True, text=True, timeout=8, check=True,
        )
        seconds = float(result.stdout.strip())
        return seconds if math.isfinite(seconds) and seconds >= 0 else None
    except (OSError, subprocess.SubprocessError, ValueError):
        return None


class ProbeSignals(QObject):
    done = Signal(object, object)


class Probe(QRunnable):
    def __init__(self, executable, key, signals):
        super().__init__()
        self.executable, self.key, self.signals = executable, key, signals

    def run(self):
        self.signals.done.emit(self.key, probe_duration(self.executable, self.key[0]))


class DurationCache(QObject):
    updated = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.executable = shutil.which('ffprobe') or (
            '/opt/homebrew/bin/ffprobe' if Path('/opt/homebrew/bin/ffprobe').exists() else None
        )
        self.pool = QThreadPool(self)
        self.pool.setMaxThreadCount(2)
        self.values = {}
        self.pending = set()
        self.signals = ProbeSignals(self)
        self.signals.done.connect(self.completed)

    def key(self, path):
        try:
            stat = path.stat()
            return str(path), stat.st_mtime_ns, stat.st_size
        except OSError:
            return None

    def get(self, path):
        key = self.key(path)
        if key is None or not self.executable:
            return '—'
        if key in self.values:
            return format_duration(self.values[key])
        if key not in self.pending:
            self.pending.add(key)
            self.pool.start(Probe(self.executable, key, self.signals))
        return '…'

    def completed(self, key, seconds):
        self.pending.discard(key)
        # Keep only the latest version of a file; changed videos get re-probed.
        for old in tuple(self.values):
            if old[0] == key[0]:
                del self.values[old]
        self.values[key] = seconds
        self.updated.emit(key[0])


class MediaModel(QFileSystemModel):
    rename_failed = Signal(str)

    def __init__(self, cache, parent=None):
        super().__init__(parent)
        self.cache = cache
        self.icons = FileIcons()
        cache.updated.connect(self.duration_ready)

    def setData(self, index, value, role=Qt.ItemDataRole.EditRole):
        if role == Qt.ItemDataRole.EditRole and index.column() == 0:
            name = str(value)
            if not name or name in ('.', '..') or '/' in name or '\0' in name:
                self.rename_failed.emit('Rename requires a filename, without path separators.')
                return False
            if name == self.fileName(index):
                return True
            renamed = super().setData(index, name, role)
            if not renamed:
                self.rename_failed.emit(f'Could not rename to {name!r}: target exists or directory is not writable.')
            return renamed
        return super().setData(index, value, role)

    def supportedDragActions(self):
        return Qt.DropAction.CopyAction | Qt.DropAction.MoveAction

    def columnCount(self, parent=QModelIndex()):
        return 5

    def headerData(self, section, orientation, role=Qt.ItemDataRole.DisplayRole):
        if section == 4 and orientation == Qt.Orientation.Horizontal:
            if role == Qt.ItemDataRole.DisplayRole:
                return 'Duration'
            if role == Qt.ItemDataRole.ToolTipRole:
                return 'Video duration (display only; sort using Name, Size, Type, or Date Modified)'
            return None
        return super().headerData(section, orientation, role)

    def is_video(self, index):
        return not self.isDir(index) and Path(self.filePath(index)).suffix.lower() in VIDEO_SUFFIXES

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if index.isValid() and index.column() == 0 and role == Qt.ItemDataRole.DecorationRole:
            icon = self.icons.icon(self.fileName(index), self.isDir(index))
            if icon is not None:
                return icon
        if index.column() != 4:
            return super().data(index, role)
        if not self.is_video(index):
            return None
        if role == Qt.ItemDataRole.DisplayRole:
            return self.cache.get(Path(self.filePath(index)))
        if role == Qt.ItemDataRole.TextAlignmentRole:
            return int(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        if role == Qt.ItemDataRole.ToolTipRole:
            return 'Video duration (ffprobe)' if self.cache.executable else 'Install ffmpeg to enable duration: brew install ffmpeg'
        return None

    def duration_ready(self, path):
        index = self.index(path)
        if index.isValid():
            duration = self.index(index.row(), 4, index.parent())
            self.dataChanged.emit(duration, duration, [Qt.ItemDataRole.DisplayRole])
