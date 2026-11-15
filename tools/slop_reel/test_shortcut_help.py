"""Deliver real Qt key events to the review's shortcut handler and chat editor."""

import os
import subprocess
import sys


def test_question_help_preserves_chat_typing_and_modal_keys():
    script = r"""
from types import SimpleNamespace
from PySide6.QtCore import Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QMainWindow, QWidget, QVBoxLayout, QPlainTextEdit, QPushButton, QLabel
from app import Window
from macos_app import Application

class Review(Window):
    def __init__(self):
        QMainWindow.__init__(self)
        self.closed = False
        self.shortcut_help = None
        self.dictation = SimpleNamespace(release=lambda: None)
        self.jumps = []
        self.jump_change = self.jumps.append
        root = QWidget()
        self.setCentralWidget(root)
        layout = QVBoxLayout(root)
        self.input = QPlainTextEdit()
        self.button = QPushButton('?')
        self.button.clicked.connect(self.show_shortcuts)
        layout.addWidget(self.input)
        layout.addWidget(self.button)
    def closeEvent(self, event):
        event.accept()

app = Application([])
window = Review()
app.installEventFilter(window)
window.show()
window.activateWindow()
app.processEvents()
window.input.setFocus()
QTest.keyClicks(window.input, '?')
assert window.input.toPlainText() == '?'
assert window.shortcut_help is None
window.button.setFocus()
app.processEvents()
QTest.keyClicks(window.button, '?')
app.processEvents()
dialog = window.shortcut_help
assert dialog is not None and dialog.isVisible()
labels = [item.text() for item in dialog.findChildren(QLabel)]
assert 'Previous / next material change' in labels
assert 'F6 (hold)' in labels
assert 'Send message' in labels
QTest.keyClick(dialog, Qt.Key.Key_Up)
QTest.keyClick(dialog, Qt.Key.Key_Down)
assert not window.jumps  # Reading help must not navigate the underlying video.
QTest.keyClick(dialog, Qt.Key.Key_Escape)
assert not dialog.isVisible()
window.button.click()
assert window.shortcut_help is dialog and dialog.isVisible()
QTest.keyClick(dialog, Qt.Key.Key_Escape)
app.removeEventFilter(window)
window.close()
app.processEvents()
print('Shortcut help, Escape, and editor isolation passed')
"""
    result = subprocess.run(
        [sys.executable, "-c", script],
        cwd=os.path.dirname(__file__),
        env={**os.environ, "QT_QPA_PLATFORM": "offscreen"},
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr
