"""Real Qt layout, live note edits/replacement, navigation, and model refresh."""
from pathlib import Path
import tempfile
import time

from PySide6.QtCore import Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication

from directory_notes import LIMIT, read_note
from media import DurationCache
from pip_rot import FileTab

app = QApplication([])


def wait(predicate):
    deadline = time.monotonic() + 5
    while not predicate():
        assert time.monotonic() < deadline, 'notes did not update'
        QTest.qWait(20)


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    folder = root / 'project'
    folder.mkdir()
    (folder / 'take.mkv').touch()
    (root / '.rotten.md').write_text('# Course\n\nRecord intro next.')
    note = folder / '.rotten.md'
    note.write_text('**Best take:** 03\n\nKeep fallbacks.')
    tab = FileTab(root, DurationCache())
    tab.resize(900, 600)
    tab.show()
    wait(lambda: tab.tree.notes.root_box.isVisible())
    assert 'Record intro next.' in tab.tree.notes.root_box.toPlainText()
    wait(lambda: tab.model.index(str(folder)).isValid())
    index = tab.model.index(str(folder))
    tab.tree.expand(index)
    wait(lambda: tab.tree.notes.extra_height(index) > 0)
    assert tab.tree.visualRect(index).height() > 45
    # Every column reserves the same note height; metadata stays on the name line.
    assert tab.tree.notes.extra_height(index) == tab.tree.notes.extra_height(index.siblingAtColumn(3))
    assert tab.tree.notes.document(index).toPlainText().startswith('Best take: 03')
    tab.tree.collapse(index)
    assert tab.tree.notes.extra_height(index) == 0
    tab.tree.expand(index)
    # Atomic save must reattach the file watcher.
    replacement = folder / 'temporary'
    replacement.write_text('Updated via atomic save')
    replacement.replace(note)
    wait(lambda: tab.tree.notes.texts.get(str(folder)) == 'Updated via atomic save')
    note.write_text('Second edit')
    wait(lambda: tab.tree.notes.texts.get(str(folder)) == 'Second edit')
    note.unlink()
    wait(lambda: tab.tree.notes.extra_height(index) == 0)
    note.write_text('Recreated')
    wait(lambda: tab.tree.notes.extra_height(index) > 0)
    tab.navigate(folder)
    wait(lambda: tab.tree.notes.root_box.toPlainText() == 'Recreated')
    tab.refresh()
    wait(lambda: tab.refresh_state is None)
    wait(lambda: tab.tree.notes.root_box.toPlainText() == 'Recreated')
    note.write_text('After refresh')
    wait(lambda: tab.tree.notes.root_box.toPlainText() == 'After refresh')
    notes = tab.tree.notes
    # Clicking descriptions must not open the editor; watcher updates preserve explicit drafts.
    QTest.mouseClick(notes.root_box.viewport(), Qt.MouseButton.LeftButton)
    assert notes.editing is None
    notes.begin_edit(folder)
    assert notes.editing == str(folder)
    notes.input.setPlainText('**Edited**\n\nTwo paragraphs.')
    note.write_text('External change')
    QTest.qWait(150)
    assert notes.input.toPlainText() == '**Edited**\n\nTwo paragraphs.'
    QTest.keyClick(notes.input, Qt.Key.Key_Return, Qt.KeyboardModifier.ControlModifier)
    assert notes.editing is None
    assert note.read_text() == '**Edited**\n\nTwo paragraphs.'  # Last write wins.
    notes.begin_edit(folder)
    notes.input.setPlainText('Discard this')
    QTest.keyClick(notes.input, Qt.Key.Key_Escape)
    assert note.read_text().startswith('**Edited**')
    assert notes.editing is None
    # Start notes for a directory with no file, and preserve the draft on a save error.
    fresh = folder / 'fresh'
    fresh.mkdir()
    notes.begin_edit(fresh)
    notes.input.setPlainText('# New notes')
    (fresh / '.rotten.md').mkdir()  # Cannot replace a directory with a note.
    notes.save()
    assert notes.editing == str(fresh)
    assert 'Could not save' in notes.error.text()
    (fresh / '.rotten.md').rmdir()
    notes.save()
    assert (fresh / '.rotten.md').read_text() == '# New notes'
    tab.navigate(root)
    wait(lambda: tab.tree.notes.root_box.isVisible())
    index = tab.model.index(str(folder))
    tab.tree.expand(index)
    wait(lambda: notes.extra_height(index) > 0)
    point = tab.tree.visualRect(index).bottomLeft()
    point.setX(point.x() + 40)
    point.setY(point.y() - 8)
    QTest.mouseClick(tab.tree.viewport(), Qt.MouseButton.LeftButton, pos=point)
    assert notes.editing is None
    notes.begin_edit(folder)
    assert notes.editing == str(folder)
    notes.input.setPlainText('Nested edit')
    notes.save()
    assert note.read_text() == 'Nested edit'
    note.write_bytes(b'\xff' + b'a' * LIMIT)
    assert '[Note truncated' in read_note(folder)
    assert '\ufffd' in read_note(folder)
    tab.close()
print('directory notes passed')
