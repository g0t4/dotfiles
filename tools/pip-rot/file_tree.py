"""Native URL dragging with explicit filesystem drop handling."""
from pathlib import Path

from PySide6.QtCore import QModelIndex, Qt, Signal
from PySide6.QtGui import QDrag, QPainter, QPen
from PySide6.QtWidgets import QAbstractItemView, QTreeView

PIP_ROT_FILES = 'application/x-pip-rot-files'


def dropped_paths(mime):
    urls = mime.urls()
    if not urls or not all(url.isLocalFile() for url in urls):
        return []
    return [Path(url.toLocalFile()) for url in urls]


def drop_action(mime, modifiers, possible):
    # External sources only copy: they must never remove files before our async job completes.
    internal_move = mime.hasFormat(PIP_ROT_FILES) and not modifiers & Qt.KeyboardModifier.AltModifier
    preferred = Qt.DropAction.MoveAction if internal_move else Qt.DropAction.CopyAction
    return preferred if possible & preferred else Qt.DropAction.IgnoreAction


class FileTree(QTreeView):
    files_dropped = Signal(object, object, bool)
    drop_hint = Signal(str)

    def __init__(self):
        super().__init__()
        self.setDragDropMode(QAbstractItemView.DragDropMode.DragDrop)
        self.setDefaultDropAction(Qt.DropAction.CopyAction)
        self.setAcceptDrops(True)
        self.setDropIndicatorShown(False)
        self.setAutoExpandDelay(600)
        self.drop_index = QModelIndex()
        self.drop_active = False

    def startDrag(self, _supported):
        indexes = self.selectionModel().selectedRows(0)
        if not indexes:
            return
        mime = self.model().mimeData(indexes)
        mime.setData(PIP_ROT_FILES, b'1')
        drag = QDrag(self)
        drag.setMimeData(mime)
        icon = self.model().fileIcon(indexes[0])
        drag.setPixmap(icon.pixmap(48, 48))
        # Filesystem targets move URLs themselves; never run Qt's generic row deletion.
        drag.exec(Qt.DropAction.CopyAction | Qt.DropAction.MoveAction, Qt.DropAction.CopyAction)
        self.clear_drop()

    def destination(self, position):
        index = self.indexAt(position)
        if index.isValid() and not self.model().isDir(index):
            return None, index
        return Path(self.model().filePath(index if index.isValid() else self.rootIndex())), index

    def dragEnterEvent(self, event):
        if dropped_paths(event.mimeData()):
            action = drop_action(event.mimeData(), event.modifiers(), event.possibleActions())
            if action != Qt.DropAction.IgnoreAction:
                event.setDropAction(action)
                event.accept()
                return
        event.ignore()

    def dragMoveEvent(self, event):
        destination, index = self.destination(event.position().toPoint())
        action = drop_action(event.mimeData(), event.modifiers(), event.possibleActions())
        if destination and dropped_paths(event.mimeData()) and action != Qt.DropAction.IgnoreAction:
            super().dragMoveEvent(event)  # Qt supplies edge scrolling and hover expansion.
            self.drop_active, self.drop_index = True, index
            verb = 'Copy' if action == Qt.DropAction.CopyAction else 'Move'
            self.drop_hint.emit(f'{verb} to {destination} · Option: copy')
            event.setDropAction(action)
            event.accept()
        else:
            self.clear_drop()
            event.ignore()
        self.viewport().update()

    def dragLeaveEvent(self, event):
        super().dragLeaveEvent(event)
        self.clear_drop()

    def dropEvent(self, event):
        destination, _ = self.destination(event.position().toPoint())
        paths = dropped_paths(event.mimeData())
        action = drop_action(event.mimeData(), event.modifiers(), event.possibleActions())
        self.clear_drop()
        if not destination or not paths or action == Qt.DropAction.IgnoreAction:
            event.ignore()
            return
        # This signal is the only transfer entry point; QFileSystemModel.dropMimeData is not called.
        self.files_dropped.emit(paths, destination, action == Qt.DropAction.CopyAction)
        event.setDropAction(action)
        event.accept()

    def clear_drop(self):
        self.drop_active = False
        self.drop_index = QModelIndex()
        self.drop_hint.emit('')
        self.viewport().update()

    def paintEvent(self, event):
        super().paintEvent(event)
        if self.drop_active:
            painter = QPainter(self.viewport())
            painter.setPen(QPen(self.palette().highlight().color(), 2))
            rectangle = self.visualRect(self.drop_index) if self.drop_index.isValid() else self.viewport().rect()
            rectangle.setLeft(1)
            rectangle.setRight(self.viewport().width() - 2)
            painter.drawRect(rectangle.adjusted(0, 1, 0, -1))
