"""Bundle identity and Qt delivery of macOS folder-open events."""
from pathlib import Path
import sys
from PySide6.QtCore import QEvent, QTimer
from PySide6.QtWidgets import QApplication


def bundle_executable():
    path = Path.home() / 'Applications/Pip Rot.app/Contents/MacOS/Pip Rot'
    return path if path.is_file() else None


def launch_command(arguments):
    executable = bundle_executable()
    if executable:
        return [str(executable), *map(str, arguments)]
    return [sys.executable, str(Path(__file__).with_name('pip_rot.py')), *map(str, arguments)]


class Application(QApplication):
    def __init__(self, argv):
        self.pending = []
        self.windows = []
        self.ready = False
        self.last_browser = None
        super().__init__(argv)
        self.focusWindowChanged.connect(self.remember_window)

    def remember_window(self, handle):
        for window in self.windows:
            if handle is not None and window.windowHandle() == handle:
                self.last_browser = window
                break

    def event(self, event):
        if event.type() == QEvent.Type.FileOpen:
            path = Path(event.file())
            if self.ready:
                self.open_paths([path])
            else:
                self.pending.append(path)
            return True
        return super().event(event)

    def open_paths(self, paths):
        from pip_rot import Browser
        from restart import RestartController
        window = Browser(paths, record_history=True)
        window.restart_controller = RestartController(window)
        self.windows.append(window)
        self.last_browser = window
        window.show()
        window.publish_selection()
        window.raise_()
        window.activateWindow()
        return window

    def start_bundle(self):
        def start():
            self.ready = True
            paths, self.pending = self.pending, []
            self.open_paths(paths or [Path.home()])
        QTimer.singleShot(150, start)
