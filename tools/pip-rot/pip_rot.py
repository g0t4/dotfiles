"""Pip Rot: small independent filesystem trees in tabs."""
import argparse
from pathlib import Path
import sys

from PySide6.QtCore import QDir, Qt, QUrl, QTimer
from PySide6.QtGui import QAction, QDesktopServices, QKeySequence
from PySide6.QtWidgets import (
    QApplication, QAbstractItemView, QFileSystemModel, QHeaderView, QLineEdit, QMainWindow,
    QMenu, QMessageBox, QTabWidget, QTreeView, QVBoxLayout, QWidget,
)


class FileTab(QWidget):
    def __init__(self, root: Path, reveal: Path | None = None):
        super().__init__()
        self.root = root
        self.initial_selection_done = False
        self.pending_reveal = reveal
        self.model = QFileSystemModel(self)
        self.model.setReadOnly(True)
        self.model.setOption(QFileSystemModel.Option.DontUseCustomDirectoryIcons)
        self.model.setFilter(QDir.Filter.AllEntries | QDir.Filter.NoDotAndDotDot)
        self.tree = QTreeView()
        self.tree.setModel(self.model)
        self.tree.setRootIndex(self.model.setRootPath(str(root)))
        self.tree.setUniformRowHeights(True)
        self.tree.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.tree.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.tree.setSortingEnabled(True)
        self.tree.sortByColumn(0, Qt.SortOrder.AscendingOrder)
        self.tree.header().setSectionResizeMode(0, QHeaderView.ResizeMode.Interactive)
        self.tree.setColumnWidth(0, 440)
        self.tree.setColumnWidth(1, 110)
        self.tree.setColumnWidth(2, 150)
        self.tree.setColumnWidth(3, 180)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(self.tree)
        self.model.directoryLoaded.connect(self.loaded)
        self.tree.doubleClicked.connect(self.open_file)
        QTimer.singleShot(0, lambda: self.loaded(str(root)))

    def loaded(self, directory):
        if self.initial_selection_done or Path(directory) != self.root:
            return
        index = self.model.index(str(self.pending_reveal)) if self.pending_reveal else self.model.index(0, 0, self.tree.rootIndex())
        if index.isValid():
            self.tree.setCurrentIndex(index)
            self.tree.scrollTo(index)
            self.pending_reveal = None
            self.initial_selection_done = True

    def selected(self):
        index = self.tree.currentIndex()
        return Path(self.model.filePath(index)) if index.isValid() else self.root

    def open_file(self, index):
        if not self.model.isDir(index):
            QDesktopServices.openUrl(QUrl.fromLocalFile(self.model.filePath(index)))


class Browser(QMainWindow):
    def __init__(self, paths, reveal=False):
        super().__init__()
        self.resize(1100, 740)
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
        toolbar.addWidget(self.location)
        file_menu = self.menuBar().addMenu("File")
        view_menu = self.menuBar().addMenu("View")
        self.action(file_menu, "Open Directory in New Tab", "Ctrl+Return", self.tab_selected)
        self.action(file_menu, "Duplicate Tab", "Ctrl+T", lambda: self.add_tab(self.current().root))
        self.action(file_menu, "Open Selected File", "Ctrl+O", self.open_selected)
        self.action(file_menu, "Close Tab", "Ctrl+W", lambda: self.close_tab(self.tabs.currentIndex()))
        self.action(file_menu, "Quit Pip Rot", "Ctrl+Q", self.close)
        self.action(view_menu, "Go to Directory…", "Ctrl+L", self.focus_location)
        self.action(view_menu, "Parent Directory", "Alt+Up", self.go_parent)
        hidden = self.action(view_menu, "Show Hidden Files", "Ctrl+Shift+.", self.toggle_hidden)
        hidden.setCheckable(True)
        self.hidden_action = hidden
        self.action(view_menu, "Next Tab", "Ctrl+Tab", lambda: self.cycle_tab(1))
        self.action(view_menu, "Previous Tab", "Ctrl+Shift+Tab", lambda: self.cycle_tab(-1))
        self.statusBar().showMessage("← → collapse / expand · ⌘↵ directory in new tab · ⌘L go to directory")
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
        tab = FileTab(root, reveal)
        self.tabs.setCurrentIndex(self.tabs.addTab(tab, root.name or str(root)))
        self.tabs.setTabToolTip(self.tabs.currentIndex(), str(root))
        tab.tree.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        tab.tree.customContextMenuRequested.connect(lambda point: self.context_menu(tab, point))
        self.apply_hidden(tab)
        tab.tree.setFocus()

    def context_menu(self, tab, point):
        index = tab.tree.indexAt(point)
        if index.isValid():
            tab.tree.setCurrentIndex(index)
        menu = QMenu(self)
        if tab.selected().is_dir():
            menu.addAction("Open Directory in New Tab", self.tab_selected)
        else:
            menu.addAction("Open File", self.open_selected)
        menu.addAction("Copy Path", lambda: QApplication.clipboard().setText(str(tab.selected())))
        menu.exec(tab.tree.viewport().mapToGlobal(point))

    def tab_selected(self):
        path = self.current().selected()
        if path.is_dir():
            self.add_tab(path)

    def open_selected(self):
        path = self.current().selected()
        if path.is_dir():
            self.add_tab(path)
        else:
            QDesktopServices.openUrl(QUrl.fromLocalFile(str(path)))

    def close_tab(self, index):
        tab = self.tabs.widget(index)
        self.tabs.removeTab(index)
        tab.deleteLater()
        if not self.tabs.count():
            self.close()

    def update_location(self, *_):
        if self.current():
            self.location.setText(str(self.current().root))
            self.setWindowTitle(f"{self.current().root} — Pip Rot")

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
        old = self.current()
        index = self.tabs.currentIndex()
        self.add_tab(path.absolute())
        self.tabs.removeTab(index)
        old.deleteLater()

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
