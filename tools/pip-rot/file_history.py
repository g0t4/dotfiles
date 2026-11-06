"""Record successful default-app opens without preventing an open on history errors."""
from pathlib import Path
import sys

from PySide6.QtCore import QUrl
from PySide6.QtGui import QDesktopServices

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / '.config/xonsh/lib'))
from wes_file_history import FileHistory


def open_tracked_file(path):
    if not QDesktopServices.openUrl(QUrl.fromLocalFile(str(path))):
        return False
    try:
        FileHistory().record(path, source='pip-rot')
    except Exception as error:
        print(f'file history: could not record {path}: {error}', file=sys.stderr)
    return True
