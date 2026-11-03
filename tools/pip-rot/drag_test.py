"""Verify native file URL payloads and copy-only drag configuration."""
import tempfile
from pathlib import Path
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QItemSelectionModel, QTimer, Qt
from PySide6.QtWidgets import QApplication, QAbstractItemView

from pip_rot import Browser

app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    paths = [root / "clip #1 $ ' café.mov", root / 'clip two.mkv']
    for path in paths:
        path.write_bytes(b'test source bytes')
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        loop = QEventLoop()
        QTimer.singleShot(200, loop.quit)
        loop.exec()
        tab = window.current()
        assert tab.tree.dragEnabled()
        assert tab.tree.dragDropMode() == QAbstractItemView.DragDropMode.DragOnly
        assert tab.tree.defaultDropAction() == Qt.DropAction.CopyAction
        assert not tab.tree.acceptDrops() and not tab.tree.viewport().acceptDrops()
        assert tab.model.isReadOnly()
        assert tab.model.supportedDragActions() == Qt.DropAction.CopyAction
        tab.tree.clearSelection()
        for path in paths:
            index = tab.model.index(str(path))
            assert tab.model.flags(index) & Qt.ItemFlag.ItemIsDragEnabled
            tab.tree.selectionModel().select(index, QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows)
        # Use all selected columns, just as QAbstractItemView does during a drag.
        payload = tab.model.mimeData(tab.tree.selectedIndexes())
        assert payload.hasUrls() and payload.hasFormat('text/uri-list')
        urls = payload.urls()
        assert len(urls) == 2
        assert {url.toLocalFile() for url in urls} == set(map(str, paths))
        assert all(url.isLocalFile() for url in urls)
        assert all(path.read_bytes() == b'test source bytes' for path in paths)
        window.close()
print('PASS: drag-only tree, no drop targets, copy-only negotiation, multi-file native URLs, Unicode/special paths, sources unchanged')
