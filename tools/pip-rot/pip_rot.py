"""Pip Rot: small independent filesystem trees in tabs."""
import argparse
import subprocess
import os
from dataclasses import dataclass
from pathlib import Path
import sys

from PySide6.QtCore import QDir, QProcess, Qt, QUrl, QTimer
from PySide6.QtGui import QAction, QDesktopServices, QKeySequence
from PySide6.QtWidgets import (
    QApplication, QAbstractItemView, QFileSystemModel, QHeaderView, QInputDialog, QLineEdit, QMainWindow,
    QMenu, QMessageBox, QTabWidget, QTreeView, QVBoxLayout, QWidget,
)


from media import DurationCache, MediaModel
from action_context import publish_context, remove_context
from preview import PreviewController


def finder_trash_executable():
    # macOS /usr/bin/trash is a different implementation with no -F option.
    # Pin the Homebrew command whose Finder mode preserves Put Back metadata.
    path = "/opt/homebrew/bin/trash"
    return path if Path(path).is_file() and os.access(path, os.X_OK) else None


@dataclass
class Location:
    root: Path
    selected: Path | None = None
    scroll: int = 0


class FileTab(QWidget):
    def __init__(self, root: Path, cache: DurationCache, reveal: Path | None = None):
        super().__init__()
        self.root = root
        self.history = [Location(root, reveal)]
        self.history_index = 0
        self.restore_scroll = None
        self.initial_selection_done = False
        self.pending_reveal = reveal
        self.model = MediaModel(cache, self)
        self.model.setReadOnly(True)
        self.model.setOption(QFileSystemModel.Option.DontUseCustomDirectoryIcons)
        self.model.setFilter(QDir.Filter.AllEntries | QDir.Filter.NoDotAndDotDot)
        self.tree = QTreeView()
        self.tree.setModel(self.model)
        self.tree.setRootIndex(self.model.setRootPath(str(root)))
        self.tree.setDragDropMode(QAbstractItemView.DragDropMode.DragOnly)
        self.tree.setDefaultDropAction(Qt.DropAction.CopyAction)
        self.tree.setAcceptDrops(False)
        self.tree.setUniformRowHeights(True)
        self.tree.setSelectionMode(QAbstractItemView.SelectionMode.ExtendedSelection)
        self.tree.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.tree.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.tree.setSortingEnabled(True)
        self.tree.sortByColumn(0, Qt.SortOrder.AscendingOrder)
        self.last_sort = (0, Qt.SortOrder.AscendingOrder)
        self.tree.header().sortIndicatorChanged.connect(self.sort_changed)
        self.tree.header().setSectionResizeMode(0, QHeaderView.ResizeMode.Interactive)
        self.tree.setColumnWidth(0, 440)
        self.tree.setColumnWidth(1, 110)
        self.tree.setColumnHidden(2, True)
        self.tree.setColumnWidth(3, 180)
        self.tree.setColumnWidth(4, 100)
        self.tree.header().moveSection(self.tree.header().visualIndex(4), self.tree.header().visualIndex(3))
        self.tree.setColumnHidden(4, True)
        self.model.rowsInserted.connect(self.update_duration_column)
        self.model.rowsRemoved.connect(self.update_duration_column)
        self.model.dataChanged.connect(self.update_duration_column)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(self.tree)
        self.model.directoryLoaded.connect(self.loaded)
        self.tree.expanded.connect(self.update_duration_column)
        self.tree.collapsed.connect(self.update_duration_column)
        self.tree.doubleClicked.connect(self.open_file)
        QTimer.singleShot(0, lambda: self.loaded(str(root)))

    def sort_changed(self, column, order):
        # QFileSystemModel sorts its four built-in columns only.
        if column == 4:
            self.tree.sortByColumn(*self.last_sort)
        else:
            self.last_sort = (column, order)

    def update_duration_column(self, *_):
        # Inspect loaded rows only; expanding a nested directory may reveal videos.
        def contains_video(parent):
            for row in range(self.model.rowCount(parent)):
                index = self.model.index(row, 0, parent)
                if self.model.is_video(index):
                    return True
                if self.tree.isExpanded(index) and contains_video(index):
                    return True
            return False
        self.tree.setColumnHidden(4, not contains_video(self.tree.rootIndex()))

    def loaded(self, directory):
        self.update_duration_column()
        if self.initial_selection_done:
            return
        if Path(directory) != self.root and not (
            self.pending_reveal and Path(directory) in self.pending_reveal.parents
        ):
            return
        index = self.model.index(str(self.pending_reveal)) if self.pending_reveal else self.model.index(0, 0, self.tree.rootIndex())
        if index.isValid():
            ancestor = index.parent()
            while ancestor.isValid() and ancestor != self.tree.rootIndex():
                self.tree.expand(ancestor)
                ancestor = ancestor.parent()
            self.tree.setCurrentIndex(index)
            self.tree.scrollTo(index)
            self.pending_reveal = None
            self.initial_selection_done = True
            if self.restore_scroll is not None:
                self.tree.verticalScrollBar().setValue(self.restore_scroll)
                self.restore_scroll = None

    def save_location(self):
        entry = self.history[self.history_index]
        entry.selected = self.selected()
        entry.scroll = self.tree.verticalScrollBar().value()

    def navigate(self, root):
        if root == self.root:
            return
        self.save_location()
        del self.history[self.history_index + 1:]
        # Going up highlights the directory we just left.
        reveal = self.root if self.root.parent == root else None
        self.history.append(Location(root, reveal))
        self.history_index += 1
        self.show_location()

    def show_location(self):
        entry = self.history[self.history_index]
        self.root = entry.root
        self.pending_reveal = entry.selected
        self.restore_scroll = entry.scroll
        self.initial_selection_done = False
        self.tree.setRootIndex(self.model.setRootPath(str(self.root)))
        self.tree.clearSelection()
        self.tree.setCurrentIndex(self.model.index(-1, -1))
        self.loaded(str(self.root))
        self.tree.setFocus()

    def selected(self):
        index = self.tree.currentIndex()
        return Path(self.model.filePath(index)) if index.isValid() else self.root

    def open_file(self, index):
        if not self.model.isDir(index):
            QDesktopServices.openUrl(QUrl.fromLocalFile(self.model.filePath(index)))


