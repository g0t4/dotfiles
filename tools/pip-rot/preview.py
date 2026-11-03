"""Preview dispatch and lifecycle. Quick Look is the default backend."""
from PySide6.QtCore import QObject, QProcess, QTimer, Signal


def preview_command(paths):
    """Future format-specific backends can be selected here."""
    return ['/usr/bin/qlmanage', '-p', *map(str, paths)]


class PreviewController(QObject):
    error = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.process = None
        self.paths = ()
        self.pending = None
        self.stopping = False

    def toggle(self, paths):
        paths = tuple(paths)
        if not paths:
            return
        if self.process:
            self.pending = paths if paths != self.paths else None
            self.stopping = True
            self._stop_timer.start(500)
            self.process.terminate()
        else:
            self.start(paths)

    def start(self, paths):
        self.paths = paths
        self.stopping = False
        process = QProcess(self)
        self.process = process
        # Kill only our own helper if it does not exit after termination.
        timer = QTimer(process)
        timer.setSingleShot(True)
        timer.timeout.connect(process.kill)

        def completed(code=0, _status=None):
            timer.stop()
            if process is not self.process:
                return
            if code and not self.stopping:
                message = bytes(process.readAllStandardError()).decode(errors='replace').strip()
                self.error.emit(message or 'Quick Look could not preview this selection.')
            self.process = None
            process.deleteLater()
            pending, self.pending = self.pending, None
            if pending:
                self.start(pending)

        def failed(error):
            if error == QProcess.ProcessError.FailedToStart:
                self.error.emit(process.errorString())
                completed()

        process.finished.connect(completed)
        process.errorOccurred.connect(failed)
        self._stop_timer = timer
        command = preview_command(paths)
        process.start(command[0], command[1:])

    def close(self):
        self.pending = None
        if self.process:
            process = self.process
            self.stopping = True
            process.terminate()
            if not process.waitForFinished(300):
                process.kill()
                process.waitForFinished(300)
