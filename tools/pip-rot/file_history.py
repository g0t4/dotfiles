"""Record successful default-app opens without preventing an open on history errors."""
from pathlib import Path
import sys
import subprocess

from PySide6.QtCore import QUrl
from PySide6.QtGui import QDesktopServices

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / '.config/xonsh/lib'))
from wes_file_history import FileHistory


def open_tracked_file(path):
    if not QDesktopServices.openUrl(QUrl.fromLocalFile(str(path))):
        return False
    record_open(path)
    return True


def open_tracked_files(paths):
    """Hand off a selection together so media apps receive one open event."""
    paths = list(paths)
    if not paths:
        return False
    if len(paths) == 1:
        return open_tracked_file(paths[0])
    try:
        result = subprocess.run(["/usr/bin/open", *map(str, paths)], capture_output=True, text=True)
    except OSError as error:
        print(f"file open: {error}", file=sys.stderr)
        return False
    if result.returncode:
        print(f"file open: {result.stderr.strip()}", file=sys.stderr)
        return False
    for path in paths:
        record_open(path)
    return True


def record_open(path):
    try:
        FileHistory().record(path, source='pip-rot')
    except Exception as error:
        print(f'file history: could not record {path}: {error}', file=sys.stderr)
    return True