class Browser(QMainWindow):
    def __init__(self, paths, reveal=False):
        super().__init__()
        self.resize(1200, 740)
        self.duration_cache = DurationCache(self)
        self.trash_processes = set()
        self.preview = PreviewController(self)
        self.preview.error.connect(lambda message: QMessageBox.warning(self, "Pip Rot Preview", message))
        self.tabs = QTabWidget()
        self.tabs.setDocumentMode(True)
        self.tabs.setTabsClosable(True)
        self.tabs.setMovable(True)
        self.tabs.tabCloseRequested.connect(self.close_tab)
        self.tabs.currentChanged.connect(self.update_location)
        self.setCentralWidget(self.tabs)
        toolbar = self.addToolBar("Location")
        toolbar.setMovable(False)
        self.location = QLineEdit()
        self.location.setPlaceholderText("Go to a directory…")
        self.location.returnPressed.connect(self.go_location)
        go_menu = self.menuBar().addMenu("Go")
        self.back_action = self.action(go_menu, "Back", "Ctrl+[", lambda: self.move_history(-1))
        self.forward_action = self.action(go_menu, "Forward", "Ctrl+]", lambda: self.move_history(1))
        toolbar.addAction(self.back_action)
        toolbar.addAction(self.forward_action)
        toolbar.addWidget(self.location)
        file_menu = self.menuBar().addMenu("File")
        view_menu = self.menuBar().addMenu("View")
        self.preview_action = self.action(view_menu, "Quick Look", "Space", self.preview_selected)
        self.preview_action.setShortcutContext(Qt.ShortcutContext.WidgetWithChildrenShortcut)
        self.action(file_menu, "Open Terminal Here", "Ctrl+Alt+T", self.open_terminal)
        self.action(file_menu, "Copy Path", "Ctrl+Shift+C", self.copy_paths)
        self.action(file_menu, "Copy File Contents", "Ctrl+Alt+Shift+C", self.copy_contents)
        self.action(file_menu, "New Nested Directory…", "Ctrl+Shift+N", self.new_directory)
        self.trash_action = self.action(file_menu, "Move to Trash", "Ctrl+Backspace", self.trash_selected)
        self.trash_action.setShortcutContext(Qt.ShortcutContext.WidgetWithChildrenShortcut)
        self.action(file_menu, "Open Directory in New Tab", "Ctrl+Return", self.tab_selected)
        self.action(file_menu, "Duplicate Tab", "Ctrl+T", lambda: self.add_tab(self.current().root))
        open_item = self.action(file_menu, "Open Selected Item", "Ctrl+Down", self.open_selected)
        open_item.setShortcuts([QKeySequence("Ctrl+Down"), QKeySequence("Ctrl+O")])
        self.action(file_menu, "Close Tab", "Ctrl+W", lambda: self.close_tab(self.tabs.currentIndex()))
        self.action(file_menu, "Quit Pip Rot", "Ctrl+Q", self.close)
        self.action(view_menu, "Go to Directory…", "Ctrl+L", self.focus_location)
        parent_directory = self.action(view_menu, "Parent Directory", "Ctrl+Up", self.go_parent)
        parent_directory.setShortcuts([QKeySequence("Ctrl+Up"), QKeySequence("Alt+Up")])
        hidden = self.action(view_menu, "Show Hidden Files", "Ctrl+Shift+.", self.toggle_hidden)
        hidden.setCheckable(True)
        self.hidden_action = hidden
        # Qt swaps Ctrl/Meta on macOS: Meta means the physical Control key.
        control = "Meta" if sys.platform == "darwin" else "Ctrl"
        next_tab = self.action(view_menu, "Next Tab", f"{control}+Tab", lambda: self.cycle_tab(1))
        next_tab.setShortcuts([QKeySequence(f"{control}+Tab"), QKeySequence(f"{control}+PgDown")])
        previous_tab = self.action(view_menu, "Previous Tab", f"{control}+Shift+Tab", lambda: self.cycle_tab(-1))
        previous_tab.setShortcuts([QKeySequence(f"{control}+Shift+Tab"), QKeySequence(f"{control}+PgUp")])
        self.statusBar().showMessage("← → collapse / expand · ⌘↓ open · ⌘↵ new tab · ⌘L go to directory")
        for path in paths:
            self.add_path(path, reveal)

    def action(self, menu, label, shortcut, callback):
        action = QAction(label, self)
        action.setShortcut(QKeySequence(shortcut))
        action.triggered.connect(callback)
        menu.addAction(action)
        return action

    def current(self):
        return self.tabs.currentWidget()

    def add_path(self, path, reveal=False):
        path = Path(path).expanduser().absolute()
        if not path.exists():
            raise ValueError(f"Path does not exist: {path}")
        self.add_tab(path.parent if reveal or not path.is_dir() else path,
                     path if reveal or not path.is_dir() else None)

    def add_tab(self, root, reveal=None):
        tab = FileTab(root, self.duration_cache, reveal)
        self.tabs.setCurrentIndex(self.tabs.addTab(tab, root.name or str(root)))
        self.tabs.setTabToolTip(self.tabs.currentIndex(), str(root))
        tab.tree.addAction(self.trash_action)
        tab.tree.addAction(self.preview_action)
        tab.tree.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        tab.tree.customContextMenuRequested.connect(lambda point: self.context_menu(tab, point))
        self.apply_hidden(tab)
        tab.tree.selectionModel().selectionChanged.connect(self.publish_selection)
        tab.tree.setFocus()
        self.publish_selection()

    def context_menu(self, tab, point):
        index = tab.tree.indexAt(point)
        if index.isValid():
            tab.tree.setCurrentIndex(index)
        menu = QMenu(self)
        if tab.selected().is_dir():
            menu.addAction("Open Directory in New Tab", self.tab_selected)
        else:
            menu.addAction("Open File", self.open_selected)
        menu.addAction("Open Terminal Here", self.open_terminal)
        menu.addAction("Copy Path", self.copy_paths)
        menu.addAction("Copy File Contents", self.copy_contents)
        menu.addAction("New Nested Directory…", self.new_directory)
        menu.addAction(self.trash_action)
        menu.addAction(self.preview_action)
        menu.exec(tab.tree.viewport().mapToGlobal(point))

    def preview_selected(self):
        tab = self.current()
        rows = tab.tree.selectionModel().selectedRows(0)
        paths = [Path(tab.model.filePath(row)) for row in rows]
        if paths:
            self.preview.toggle(paths)

    def trash_selected(self):
        tab = self.current()
        rows = tab.tree.selectionModel().selectedRows(0)
        paths = [tab.model.filePath(row) for row in rows]
        if not paths:
            self.statusBar().showMessage("Select files or directories to move to Trash", 4000)
            return
        executable = finder_trash_executable()
        if not executable:
            QMessageBox.warning(self, "Pip Rot", "Install the trash command: brew install trash")
            return
        process = QProcess(self)
        self.trash_processes.add(process)
        self.trash_action.setEnabled(False)

        def cleanup():
            self.trash_processes.discard(process)
            self.trash_action.setEnabled(not self.trash_processes)
            process.deleteLater()

        def finished(code, _status):
            stderr = bytes(process.readAllStandardError()).decode(errors="replace").strip()
            if code:
                QMessageBox.warning(self, "Pip Rot", stderr or "Some items could not be moved to Trash.")
            else:
                self.statusBar().showMessage(f"Moved {len(paths)} item(s) to Trash — restore with Finder’s Put Back", 5000)
            cleanup()
            self.publish_selection()

        def failed(error):
            if error == QProcess.ProcessError.FailedToStart:
                QMessageBox.warning(self, "Pip Rot", process.errorString())
                cleanup()

        process.finished.connect(finished)
        process.errorOccurred.connect(failed)
        process.start(executable, ["-F", *paths])

    def selected_paths(self):
        tab = self.current()
        if not tab:
            return []
        rows = tab.tree.selectionModel().selectedRows(0)
        return [Path(tab.model.filePath(row)) for row in rows] or [tab.root]

    def publish_selection(self, *_):
        if self.current():
            try:
                publish_context(
                    self.current().root, self.selected_paths(), self.windowTitle(),
                    selection_explicit=bool(self.current().tree.selectionModel().selectedRows(0)),
                )
            except OSError as error:
                self.statusBar().showMessage(f"Could not update action picker context: {error}")

    def closeEvent(self, event):
        self.preview.close()
        remove_context()
        super().closeEvent(event)

    def copy_paths(self):
        QApplication.clipboard().setText("\n".join(map(str, self.selected_paths())))

    def copy_contents(self):
        contents = []
        try:
            paths = self.selected_paths()
            for path in paths:
                if path.is_file():
                    text = path.read_text()
                    contents.append(f"--- {path.name} ---\n{text}" if len(paths) > 1 else text)
        except (OSError, UnicodeError) as error:
            QMessageBox.warning(self, "Pip Rot", f"Could not read file contents: {error}")
            return
        if contents:
            QApplication.clipboard().setText("\n\n".join(contents))
        else:
            self.statusBar().showMessage("Select a text file to copy its contents", 4000)

    def action_directory(self):
        path = self.current().selected()
        return path if path.is_dir() else path.parent

    def open_terminal(self):
        try:
            subprocess.Popen(["/usr/bin/open", "-a", "iTerm", str(self.action_directory())])
        except OSError as error:
            QMessageBox.warning(self, "Pip Rot", str(error))

    def new_directory(self):
        parent = self.action_directory()
        name, accepted = QInputDialog.getText(self, "New Nested Directory", f"Create inside {parent}:")
        if not accepted or not name.strip():
            return
        relative = Path(name.strip())
        if relative.is_absolute() or '..' in relative.parts or relative == Path('.'):
            QMessageBox.warning(self, "Pip Rot", "Use a relative directory name without '..'.")
            return
        target = parent / relative
        try:
            target.mkdir(parents=True)
        except OSError as error:
            QMessageBox.warning(self, "Pip Rot", str(error))
            return
        tab = self.current()
        tab.tree.expand(tab.model.index(str(parent)))
        tab.pending_reveal = target
        tab.initial_selection_done = False
        tab.loaded(str(tab.root))

    def tab_selected(self):
        path = self.current().selected()
        if path.is_dir():
            self.add_tab(path)

    def open_selected(self):
        path = self.current().selected()
        if path.is_dir():
            self.current().navigate(path)
            self.update_location()
        else:
            QDesktopServices.openUrl(QUrl.fromLocalFile(str(path)))

    def close_tab(self, index):
        tab = self.tabs.widget(index)
        self.tabs.removeTab(index)
        tab.deleteLater()
        if not self.tabs.count():
            self.close()
        else:
            self.current().tree.setFocus(Qt.FocusReason.OtherFocusReason)

    def update_location(self, *_):
        if self.current():
            self.location.setText(str(self.current().root))
            self.setWindowTitle(f"{self.current().root} — Pip Rot")
            index = self.tabs.currentIndex()
            self.tabs.setTabText(index, self.current().root.name or str(self.current().root))
            self.tabs.setTabToolTip(index, str(self.current().root))
        if hasattr(self, "back_action"):
            tab = self.current()
            self.back_action.setEnabled(bool(tab and tab.history_index > 0))
            self.forward_action.setEnabled(bool(tab and tab.history_index + 1 < len(tab.history)))
        self.publish_selection()

    def focus_location(self):
        self.location.setFocus()
        self.location.selectAll()

    def go_location(self):
        path = Path(self.location.text()).expanduser()
        if not path.is_absolute():
            path = self.current().root / path
        if not path.is_dir():
            QMessageBox.warning(self, "Pip Rot", f"Not a directory: {path}")
            return
        self.current().navigate(Path(QDir.cleanPath(str(path.absolute()))))
        self.update_location()

    def move_history(self, delta):
        tab = self.current()
        target = tab.history_index + delta
        if not 0 <= target < len(tab.history):
            return
        entry = tab.history[target]
        if not entry.root.is_dir():
            QMessageBox.warning(self, "Pip Rot", f"Directory is no longer available: {entry.root}")
            return
        tab.save_location()
        tab.history_index = target
        tab.show_location()
        self.update_location()

    def go_parent(self):
        self.location.setText(str(self.current().root.parent))
        self.go_location()

    def cycle_tab(self, delta):
        self.tabs.setCurrentIndex((self.tabs.currentIndex() + delta) % self.tabs.count())

    def apply_hidden(self, tab):
        flags = QDir.Filter.AllEntries | QDir.Filter.NoDotAndDotDot
        if self.hidden_action.isChecked():
            flags |= QDir.Filter.Hidden | QDir.Filter.System
        tab.model.setFilter(flags)

    def toggle_hidden(self):
        for index in range(self.tabs.count()):
            self.apply_hidden(self.tabs.widget(index))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", default=[str(Path.cwd())])
    parser.add_argument("--reveal", action="store_true", help="Show each item selected in its parent directory")
    args = parser.parse_args()
    for path in args.paths:
        if not Path(path).expanduser().exists():
            parser.error(f"Path does not exist: {path}")
    app = QApplication(sys.argv[:1])
    app.setApplicationName("Pip Rot")
    app.setOrganizationName("Pip Rot")
    window = Browser(args.paths, args.reveal)
    window.show()
    window.raise_()
    window.activateWindow()
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
