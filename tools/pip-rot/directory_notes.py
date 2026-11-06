"""Portable directory Markdown, rendered without adding filesystem model rows."""
from pathlib import Path

from PySide6.QtCore import QEvent, QFileSystemWatcher, QIODevice, QObject, QRectF, QSaveFile, Qt, QTimer, Signal
from PySide6.QtGui import QAbstractTextDocumentLayout, QColor, QPalette, QTextCursor, QTextDocument
from PySide6.QtWidgets import (
    QFrame, QHBoxLayout, QLabel, QMessageBox, QPlainTextEdit, QPushButton,
    QStyle, QStyleOptionViewItem, QStyledItemDelegate, QTextBrowser, QVBoxLayout,
)

NAME = '.rotten.md'
LIMIT = 64 * 1024
NOTE_PADDING = 2
NOTE_LEFT = 24


def muted(foreground, background):
    return QColor(*(round(foreground.getRgb()[i] * 0.65 + background.getRgb()[i] * 0.35) for i in range(3)))


def read_note(directory):
    try:
        with (Path(directory) / NAME).open('rb') as stream:
            data = stream.read(LIMIT + 1)
        text = data[:LIMIT].decode('utf-8', errors='replace').strip()
        return text + ('\n\n[Note truncated at 64 KiB]' if len(data) > LIMIT else '')
    except OSError:
        return ''


class NoteDocument(QTextDocument):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setDocumentMargin(0)

    def setMarkdown(self, markdown, *args):
        super().setMarkdown(markdown, *args)
        # Qt gives each list item paragraph margins; keep lists compact in blurbs.
        block = self.begin()
        while block.isValid():
            if block.textList() is not None:
                formatting = block.blockFormat()
                formatting.setTopMargin(0)
                formatting.setBottomMargin(0)
                QTextCursor(block).setBlockFormat(formatting)
            block = block.next()

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


class NoteInput(QPlainTextEdit):
    save_requested = Signal()
    cancel_requested = Signal()

    def event(self, event):
        save = (event.type() in (QEvent.Type.ShortcutOverride, QEvent.Type.KeyPress)
                and event.key() in (Qt.Key.Key_Return, Qt.Key.Key_Enter)
                and event.modifiers() == Qt.KeyboardModifier.ControlModifier)
        cancel = (event.type() in (QEvent.Type.ShortcutOverride, QEvent.Type.KeyPress)
                  and event.key() == Qt.Key.Key_Escape)
        if save or cancel:
            event.accept()
            if event.type() == QEvent.Type.KeyPress:
                (self.save_requested if save else self.cancel_requested).emit()
            return True
        return super().event(event)


