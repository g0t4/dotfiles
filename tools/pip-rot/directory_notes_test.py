"""Real Qt layout, live note edits/replacement, navigation, and model refresh."""
from pathlib import Path
import tempfile
import time

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
    (root / '.pip-rot.md').write_text('# Course\n\nRecord intro next.')
    note = folder / '.pip-rot.md'
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
    note.write_bytes(b'\xff' + b'a' * LIMIT)
    assert '[Note truncated' in read_note(folder)
    assert '\ufffd' in read_note(folder)
    tab.close()
print('directory notes passed')
