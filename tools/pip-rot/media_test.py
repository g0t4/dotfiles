"""Integration check using a generated two-second video, never user media."""
import shutil
import subprocess
import tempfile
from pathlib import Path

from PySide6.QtCore import QEventLoop, QTimer
from PySide6.QtWidgets import QApplication

from media import format_duration, probe_duration
from pip_rot import Browser


def pump():
    loop = QEventLoop()
    QTimer.singleShot(100, loop.quit)
    loop.exec()


assert format_duration(65) == '1:05'
assert format_duration(3661) == '1:01:01'
assert format_duration(None) == '—'
app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    empty = root / 'empty'
    empty.mkdir()
    nested = root / 'nested'
    nested.mkdir()
    movie = nested / "video $ ' name.MP4"
    subprocess.run([shutil.which('ffmpeg'), '-v', 'error', '-f', 'lavfi', '-i',
                    'color=black:s=16x16:r=1:d=2', '-c:v', 'mpeg4', str(movie)], check=True)
    window = Browser([str(empty), str(nested)])
    for _ in range(20):
        pump()
        if not window.current().tree.isColumnHidden(4):
            break
    tab = window.current()
    assert not tab.tree.isColumnHidden(4)
    index = tab.model.index(str(movie))
    duration = tab.model.index(index.row(), 4, index.parent())
    assert duration.isValid()
    for _ in range(50):
        value = tab.model.data(duration)
        if value != '…':
            break
        pump()
    assert value == '0:02', value
    assert len(window.duration_cache.values) == 1
    assert tab.model.data(duration) == '0:02'
    window.tabs.setCurrentIndex(0)
    assert window.current().tree.isColumnHidden(4)
    # A corrupt video produces a quiet unavailable value, never blocks the GUI.
    bad = nested / 'corrupt.mp4'
    bad.write_text('not video')
    assert probe_duration(shutil.which('ffprobe'), bad) is None
    window.close()
print('PASS: auto column, real ffprobe duration, async delivery, shared cache, no-video hiding, corrupt media')
