"""Real temporary-file moves/copies and synthesized Qt folder drops."""
import errno
import subprocess
from pathlib import Path
import tempfile
from unittest.mock import patch

from PySide6.QtCore import QEventLoop, QMimeData, QPoint, QPointF, QTimer, Qt, QUrl
from PySide6.QtGui import QDragEnterEvent, QDragMoveEvent, QDropEvent
from PySide6.QtWidgets import QApplication

from file_tree import PIP_ROT_FILES, drop_action
from pip_rot import Browser
from transfers import plan_transfer, transfer_one, rename_exclusive


def pump():
    loop = QEventLoop()
    QTimer.singleShot(150, loop.quit)
    loop.exec()


def expect_error(callback):
    try:
        callback()
    except (OSError, ValueError):
        return
    raise AssertionError('Unsafe transfer was accepted')


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    source, destination = root/'source', root/'destination'
    source.mkdir()
    destination.mkdir()
    file = source/"clip $ ' café.mov"
    file.write_bytes(b'original media')
    target = destination/file.name
    transfer_one(*plan_transfer([file], destination, False)[0])
    assert not file.exists() and target.read_bytes() == b'original media'
    folder = source/'package'
    folder.mkdir()
    (folder/'content').write_text('directory payload')
    (folder/'link').symlink_to('content')
    transfer_one(*plan_transfer([folder, folder/'content'], destination, True)[0])
    assert folder.exists() and (destination/'package/content').read_text() == 'directory payload'
    assert (destination/'package/link').is_symlink()
    expect_error(lambda: plan_transfer([folder], destination, True))
    expect_error(lambda: plan_transfer([folder], folder, False))
    assert plan_transfer([target], destination, False) == []
    # An occupied target created after preflight must still be protected atomically.
    late = source/'late.txt'
    late.write_text('source')
    plan = plan_transfer([late], destination, False)
    (destination/late.name).write_text('existing')
    expect_error(lambda: transfer_one(*plan[0]))
    assert late.read_text() == 'source' and (destination/late.name).read_text() == 'existing'
    # Broken links are occupied destinations too.
    link = source/'broken'
    link.symlink_to('missing')
    (destination/'broken').symlink_to('also-missing')
    expect_error(lambda: plan_transfer([link], destination, True))
    # Exercise cross-volume move fallback without requiring another mounted disk.
    cross = source/'cross.txt'
    cross.write_text('cross-volume data')
    subprocess.run(['/usr/bin/xattr', '-w', 'com.piprot.test', 'preserve metadata', str(cross)], check=True)
    def cross_device_once(src, dst):
        if src == cross:
            raise OSError(errno.EXDEV, 'different volume')
        return rename_exclusive(src, dst)
    with patch('transfers.rename_exclusive', side_effect=cross_device_once):
        transfer_one(cross, destination/cross.name, False)
    assert not cross.exists() and (destination/cross.name).read_text() == 'cross-volume data'
    assert subprocess.check_output(['/usr/bin/xattr', '-p', 'com.piprot.test', str(destination/cross.name)]).strip() == b'preserve metadata'
    actions = Qt.DropAction.CopyAction | Qt.DropAction.MoveAction
    mime = QMimeData()
    mime.setUrls([QUrl.fromLocalFile(str(late))])
    assert drop_action(mime, Qt.KeyboardModifier.NoModifier, actions) == Qt.DropAction.CopyAction
    mime.setData(PIP_ROT_FILES, b'1')
    assert drop_action(mime, Qt.KeyboardModifier.NoModifier, actions) == Qt.DropAction.MoveAction
    assert drop_action(mime, Qt.KeyboardModifier.AltModifier, actions) == Qt.DropAction.CopyAction
    with patch('action_context.Path.home', return_value=root):
        window = Browser([str(root)])
        window.show()
        window.activateWindow()
        pump()
        tab = window.current()
        index = tab.model.index(str(destination))
        point = tab.tree.visualRect(index).center()
        # Drop another distinct file onto the actual destination row.
        drag_file = source/'drag.txt'
        drag_file.write_text('real drop')
        mime.setUrls([QUrl.fromLocalFile(str(drag_file))])
        entered = QDragEnterEvent(point, actions, mime, Qt.MouseButton.LeftButton, Qt.KeyboardModifier.NoModifier)
        QApplication.sendEvent(tab.tree.viewport(), entered)
        assert entered.isAccepted()
        dropped = QDropEvent(QPointF(point), actions, mime, Qt.MouseButton.LeftButton, Qt.KeyboardModifier.NoModifier)
        QApplication.sendEvent(tab.tree.viewport(), dropped)
        assert dropped.isAccepted() and dropped.dropAction() == Qt.DropAction.MoveAction
        for _ in range(40):
            pump()
            if not window.transfers.busy:
                break
        assert (destination/drag_file.name).read_text() == 'real drop' and not drag_file.exists()
        external = source/'external.txt'
        external.write_text('keep external original')
        mime.removeFormat(PIP_ROT_FILES)
        mime.setUrls([QUrl.fromLocalFile(str(external))])
        point = tab.tree.visualRect(tab.model.index(str(destination))).center()
        QApplication.sendEvent(tab.tree.viewport(), QDragEnterEvent(point, actions, mime, Qt.MouseButton.LeftButton, Qt.KeyboardModifier.NoModifier))
        copied = QDropEvent(QPointF(point), actions, mime, Qt.MouseButton.LeftButton, Qt.KeyboardModifier.NoModifier)
        QApplication.sendEvent(tab.tree.viewport(), copied)
        assert copied.isAccepted() and copied.dropAction() == Qt.DropAction.CopyAction
        for _ in range(40):
            pump()
            if not window.transfers.busy:
                break
        assert external.read_text() == (destination/external.name).read_text()
        # Blank space targets the tab root; ordinary files are never destinations.
        assert tab.tree.destination(QPoint(5, tab.tree.viewport().height()-5))[0] == root
        moved_index = tab.model.index(str(target))
        tab.tree.expand(index)
        pump()
        assert tab.tree.destination(tab.tree.visualRect(moved_index).center())[0] is None
        # Hovering another tab while dragging exposes that tab's destination tree.
        window.add_tab(destination)
        window.tabs.setCurrentIndex(0)
        bar = window.tabs.tabBar()
        position = bar.tabRect(1).center()
        QApplication.sendEvent(bar, QDragEnterEvent(position, actions, mime, Qt.MouseButton.LeftButton, Qt.KeyboardModifier.NoModifier))
        QApplication.sendEvent(bar, QDragMoveEvent(position, actions, mime, Qt.MouseButton.LeftButton, Qt.KeyboardModifier.NoModifier))
        for _ in range(12):
            pump()
            if window.tabs.currentIndex() == 1:
                break
        assert window.tabs.currentIndex() == 1, 'drag hover must switch tabs'
        window.close_tab(1)
        # A tab rooted inside a moved directory follows the destination.
        relocating = source/'relocating'
        inner = relocating/'inner'
        inner.mkdir(parents=True)
        window.add_tab(inner)
        window.transfer_files([relocating], destination, False)
        for _ in range(40):
            pump()
            if not window.transfers.busy:
                break
        assert window.current().root.resolve() == (destination/'relocating/inner').resolve(), window.current().root
        window.close_tab(1)
        # Close/restart cannot interrupt an active filesystem operation.
        window.transfers.pending = 1
        window.close()
        assert window.isVisible()
        window.close_tab(0)
        assert window.tabs.count() == 1
        window.transfers.pending = 0
        window.close()
print('PASS: file/folder transfers, symlinks, collision races, self-move rejection, cross-volume metadata, move/copy policy, real Qt drop and async completion, close guard')
