"""Pip Rot: small independent filesystem trees in tabs."""
import argparse
import json
import subprocess
import os
from dataclasses import dataclass
from pathlib import Path
import sys

from PySide6.QtCore import QDir, QItemSelectionModel, QProcess, Qt, QUrl, QTimer, Signal
from PySide6.QtGui import QAction, QDesktopServices, QIcon, QKeySequence
from PySide6.QtWidgets import (
    QApplication, QAbstractItemView, QFileSystemModel, QHeaderView, QInputDialog, QLineEdit, QMainWindow,
    QMenu, QMessageBox, QTabWidget, QVBoxLayout, QWidget,
)


from media import DurationCache, MediaModel
from action_context import publish_context, remove_context
from preview import PreviewController
from directory_picker import DirectoryHistory, DirectoryPicker
from restart import RestartController, restore
from file_tree import FileTree
from transfers import CrossVolumeMove, Transfers, name_parts
from status_line import StatusLine
from diagnostics import log_refresh


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
    model_replaced = Signal()

    def __init__(self, root: Path, cache: DurationCache, reveal: Path | None = None):
        super().__init__()
        self.refresh_state = None
        self.refresh_again = False
        self.pending_expansions = set()
        self.root = root
        self.history = [Location(root, reveal)]
        self.history_index = 0
        self.restore_scroll = None
        self.initial_selection_done = False
        self.pending_reveal = reveal
        self.model = MediaModel(cache, self)
        self.model.setReadOnly(False)
        self.model.setOption(QFileSystemModel.Option.DontUseCustomDirectoryIcons)
        self.model.setFilter(QDir.Filter.AllEntries | QDir.Filter.NoDotAndDotDot)
        self.tree = FileTree()
        self.tree.setModel(self.model)
        self.tree.setRootIndex(self.model.setRootPath(str(root)))
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
        self.model.directoryLoaded.connect(lambda directory: self.loaded(directory, complete=True))
        self.tree.expanded.connect(self.update_duration_column)
        self.tree.collapsed.connect(self.update_duration_column)
        self.tree.doubleClicked.connect(self.open_file)
        QTimer.singleShot(0, lambda: self.loaded(str(root)))

    def expanded_paths(self):
        expanded = []

        def collect(parent):
            for row in range(self.model.rowCount(parent)):
                index = self.model.index(row, 0, parent)
                if self.tree.isExpanded(index):
                    expanded.append(self.model.filePath(index))
                    collect(index)

        collect(self.tree.rootIndex())
        return expanded

    def refresh(self):
        if self.refresh_state is not None:
            self.refresh_again = True
            return
        expanded = self.expanded_paths()
        log_refresh('refresh-start', self.root, {
            path: self.model.rowCount(self.model.index(path))
            for path in [str(self.root), *expanded]
        })
        self.refresh_state = {
            'expanded': expanded,
            'selected': [self.model.filePath(i) for i in self.tree.selectionModel().selectedRows(0)],
            'current': self.model.filePath(self.tree.currentIndex()),
            'scroll': self.tree.verticalScrollBar().value(),
            'horizontal': self.tree.horizontalScrollBar().value(),
            'waiting': {str(self.root), *(p for p in expanded if Path(p).is_dir())},
        }
        refresh_state = self.refresh_state
        QTimer.singleShot(5000, lambda: log_refresh(
            'refresh-still-waiting', self.root, sorted(refresh_state['waiting'])
        ) if self.refresh_state is refresh_state else None)
        old = self.model
        self.model = MediaModel(old.cache, self)
        self.model.setReadOnly(False)
        self.model.setOptions(old.options())
        self.model.setFilter(old.filter())
        self.model.rowsInserted.connect(self.update_duration_column)
        self.model.rowsRemoved.connect(self.update_duration_column)
        self.model.dataChanged.connect(self.update_duration_column)
        self.model.directoryLoaded.connect(lambda directory: self.loaded(directory, complete=True))
        self.tree.setModel(self.model)
        self.tree.setRootIndex(self.model.setRootPath(str(self.root)))
        self.tree.sortByColumn(*self.last_sort)
        self.model_replaced.emit()
        old.deleteLater()
        for path in expanded:
            if Path(path).is_dir():
                self.tree.expand(self.model.index(path))

    def finish_refresh(self):
        state = self.refresh_state
        if state is None or state['waiting']:
            return
        self.refresh_state = None
        log_refresh('refresh-finished', self.root, {
            path: self.model.rowCount(self.model.index(path))
            for path in [str(self.root), *state['expanded']]
        })
        selection = self.tree.selectionModel()
        current = self.model.index(state['current'])
        selection.setCurrentIndex(current, QItemSelectionModel.SelectionFlag.NoUpdate)
        selection.clearSelection()
        for path in state['selected']:
            index = self.model.index(path)
            if index.isValid():
                selection.select(index, QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows)
        self.tree.doItemsLayout()
        self.tree.verticalScrollBar().setValue(state['scroll'])
        self.tree.horizontalScrollBar().setValue(state['horizontal'])
        self.update_duration_column()
        if self.refresh_again:
            self.refresh_again = False
            self.refresh()

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

    def restore_view_scroll(self, complete=False):
        if self.restore_scroll is not None:
            self.tree.doItemsLayout()
            scrollbar = self.tree.verticalScrollBar()
            scrollbar.setValue(self.restore_scroll)
            if complete or scrollbar.maximum() >= self.restore_scroll:
                self.restore_scroll = None

    def loaded(self, directory, complete=False):
        if self.pending_expansions:
            if complete:
                self.pending_expansions.discard(directory)
            for path in sorted(self.pending_expansions):
                self.tree.expand(self.model.index(path))
            if self.pending_expansions:
                return
            directory, complete = str(self.root), True
        if self.refresh_state is not None:
            if complete:
                self.refresh_state['waiting'].discard(directory)
                QTimer.singleShot(0, self.finish_refresh)
            return
        self.update_duration_column()
        if self.restore_scroll is not None and Path(directory) == self.root:
            QTimer.singleShot(0, lambda: self.restore_view_scroll(complete))
        if self.initial_selection_done:
            return
        if Path(directory) != self.root and not (
            self.pending_reveal and Path(directory) in self.pending_reveal.parents
        ):
            return
        index = self.model.index(str(self.pending_reveal)) if self.pending_reveal and self.pending_reveal != self.root else self.model.index(0, 0, self.tree.rootIndex())
        if index.isValid():
            ancestor = index.parent()
            while ancestor.isValid() and ancestor != self.tree.rootIndex():
                self.tree.expand(ancestor)
                ancestor = ancestor.parent()
            self.tree.setCurrentIndex(index)
            self.tree.scrollTo(index)
            self.pending_reveal = None
            self.initial_selection_done = True
            self.restore_view_scroll()

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
        self.refresh_state = None
        self.pending_expansions.clear()
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
    def __init__(self, paths, reveal=False, *, record_history=False):
        super().__init__()
        self.resize(1200, 740)
        self.setStatusBar(StatusLine(self))
        self.restart_controller = None
        self.directory_history = DirectoryHistory(self)
        self.record_history = record_history
        self.last_recorded_directory = None
        self.directory_history.error.connect(lambda message: self.statusBar().showMessage(message, 6000, warning=True))
        self.duration_cache = DurationCache(self)
        self.trash_processes = set()
        self.transfers = Transfers(self)
        self.transfers.finished.connect(self.transfer_finished)
        self.transfers.duplicated.connect(self.duplicate_finished)
        self.transfers.gathered.connect(self.gather_finished)
        self.gather_tab = None
        self.preview = PreviewController(self)
        self.preview.error.connect(lambda message: QMessageBox.warning(self, "Pip Rot Preview", message))
        self.tabs = QTabWidget()
        self.tabs.setDocumentMode(True)
        self.tabs.setTabsClosable(True)
        self.tabs.setMovable(True)
        self.tabs.tabBar().setAcceptDrops(True)
        self.tabs.tabBar().setChangeCurrentOnDrag(True)
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
        self.action(view_menu, "Refresh", "F5", self.refresh_current)
        self.preview_action = self.action(view_menu, "Quick Look", "Space", self.preview_selected)
        self.preview_action.setShortcutContext(Qt.ShortcutContext.WidgetShortcut)
        self.action(file_menu, "Open Terminal Here", "Ctrl+Alt+T", self.open_terminal)
        self.action(file_menu, "Copy Path", "Ctrl+Shift+C", self.copy_paths)
        self.action(file_menu, "Copy File Contents", "Ctrl+Alt+Shift+C", self.copy_contents)
        self.action(file_menu, "New Folder Inside", "Ctrl+Shift+N", self.new_directory)
        self.action(file_menu, "New Nested Directory Path…", "", self.new_nested_directory)
        self.gather_action = self.action(file_menu, "New Folder with Selection", ("Meta+Ctrl+N" if sys.platform == "darwin" else "Ctrl+Alt+N"), self.gather_selected)
        self.gather_action.setShortcutContext(Qt.ShortcutContext.WidgetShortcut)
        self.duplicate_action = self.action(file_menu, "Duplicate", "Ctrl+D", self.duplicate_selected)
        self.duplicate_action.setShortcutContext(Qt.ShortcutContext.WidgetShortcut)
        self.rename_action = self.action(file_menu, "Rename…", "Ctrl+R", self.rename_selected)
        self.rename_action.setShortcuts([QKeySequence("Ctrl+R"), QKeySequence("Return"), QKeySequence("Enter")])
        self.rename_action.setShortcutContext(Qt.ShortcutContext.WidgetShortcut)
        self.trash_action = self.action(file_menu, "Move to Trash", "Ctrl+Backspace", self.trash_selected)
        self.trash_action.setShortcutContext(Qt.ShortcutContext.WidgetShortcut)
        self.action(file_menu, "Open Directory in New Tab", "Ctrl+Return", self.tab_selected)
        self.action(file_menu, "Duplicate Tab", "Ctrl+T", lambda: self.add_tab(self.current().root))
        open_item = self.action(file_menu, "Open Selected Item", "Ctrl+Down", self.open_selected)
        open_item.setShortcuts([QKeySequence("Ctrl+Down"), QKeySequence("Ctrl+O")])
        close_tab = self.action(file_menu, "Close Tab", "Ctrl+W", lambda: self.close_tab(self.tabs.currentIndex()))
        close_tab.setShortcuts([QKeySequence("Ctrl+W"), QKeySequence("F8")])
        self.action(file_menu, "Close Window", "F9", self.close)
        self.action(file_menu, "Restart App", "", self.restart_app)
        self.action(file_menu, "Quit Pip Rot", "Ctrl+Q", self.close)
        self.action(view_menu, "Go to Directory…", "Ctrl+L", self.focus_location)
        parent_directory = self.action(view_menu, "Parent Directory", "Ctrl+Up", self.go_parent)
        parent_directory.setShortcuts([QKeySequence("Ctrl+Up"), QKeySequence("Alt+Up")])
        hidden = self.action(view_menu, "Show Hidden Files", "Ctrl+Shift+.", self.toggle_hidden)
        hidden.setCheckable(True)
        self.hidden_action = hidden
        # Qt swaps Ctrl/Meta on macOS: Meta means the physical Control key.
        control = "Meta" if sys.platform == "darwin" else "Ctrl"
        self.action(go_menu, "Jump to Directory…", f"{control}+P", self.jump_directory)
        next_tab = self.action(view_menu, "Next Tab", f"{control}+Tab", lambda: self.cycle_tab(1))
        next_tab.setShortcuts([QKeySequence(f"{control}+Tab"), QKeySequence(f"{control}+PgDown")])
        previous_tab = self.action(view_menu, "Previous Tab", f"{control}+Shift+Tab", lambda: self.cycle_tab(-1))
        previous_tab.setShortcuts([QKeySequence(f"{control}+Shift+Tab"), QKeySequence(f"{control}+PgUp")])
        self.statusBar().showMessage("← → collapse / expand · ⌘↓ open · ⌘↵ new tab · ⌃P jump · ⌘L path")
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
        tab.tree.files_dropped.connect(self.transfer_files)
        tab.tree.drop_hint.connect(lambda text: self.statusBar().showMessage(text, 4000))
        tab.tree.addAction(self.gather_action)
        tab.tree.addAction(self.duplicate_action)
        tab.tree.addAction(self.rename_action)
        tab.tree.addAction(self.trash_action)
        tab.tree.addAction(self.preview_action)
        tab.tree.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        tab.tree.customContextMenuRequested.connect(lambda point: self.context_menu(tab, point))
        self.apply_hidden(tab)
        tab.model_replaced.connect(lambda: self.connect_tab_model(tab))
        self.connect_tab_model(tab)
        tab.tree.setFocus()
        self.publish_selection()

    def connect_tab_model(self, tab):
        tab.tree.selectionModel().selectionChanged.connect(self.publish_selection)
        tab.model.fileRenamed.connect(
            lambda directory, _old, new: QTimer.singleShot(0, lambda: self.renamed_item(tab, Path(directory) / new))
        )
        tab.model.rename_failed.connect(lambda message: self.statusBar().showMessage(message, 7000, warning=True))
        tab.tree.setFocus()
        self.publish_selection()

    def refresh_current(self):
        tab = self.current()
        if not tab.root.is_dir():
            self.statusBar().showMessage('Directory is no longer available.', 5000, warning=True)
            return
        tab.refresh()

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
        menu.addAction("New Folder Inside", self.new_directory)
        menu.addAction("New Nested Directory Path…", self.new_nested_directory)
        menu.addAction(self.gather_action)
        menu.addAction(self.duplicate_action)
        menu.addAction(self.rename_action)
        menu.addAction(self.trash_action)
        menu.addAction(self.preview_action)
        menu.exec(tab.tree.viewport().mapToGlobal(point))

    def gather_selected(self):
        tab = self.current()
        paths = [Path(tab.model.filePath(row)) for row in tab.tree.selectionModel().selectedRows(0)]
        if not paths or len({path.parent for path in paths}) != 1:
            self.statusBar().showMessage("Select items with the same parent directory", 5000, warning=True)
            return
        if self.transfers.busy:
            self.statusBar().showMessage("Let the current transfer finish first", 4000, warning=True)
            return
        self.gather_tab = tab
        self.transfers.gather(paths)
        self.statusBar().showMessage(f"Moving {len(paths)} item(s) into a new folder…")

    def gather_finished(self, folder, completed, errors):
        tab, self.gather_tab = self.gather_tab, None
        self.transfer_finished(completed, errors)
        if errors or tab is None or self.tabs.indexOf(tab) < 0:
            return
        self.edit_created_folder(tab, folder)

    def edit_created_folder(self, tab, folder):
        # Wait for the replacement model's asynchronous directory loading.
        def edit_when_ready(attempt=0):
            if self.tabs.indexOf(tab) < 0 or self.current() is not tab or not tab.tree.hasFocus():
                return
            if tab.refresh_state is not None:
                if attempt < 100:
                    QTimer.singleShot(50, lambda: edit_when_ready(attempt + 1))
                return
            index = tab.model.index(str(folder))
            if index.isValid():
                self.renamed_item(tab, folder)
                tab.tree.scrollTo(index)
                tab.tree.edit(index)
        QTimer.singleShot(0, edit_when_ready)

    def duplicate_selected(self):
        tab = self.current()
        rows = tab.tree.selectionModel().selectedRows(0)
        if len(rows) != 1:
            self.statusBar().showMessage("Select exactly one file or directory to duplicate", 4000, warning=True)
            return
        source = Path(tab.model.filePath(rows[0]))
        self.transfers.duplicate(source)
        self.statusBar().showMessage(f"Duplicating {source.name}…")

    def duplicate_finished(self, completed, errors):
        if errors:
            QMessageBox.warning(self, "Pip Rot Duplicate", "\n".join(errors))
            return
        source, target, _ = completed[0]
        self.statusBar().showMessage(f"Created {target.name}", 5000)
        tab = self.current()
        # Do not steal focus if the user navigated away while a large copy ran.
        if tab and tab.selected() == source and tab.tree.hasFocus():
            QTimer.singleShot(0, lambda: self.edit_duplicate(tab, source, target))

    def edit_duplicate(self, tab, source, target):
        if self.current() is not tab or tab.selected() != source:
            return
        index = tab.model.index(str(target))
        if not index.isValid():
            return
        self.renamed_item(tab, target)
        tab.tree.scrollTo(index)
        tab.tree.edit(index)
        editor = QApplication.focusWidget()
        if isinstance(editor, QLineEdit):
            editor.setSelection(0, len(name_parts(target)[0].encode("utf-16-le")) // 2)

    def transfer_files(self, paths, destination, copy):
        log_refresh('transfer-submit', destination, {'sources': list(map(str, paths)), 'copy': copy})
        self.transfers.submit(paths, destination, copy)
        verb = "Copying" if copy else "Moving"
        self.statusBar().showMessage(f"{verb} {len(paths)} item(s) to {destination}…")

    def transfer_finished(self, completed, errors):
        log_refresh('transfer-finished', self.current().root, {
            'completed': [(str(source), str(target), copy) for source, target, copy in completed],
            'errors': list(map(str, errors)),
        })
        # Keep tabs/history pointing at directories moved elsewhere in this window.
        for source, target, copy in completed:
            if copy:
                continue
            def remap(path):
                if path is not None and path.is_relative_to(source):
                    return target / path.relative_to(source)
                return path
            for index in range(self.tabs.count()):
                tab = self.tabs.widget(index)
                tab.save_location()
                for entry in tab.history:
                    entry.root = remap(entry.root)
                    entry.selected = remap(entry.selected)
                if tab.root != tab.history[tab.history_index].root:
                    tab.show_location()
        # Worker completion is emitted only after rename/copy publication finishes.
        # Rebuild affected views instead of relying solely on filesystem watchers.
        parents = {path.parent for source, target, _ in completed for path in (source, target)}
        for index in range(self.tabs.count()):
            tab = self.tabs.widget(index)
            if any(parent.is_relative_to(tab.root) or tab.root.is_relative_to(parent) for parent in parents):
                tab.refresh()
        self.update_location()
        if errors:
            cross_volume = next((error for error in errors if isinstance(error, CrossVolumeMove)), None)
            if cross_volume:
                self.cross_volume_warning(cross_volume, len(completed))
            else:
                QMessageBox.warning(self, "Pip Rot Transfer", f"{len(completed)} item(s) completed; {len(errors)} failed.\n\n" + "\n".join(map(str, errors)))
        else:
            self.statusBar().showMessage(f"Transferred {len(completed)} item(s)", 5000)

    def cross_volume_warning(self, error, completed=0):
        message = QMessageBox(self)
        message.setIcon(QMessageBox.Icon.Warning)
        message.setWindowTitle("Cross-volume move")
        message.setText("Pip Rot does not move files between volumes yet.")
        message.setInformativeText(f"{completed} item(s) moved. The blocked source is unchanged.\n\nSource: {error.source}\nDestination: {error.destination}")
        finder = message.addButton("Open in Finder", QMessageBox.ButtonRole.ActionRole)
        message.addButton(QMessageBox.StandardButton.Close)
        message.exec()
        if message.clickedButton() is finder:
            try:
                subprocess.Popen(["/usr/bin/open", "-R", str(error.source)])
                subprocess.Popen(["/usr/bin/open", "-a", "Finder", str(error.destination)])
            except OSError as failure:
                QMessageBox.warning(self, "Pip Rot", f"Could not open Finder: {failure}")

    def renamed_item(self, tab, path):
        index = tab.model.index(str(path))
        if index.isValid():
            tab.tree.setCurrentIndex(index)
            tab.tree.selectionModel().select(
                index, QItemSelectionModel.SelectionFlag.ClearAndSelect | QItemSelectionModel.SelectionFlag.Rows,
            )
        self.publish_selection()

    def rename_selected(self):
        tab = self.current()
        rows = tab.tree.selectionModel().selectedRows(0)
        if len(rows) != 1:
            self.statusBar().showMessage("Select exactly one file or directory to rename", 4000, warning=True)
            return
        tab.tree.setCurrentIndex(rows[0])
        tab.tree.edit(rows[0])

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
            self.statusBar().showMessage("Select files or directories to move to Trash", 4000, warning=True)
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
                    capabilities=["restart", "status", "folder-actions"] if self.restart_controller else [],
                )
            except OSError as error:
                self.statusBar().showMessage(f"Could not update action picker context: {error}", 7000, warning=True)

    def restart_app(self):
        if self.restart_controller is None:
            self.restart_controller = RestartController(self)
        self.restart_controller.restart()

    def closeEvent(self, event):
        if self.transfers.busy:
            self.statusBar().showMessage("File transfer in progress; let it finish before closing.", 5000, warning=True)
            event.ignore()
            return
        if self.restart_controller:
            self.restart_controller.close()
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
            self.statusBar().showMessage("Select a text file to copy its contents", 4000, warning=True)

    def action_directory(self):
        path = self.current().selected()
        return path if path.is_dir() else path.parent

    def open_terminal(self):
        try:
            subprocess.Popen(["/usr/bin/open", "-a", "iTerm", str(self.action_directory())])
        except OSError as error:
            QMessageBox.warning(self, "Pip Rot", str(error))

    def new_directory(self):
        tab = self.current()
        parent = self.action_directory()
        number = 1
        try:
            while True:
                target = parent / ('New Folder' if number == 1 else f'New Folder~{number}')
                try:
                    target.mkdir()
                    break
                except FileExistsError:
                    number += 1
        except OSError as error:
            self.statusBar().showMessage(str(error), 7000, warning=True)
            return
        tab.tree.expand(tab.model.index(str(parent)))
        tab.refresh()
        self.edit_created_folder(tab, target)

    def new_nested_directory(self):
        parent = self.action_directory()
        name, accepted = QInputDialog.getText(self, "New Nested Directory Path", f"Create inside {parent}:")
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
        if self.tabs.count() == 1 and self.transfers.busy:
            self.statusBar().showMessage("File transfer in progress; let it finish before closing.", 5000, warning=True)
            return
        tab = self.tabs.widget(index)
        self.tabs.removeTab(index)
        tab.deleteLater()
        if not self.tabs.count():
            self.close()
        else:
            self.current().tree.setFocus(Qt.FocusReason.OtherFocusReason)

    def update_location(self, *_):
        if self.current():
            if self.record_history and self.current().root != self.last_recorded_directory:
                self.last_recorded_directory = self.current().root
                self.directory_history.record(self.current().root)
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

    def jump_directory(self):
        picker = DirectoryPicker(self.directory_history, self)
        if picker.exec() and picker.destination:
            path = picker.destination
            if not path.is_dir():
                QMessageBox.warning(self, "Pip Rot", f"Directory is no longer available: {path}")
            elif picker.new_tab:
                self.add_tab(path)
            else:
                self.current().navigate(path)
                self.update_location()
        picker.deleteLater()
        if self.current():
            self.current().tree.setFocus()

    def focus_location(self):
        self.location.setFocus()
        self.location.selectAll()

    def go_location(self):
        path = Path(self.location.text()).expanduser()
        if not path.is_absolute():
            path = self.current().root / path
        if path.is_file():
            path = path.parent
        if not path.is_dir():
            parent = path.parent
            while not parent.is_dir() and parent != parent.parent:
                parent = parent.parent
            if not parent.is_dir():
                QMessageBox.warning(self, "Pip Rot", f"No existing parent directory found for: {path}")
                return
            answer = QMessageBox.question(
                self, "Pip Rot",
                f"Directory does not exist:\n{path}\n\nThis directory exists:\n{parent}\n\nIs that what you meant?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
                QMessageBox.StandardButton.No,
            )
            if answer != QMessageBox.StandardButton.Yes:
                return
            path = parent
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
    parser.add_argument("--restore-session", type=Path, help=argparse.SUPPRESS)
    args = parser.parse_args()
    session = None
    if args.restore_session:
        try:
            session = json.loads(args.restore_session.read_text())
            if session['version'] != 1 or not session['tabs']:
                raise ValueError('Invalid session')
            args.paths = [entry['directory'] for entry in session['tabs']]
        except (OSError, ValueError, KeyError, TypeError) as error:
            parser.error(f"Could not restore session: {error}")
    for path in args.paths:
        if not Path(path).expanduser().exists():
            parser.error(f"Path does not exist: {path}")
    app = QApplication(sys.argv[:1])
    app.setApplicationName("Pip Rot")
    app.setOrganizationName("Pip Rot")
    app.setWindowIcon(QIcon(str(Path(__file__).resolve().parent / "assets/pip-rot.png")))
    window = Browser(args.paths, args.reveal, record_history=True)
    if session:
        restore(window, session)
    window.restart_controller = RestartController(window)
    window.show()
    window.publish_selection()
    if args.restore_session:
        args.restore_session.unlink(missing_ok=True)
    window.raise_()
    window.activateWindow()
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
