"""Portable directory Markdown, rendered without adding filesystem model rows."""
from pathlib import Path

from PySide6.QtCore import QFileSystemWatcher, QRectF, QTimer
from PySide6.QtGui import QAbstractTextDocumentLayout, QTextDocument
from PySide6.QtWidgets import QStyleOptionViewItem, QStyledItemDelegate, QTextBrowser

NAME = '.pip-rot.md'
LIMIT = 64 * 1024


def read_note(directory):
    try:
        with (Path(directory) / NAME).open('rb') as stream:
            data = stream.read(LIMIT + 1)
        text = data[:LIMIT].decode('utf-8', errors='replace').strip()
        return text + ('\n\n[Note truncated at 64 KiB]' if len(data) > LIMIT else '')
    except OSError:
        return ''


class NoteDocument(QTextDocument):
    def loadResource(self, _kind, _url):
        # Notes are text: don't fetch network images or read embedded local resources.
        return None


class NotesDelegate(QStyledItemDelegate):
    def sizeHint(self, option, index):
        size = super().sizeHint(option, index)
        size.setHeight(size.height() + self.parent().notes.extra_height(index))
        return size

    def paint(self, painter, option, index):
        top = QStyleOptionViewItem(option)
        top.rect.setHeight(top.rect.height() - self.parent().notes.extra_height(index))
        super().paint(painter, top, index)

    def updateEditorGeometry(self, editor, option, index):
        rect = option.rect.adjusted(0, 0, 0, -self.parent().notes.extra_height(index))
        editor.setGeometry(rect)


class DirectoryNotes:
    def __init__(self, tree):
        self.tree = tree
        self.texts = {}
        self.root_box = QTextBrowser()
        self.root_box.setAccessibleName('Directory notes')
        self.root_box.setOpenLinks(False)
        self.root_box.setDocument(NoteDocument(self.root_box))
        self.root_box.hide()
        self.watcher = QFileSystemWatcher(tree)
        self.timer = QTimer(tree)
        self.timer.setSingleShot(True)
        self.timer.setInterval(80)
        self.timer.timeout.connect(self.reload)
        self.watcher.fileChanged.connect(self.schedule)
        self.watcher.directoryChanged.connect(self.schedule)
        tree.expanded.connect(self.schedule)
        tree.collapsed.connect(self.schedule)
        tree.setItemDelegate(NotesDelegate(tree))

    def schedule(self, *_):
        self.timer.start()

    def reload(self):
        tree = self.tree
        model = tree.model()
        root = tree.rootIndex()
        if model is None or not root.isValid():
            return
        paths = [model.filePath(root)]

        def collect(parent):
            for row in range(model.rowCount(parent)):
                index = model.index(row, 0, parent)
                if tree.isExpanded(index) and model.isDir(index):
                    paths.append(model.filePath(index))
                    collect(index)

        collect(root)
        self.texts = {path: read_note(path) for path in paths}
        watched = self.watcher.files() + self.watcher.directories()
        if watched:
            self.watcher.removePaths(watched)
        targets = [str(p) for path in paths for p in (Path(path), Path(path) / NAME) if p.exists()]
        if targets:
            self.watcher.addPaths(targets)
        text = self.texts[paths[0]]
        self.root_box.document().setMarkdown(text)
        self.root_box.setVisible(bool(text))
        self.resize_root()
        tree.doItemsLayout()
        tree.viewport().update()

    def resize_root(self):
        doc = self.root_box.document()
        doc.setTextWidth(max(80, self.tree.viewport().width() - 24))
        self.root_box.setFixedHeight(min(200, int(doc.size().height()) + 16))

    def document(self, index):
        if not index.isValid():
            return None
        text = self.texts.get(self.tree.model().filePath(index))
        if not text or not self.tree.isExpanded(index):
            return None
        doc = NoteDocument()
        doc.setDefaultFont(self.tree.font())
        doc.setMarkdown(text)
        depth, parent = 1, index.parent()
        while parent.isValid() and parent != self.tree.rootIndex():
            depth += 1
            parent = parent.parent()
        left = depth * self.tree.indentation()
        doc.setTextWidth(max(80, self.tree.viewport().width() - left - 24))
        return doc

    def extra_height(self, index):
        doc = self.document(index)
        return min(200, int(doc.size().height()) + 16) if doc else 0

    def paint(self, painter, option, index):
        doc = self.document(index)
        if doc is None:
            return
        height = min(200, int(doc.size().height()) + 16)
        painter.save()
        rect = QRectF(option.rect)
        rect.setTop(rect.bottom() - height + 1)
        rect.setLeft(self.tree.visualRect(index).left() + 6)
        rect.setRight(self.tree.viewport().width() - 8)
        painter.setClipRect(rect)
        painter.fillRect(rect, self.tree.palette().alternateBase())
        painter.translate(rect.left() + 4, rect.top() + 6)
        context = QAbstractTextDocumentLayout.PaintContext()
        context.palette = self.tree.palette()
        doc.documentLayout().draw(painter, context)
        painter.restore()
