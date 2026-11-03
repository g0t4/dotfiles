"""Verify native file URL payloads and filesystem drag configuration."""
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
        assert tab.tree.dragDropMode() == QAbstractItemView.DragDropMode.DragDrop
        assert tab.tree.defaultDropAction() == Qt.DropAction.CopyAction
        assert tab.tree.acceptDrops() and tab.tree.viewport().acceptDrops()
        assert not tab.model.isReadOnly()
        assert tab.model.supportedDragActions() == (Qt.DropAction.CopyAction | Qt.DropAction.MoveAction)
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
        with patch('file_tree.QDrag') as drag:
            drag.return_value.exec.return_value = Qt.DropAction.MoveAction
            tab.tree.startDrag(Qt.DropAction.CopyAction | Qt.DropAction.MoveAction)
            assert drag.return_value.setMimeData.call_args.args[0].hasFormat('application/x-pip-rot-files')
            drag.return_value.exec.assert_called_once_with(
                Qt.DropAction.CopyAction | Qt.DropAction.MoveAction, Qt.DropAction.CopyAction,
            )
        # Even a target returning Move must never trigger generic source row deletion.
        assert all(path.read_bytes() == b'test source bytes' for path in paths)
        window.close()
print('PASS: file drag/drop tree, move/copy negotiation, multi-file native URLs, Unicode/special paths, sources unchanged')
