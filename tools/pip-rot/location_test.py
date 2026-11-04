"""Address-bar navigation contract, using real files and real Yes/No dialogs."""
import tempfile
from pathlib import Path
from unittest.mock import patch

from PySide6.QtCore import Qt, QTimer
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QMessageBox

from pip_rot import Browser


app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    target = root / 'existing directory'
    target.mkdir()
    movie = target / 'my movie.mov'
    movie.touch()
    window = Browser([str(root)])
    window.show()

    def enter(text):
        window.location.setText(text)
        window.location.setFocus()
        QTest.keyClick(window.location, Qt.Key.Key_Return)

    def assert_location(path):
        assert window.current().root == path
        assert window.location.text() == str(path)

    # Existing directories and file paths both normalize the displayed address.
    with patch('pip_rot.QMessageBox.question') as question:
        enter(str(movie))
        assert_location(target)
        window.move_history(-1)
        assert_location(root)
        enter('existing directory/my movie.mov')
        assert_location(target)
        enter('../existing directory')
        assert_location(target)
        with patch.dict('os.environ', {'HOME': str(root)}):
            enter('~/existing directory/my movie.mov')
        assert_location(target)
        question.assert_not_called()

    window.move_history(-1)
    assert_location(root)
    missing = 'existing directory/missing/deeper/leaf'
    history = list(window.current().history)
    history_index = window.current().history_index
    seen = []

    def answer(button):
        dialog = app.activeModalWidget()
        if not isinstance(dialog, QMessageBox):
            QTimer.singleShot(10, lambda: answer(button))
            return
        seen.append(dialog.text())
        assert str(target) in dialog.text()
        assert str(root / missing) in dialog.text()
        assert dialog.standardButtons() == (
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        assert dialog.defaultButton() == dialog.button(QMessageBox.StandardButton.No)
        dialog.button(button).click()

    # No leaves the typed string, current tab, and history untouched for editing.
    QTimer.singleShot(0, lambda: answer(QMessageBox.StandardButton.No))
    enter(missing)
    assert window.current().root == root
    assert window.location.text() == missing
    assert window.current().history == history
    assert window.current().history_index == history_index
    app.processEvents()
    assert window.focusWidget() == window.location

    # Yes finds the nearest directory across multiple missing parents.
    QTimer.singleShot(0, lambda: answer(QMessageBox.StandardButton.Yes))
    enter(missing)
    assert_location(target)
    window.move_history(-1)
    assert_location(root)
    window.move_history(1)
    assert_location(target)
    assert len(seen) == 2

    # A non-directory ancestor must be skipped too (e.g. a pasted file/child).
    with patch('pip_rot.QMessageBox.question', return_value=QMessageBox.StandardButton.Yes):
        enter(str(movie / 'missing'))
    assert_location(target)
    assert window.tabs.count() == 1
    window.close()
print('PASS: file parents, relative/tilde paths, nearest existing ancestor, real Yes/No dialogs, address preservation, history')
