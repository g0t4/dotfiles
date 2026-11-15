"""Render real controls; separately verify native title bars when Cocoa is available."""

import os
import subprocess
import sys

import pytest

PREVIEW = r"""
import sys
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QMainWindow, QWidget, QHBoxLayout, QVBoxLayout, QLabel, QPushButton, QTextBrowser, QPlainTextEdit, QCheckBox
from PySide6.QtGui import QPalette
from macos_app import Application
from chat_theme import apply_chat_theme, append_markdown
from wes_syntax import load_style

app = Application([])
window = QMainWindow()
window.setWindowTitle('Slop Reel — course review.mp4')
window.resize(1100, 660)
root = QWidget()
window.setCentralWidget(root)
layout = QHBoxLayout(root)
left, right = QVBoxLayout(), QVBoxLayout()
layout.addLayout(left, 3)
layout.addLayout(right, 2)
video = QLabel('Video preview')
video.setAlignment(Qt.AlignmentFlag.AlignCenter)
video.setStyleSheet('background:#101319; color:#929aaa;')
left.addWidget(video, 1)
buttons = QHBoxLayout()
left.addLayout(buttons)
for name in ('Play / Pause', '◀ Frame', 'Frame ▶', 'Frame zoom'):
    buttons.addWidget(QPushButton(name))
changes = QHBoxLayout()
left.addLayout(changes)
for name in ('Previous change ↓', 'Next change ↑', 'Change sequence'):
    changes.addWidget(QPushButton(name))
left.addWidget(QLabel('14 changed frames · Up next / Down previous · Shift+Z sequence'))
browser, editor = QTextBrowser(), QPlainTextEdit()
apply_chat_theme(browser, editor)
append_markdown(browser, 'Sloppy', '# Found a one-frame flash\n\n**Frame 115** at `3.833333s` is black.\n\nIts neighbors show the same slide.\n\n```python\nframes = [114, 115, 116]\n```')
right.addWidget(browser, 1)
right.addWidget(QLabel('Trace: 2026-11-15_1234.jsonl'))
editor.setPlaceholderText('Ask Sloppy about your video…')
editor.setMaximumHeight(90)
right.addWidget(editor)
row = QHBoxLayout()
right.addLayout(row)
for name in ('Hold to talk · F6', 'Send', 'Cancel request'):
    button = QPushButton(name)
    if name.startswith('Cancel'):
        button.setEnabled(False)
    row.addWidget(button)
window.show()
app.processEvents()
colors, _ = load_style()
assert window.palette().window().color().name() == colors['background']
assert button.palette().color(QPalette.ColorGroup.Disabled, QPalette.ColorRole.ButtonText) != button.palette().color(QPalette.ColorGroup.Active, QPalette.ColorRole.ButtonText)
# Confirm the actual rendered controls have dark fills, including a popup dialog.
image = root.grab().toImage()
assert image.pixelColor(1, 1).name() == colors['background']
normal = row.itemAt(1).widget()
button_image = normal.grab().toImage()
fill = button_image.pixelColor(button_image.width()//2, 5)
assert max(fill.red(), fill.green(), fill.blue()) < 110
assert fill.name() != colors['background']
if len(sys.argv) > 1:
    assert window.grab().save(sys.argv[1])
window.close()
app.processEvents()
print('Application theme rendered successfully')
"""


def run_script(script, platform, *args):
    return subprocess.run(
        [sys.executable, "-c", script, *args],
        cwd=os.path.dirname(__file__),
        env={**os.environ, "QT_QPA_PLATFORM": platform},
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )


def test_dark_application_controls():
    result = run_script(PREVIEW, "offscreen")
    assert result.returncode == 0, result.stdout + result.stderr


@pytest.mark.skipif(sys.platform != "darwin", reason="Native Cocoa title bars")
def test_native_titlebar():
    result = run_script(
        r"""
import ctypes
from PySide6.QtWidgets import QMainWindow
from macos_app import Application
from macos_titlebar import native_window, send
from wes_syntax import load_style
app = Application([])
if not app.screens():
    raise SystemExit(77)
window = QMainWindow()
window.resize(600, 400)
window.show()
app.processEvents()
app.processEvents()
native = native_window(window)
assert native
assert send(native, 'titlebarAppearsTransparent', result=ctypes.c_bool)
assert send(native, 'standardWindowButton:', types=(ctypes.c_ulong,), values=(0,))
color = send(native, 'backgroundColor')
expected, _ = load_style()
from PySide6.QtGui import QColor
qcolor = QColor(expected['background'])
for selector, channel in [('redComponent', qcolor.redF()), ('greenComponent', qcolor.greenF()), ('blueComponent', qcolor.blueF())]:
    assert abs(send(color, selector, result=ctypes.c_double) - channel) < .001
assert window.width() == 600 and window.height() == 400
window.close()
app.processEvents()
""",
        "cocoa",
    )
    if result.returncode == 77:
        pytest.skip("No desktop screens in this execution session")
    assert result.returncode == 0, result.stdout + result.stderr