class DirectoryNotes(QObject):
    def __init__(self, tree):
        super().__init__(tree)
        self.tree = tree
        self.editing = None
        self.editor = None
        self.texts = {}
        self.root_box = QTextBrowser()
        self.root_box.setAccessibleName('Directory notes')
        self.root_box.setOpenLinks(False)
        self.root_box.setFrameShape(QFrame.Shape.NoFrame)
        self.root_box.setContentsMargins(0, 0, 0, 0)
        self.root_box.setViewportMargins(tree.indentation() + NOTE_LEFT, NOTE_PADDING, 0, NOTE_PADDING)
        palette = tree.palette()
        palette.setColor(QPalette.ColorRole.Text, muted(palette.text().color(), palette.base().color()))
        palette.setColor(QPalette.ColorRole.Window, palette.base().color())
        self.root_box.setPalette(palette)
        self.root_box.setAutoFillBackground(True)
        self.root_box.setDocument(NoteDocument(self.root_box))
        self.root_box.hide()
        self.root_box.setToolTip('Edit Directory Notes: ⌘Shift+R from the tree, or File menu')
        tree.verticalScrollBar().valueChanged.connect(self.position_editor)
        tree.horizontalScrollBar().valueChanged.connect(self.position_editor)
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
        self.root_box.setVisible(bool(text) or self.editing == paths[0])
        self.resize_root()
        tree.doItemsLayout()
        tree.viewport().update()
        QTimer.singleShot(0, self.position_editor)

    def resize_root(self):
        doc = self.root_box.document()
        doc.setTextWidth(max(80, self.tree.viewport().width() - self.tree.indentation() - NOTE_LEFT))
        root = self.tree.model().filePath(self.tree.rootIndex()) if self.tree.model() else None
        height = 180 if self.editing == root else min(200, int(doc.size().height()) + NOTE_PADDING * 2)
        self.root_box.setFixedHeight(height)

    def document(self, index):
        if not index.isValid():
            return None
        index = index.siblingAtColumn(0)
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
        doc.setTextWidth(max(80, self.tree.viewport().width() - left - NOTE_LEFT - 8))
        return doc

    def extra_height(self, index):
        if index.isValid():
            index = index.siblingAtColumn(0)
        if index.isValid() and self.editing == self.tree.model().filePath(index):
            return 180
        doc = self.document(index)
        return min(200, int(doc.size().height()) + NOTE_PADDING * 2) if doc else 0

    def paint(self, painter, option, index):
        doc = self.document(index)
        if doc is None:
            return
        height = min(200, int(doc.size().height()) + NOTE_PADDING * 2)
        painter.save()
        rect = QRectF(option.rect)
        rect.setTop(rect.bottom() - height + 1)
        rect.setLeft(self.tree.visualRect(index).left() + NOTE_LEFT)
        rect.setRight(self.tree.viewport().width() - 8)
        painter.setClipRect(rect)
        painter.translate(rect.left(), rect.top() + NOTE_PADDING)
        context = QAbstractTextDocumentLayout.PaintContext()
        context.palette = self.tree.palette()
        selected = bool(option.state & QStyle.StateFlag.State_Selected)
        foreground = context.palette.highlightedText().color() if selected else context.palette.text().color()
        background = context.palette.highlight().color() if selected else context.palette.base().color()
        context.palette.setColor(QPalette.ColorRole.Text, muted(foreground, background))
        doc.documentLayout().draw(painter, context)
        painter.restore()

    def begin_edit(self, directory):
        if self.editing is not None:
            self.input.setFocus()
            return
        path = Path(directory) / NAME
        try:
            with path.open('rb') as stream:
                raw = stream.read(LIMIT + 1)
            if len(raw) > LIMIT:
                raise ValueError('Notes larger than 64 KiB must be edited in an external editor.')
            text = raw.decode('utf-8')
        except FileNotFoundError:
            text = ''
        except (OSError, ValueError) as error:
            QMessageBox.warning(self.tree, 'Directory Notes', str(error))
            return
        self.editing = str(directory)
        self.editor = QFrame(self.root_box.parentWidget())
        self.editor.setFrameShape(QFrame.Shape.StyledPanel)
        self.editor.setAutoFillBackground(True)
        layout = QVBoxLayout(self.editor)
        layout.setContentsMargins(6, 4, 6, 4)
        layout.addWidget(QLabel(f"Directory notes: {directory}"))
        self.input = NoteInput()
        self.input.setAccessibleName('Edit directory Markdown')
        self.input.setPlainText(text)
        self.input.save_requested.connect(self.save)
        self.input.cancel_requested.connect(self.cancel)
        layout.addWidget(self.input)
        buttons = QHBoxLayout()
        self.error = QLabel('Markdown · ⌘Return saves · Escape cancels')
        self.error.setWordWrap(True)
        buttons.addWidget(self.error, 1)
        for label, callback in [('Save', self.save), ('Cancel', self.cancel)]:
            button = QPushButton(label)
            button.clicked.connect(callback)
            buttons.addWidget(button)
        layout.addLayout(buttons)
        index = self.tree.model().index(str(directory))
        if index != self.tree.rootIndex():
            self.tree.expand(index)
        self.reload()
        self.editor.show()
        self.editor.raise_()
        QTimer.singleShot(0, self.position_editor)
        self.input.setFocus()

    def position_editor(self, *_):
        if self.editor is None:
            return
        root = self.tree.model().filePath(self.tree.rootIndex())
        if self.editing == root:
            widget, rect = self.root_box, self.root_box.rect()
        else:
            index = self.tree.model().index(self.editing)
            rect = self.tree.visualRect(index)
            rect.setTop(rect.bottom() - 179)
            rect.setRight(self.tree.viewport().width() - 8)
            widget = self.tree.viewport()
            if not index.isValid() or not rect.intersects(widget.rect()):
                rect = widget.rect()
                rect.setHeight(180)
        self.editor.setGeometry(rect.translated(widget.mapTo(self.editor.parentWidget(), widget.rect().topLeft())))

    def save(self):
        data = self.input.toPlainText().encode('utf-8')
        if len(data) > LIMIT:
            self.error.setText('Notes exceed 64 KiB. Shorten them or use an external editor.')
            return
        output = QSaveFile(str(Path(self.editing) / NAME))
        if not output.open(QIODevice.OpenModeFlag.WriteOnly):
            self.error.setText(f'Could not save: {output.errorString()}')
            return
        if output.write(data) != len(data) or not output.commit():
            self.error.setText(f'Could not save: {output.errorString()}')
            return
        self.cancel()

    def cancel(self):
        self.editing = None
        self.editor.hide()
        self.editor.deleteLater()
        self.editor = None
        self.reload()
        self.tree.setFocus()
