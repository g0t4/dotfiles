"""Validate Qt's actual token colors, literal text, and trace clipboard action."""

import os
import subprocess
import sys

PREVIEW = r"""
import sys
from pathlib import Path
from types import SimpleNamespace
from PySide6.QtGui import QTextCursor
from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QTextBrowser, QPlainTextEdit, QLabel
from app import Window
from chat_theme import append_markdown, apply_chat_theme, trace_link
from wes_syntax import load_style

app = QApplication([])
window = QWidget()
window.resize(720, 540)
layout = QVBoxLayout(window)
browser, editor, status = QTextBrowser(), QPlainTextEdit(), QLabel()
layout.addWidget(browser)
layout.addWidget(editor)
layout.addWidget(status)
editor.setMaximumHeight(65)
editor.setPlaceholderText('Ask Sloppy about your video…')
apply_chat_theme(browser, editor, status, window)
window.setAutoFillBackground(True)
source = '# Frame review\n\nA **black frame** at `115` — [source](https://example.test).\n\n```python\n# Check the neighbors\nif frame == 115:\n    print("black frame")\n```\n\n<img src="no-network"> stays literal.\n'
append_markdown(browser, 'Sloppy', source)
plain = browser.toPlainText()
assert source in plain, repr(plain)
colors, _ = load_style()
def color_of(text, shift=0):
    start = plain.index(text) + shift
    cursor = QTextCursor(browser.document())
    cursor.setPosition(start)
    cursor.setPosition(start+1, QTextCursor.MoveMode.KeepAnchor)
    return cursor.charFormat().foreground().color().name()
assert color_of('# Frame') == colors['keyword']
assert color_of('black frame**') == colors['type']
assert color_of('`115`') == colors['builtin']
assert color_of('if frame') == colors['keyword']
assert color_of('"black frame"') == colors['string']
assert color_of('# Check') == colors['comment']
assert browser.palette().base().color().name() == colors['background']
assert editor.palette().text().color().name() == colors['text']
path = Path('/tmp/course review with spaces/2026-11-14_1234.jsonl')
trace_link(status, path)
target = SimpleNamespace(chat=SimpleNamespace(session=SimpleNamespace(path=path)), status=status)
status.linkActivated.connect(lambda link: Window.copy_trace_path(target, link))
status.linkActivated.emit('copy-trace')
assert QApplication.clipboard().text() == str(path.resolve())
assert str(path) in status.toolTip()
assert path.name in status.text()
assert 'Copied trace path' in status.text()
window.show()
app.processEvents()
if len(sys.argv) > 1:
    assert window.grab().save(sys.argv[1])
window.close()
print('Markdown theme and trace clipboard passed')
"""


def test_chat_theme_and_trace_clipboard():
    result = subprocess.run(
        [sys.executable, "-c", PREVIEW],
        cwd=os.path.dirname(__file__),
        env={**os.environ, "QT_QPA_PLATFORM": "offscreen"},
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr
