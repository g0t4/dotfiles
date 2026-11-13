"""Slop Reel: player, source-frame inspection and explicit multimodal chat."""

import argparse
import sys
from concurrent.futures import ThreadPoolExecutor
from html import escape
from pathlib import Path

from PySide6.QtCore import QObject, Qt, QTimer, Signal
from PySide6.QtGui import (
    QColor,
    QImage,
    QKeySequence,
    QPainter,
    QPen,
    QPixmap,
    QShortcut,
    QTextCursor,
)
from PySide6.QtWidgets import (
    QApplication,
    QDialog,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPlainTextEdit,
    QPushButton,
    QSplitter,
    QTextBrowser,
    QVBoxLayout,
    QWidget,
)

from chat import Chat, request_content
from commands import Commands
from media import Media, waveform
from player import Player


class Jobs(QObject):
    done = Signal(object, object, object)

    def __init__(self, parent):
        super().__init__(parent)
        self.pool = ThreadPoolExecutor(max_workers=1)
        self.done.connect(self.deliver)

    def submit(self, function, callback):
        future = self.pool.submit(function)

        def finished(future):
            try:
                result, error = future.result(), None
            except Exception as exc:
                result, error = None, exc
            self.done.emit(callback, result, error)

        future.add_done_callback(finished)

    def deliver(self, callback, result, error):
        callback(result, error)


class Waveform(QWidget):
    seek = Signal(float)

    def __init__(self):
        super().__init__()
        self.duration, self.position, self.peaks = 1, 0, []
        self.setMinimumHeight(85)
        self.setToolTip("Click to seek")

    def paintEvent(self, event):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor("#171b23"))
        p.setPen(QPen(QColor("#6ab7c8"), 1))
        mid = self.height() / 2
        for x in range(self.width()):
            if self.peaks:
                peak = self.peaks[
                    min(len(self.peaks) - 1, int(x / self.width() * len(self.peaks)))
                ]
                p.drawLine(x, int(mid - peak * mid), x, int(mid + peak * mid))
        p.setPen(QPen(QColor("#ffcc66"), 2))
        x = int(self.position / max(0.001, self.duration) * self.width())
        p.drawLine(x, 0, x, self.height())

    def mousePressEvent(self, event):
        self.seek.emit(event.position().x() / self.width() * self.duration)


def frame_pixmap(frame, width=300):
    image = QImage.fromData(frame.jpeg)
    return QPixmap.fromImage(image).scaledToWidth(
        width, Qt.TransformationMode.SmoothTransformation
    )


class FrameZoom(QDialog):
    def __init__(self, parent, center, frames):
        super().__init__(parent)
        self.setWindowTitle("Frames around playhead — click a frame to select")
        layout = QGridLayout(self)
        by_index = {f.index: f for f in frames}
        for slot, index in enumerate(range(center - 3, center + 4)):
            frame = by_index.get(index)
            box = QWidget()
            contents = QVBoxLayout(box)
            if frame:
                button = QPushButton()
                from PySide6.QtGui import QIcon

                pixmap = frame_pixmap(frame)
                button.setIcon(QIcon(pixmap))
                button.setIconSize(pixmap.size())
                button.clicked.connect(
                    lambda checked=False, t=frame.seconds: parent.player.seek(t)
                )
                contents.addWidget(button)
                contents.addWidget(
                    QLabel(
                        f"Frame {frame.index} · {frame.seconds:.6f}s · {index - center:+d}"
                    )
                )
            else:
                contents.addWidget(QLabel("No frame (start/end of video)"))
            if index == center:
                box.setStyleSheet("background:#394355;")
            layout.addWidget(box, slot // 4, slot % 4)
        self.resize(1250, 500)


class Window(QMainWindow):
    def __init__(self, path, trace_dir=None):
        super().__init__()
        self.path = path
        self.setWindowTitle(f"Slop Reel — {path.name}")
        self.resize(1400, 850)
        self.closed = False
        self.commands = Commands()
        self.media = None
        self.busy = False
        self.chat = Chat(trace_dir)
        self.media_jobs, self.chat_jobs, self.wave_jobs = (
            Jobs(self),
            Jobs(self),
            Jobs(self),
        )
        self.player = Player(path)
        self.player.failed.connect(lambda error: self.notice("Playback error", error))
        self.wave = Waveform()
        self.wave.seek.connect(self.player.seek)
        self.clock = QLabel("Loading media…")
        left = QWidget()
        layout = QVBoxLayout(left)
        layout.addWidget(self.player, 1)
        layout.addWidget(self.wave)
        controls = QHBoxLayout()
        for label, callback in [
            ("Play / Pause", self.toggle),
            ("◀ Frame", lambda: self.player.step(-1)),
            ("Frame ▶", lambda: self.player.step(1)),
            ("Frame zoom", self.zoom),
        ]:
            button = QPushButton(label)
            button.clicked.connect(callback)
            controls.addWidget(button)
        controls.addWidget(self.clock)
        layout.addLayout(controls)
        right = QWidget()
        chat_layout = QVBoxLayout(right)
        self.transcript = QTextBrowser()
        self.transcript.setOpenExternalLinks(True)
        self.input = QPlainTextEdit()
        self.input.setMaximumHeight(110)
        self.input.setPlaceholderText(
            "Chat, /frame question, or /frames question\nCtrl+Return to send"
        )
        self.status = QLabel(f"Trace: {self.chat.session.path.name}")
        self.send_button = QPushButton("Send")
        self.send_button.clicked.connect(self.send)
        self.cancel_button = QPushButton("Cancel request")
        self.cancel_button.setEnabled(False)
        self.cancel_button.clicked.connect(self.cancel)
        chat_layout.addWidget(self.transcript, 1)
        chat_layout.addWidget(self.status)
        chat_layout.addWidget(self.input)
        row = QHBoxLayout()
        row.addWidget(self.send_button)
        row.addWidget(self.cancel_button)
        chat_layout.addLayout(row)
        split = QSplitter()
        split.addWidget(left)
        split.addWidget(right)
        split.setSizes([900, 500])
        self.setCentralWidget(split)
        for key, callback in [("F9", self.close), ("Ctrl+Return", self.send)]:
            shortcut = QShortcut(QKeySequence(key), self)
            if key == "F9":
                shortcut.setContext(Qt.ShortcutContext.ApplicationShortcut)
            shortcut.activated.connect(callback)
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.tick)
        self.timer.start(40)
        self.media_jobs.submit(lambda: Media(path, self.commands), self.media_ready)
        self.wave_jobs.submit(
            lambda: waveform(path, commands=self.commands), self.wave_ready
        )

    def keyPressEvent(self, event):
        if event.key() == Qt.Key.Key_Space and not self.input.hasFocus():
            self.toggle()
        elif event.key() == Qt.Key.Key_Right and not self.input.hasFocus():
            self.player.step(1)
        elif event.key() == Qt.Key.Key_Left and not self.input.hasFocus():
            self.player.step(-1)
        elif event.key() == Qt.Key.Key_Z and not self.input.hasFocus():
            self.zoom()
        else:
            super().keyPressEvent(event)

    def toggle(self):
        self.player.engine.pause = not self.player.engine.pause

    def tick(self):
        position = self.player.position
        self.wave.position = position
        self.wave.update()
        self.clock.setText(f"{position:.3f} / {self.wave.duration:.3f}s")

    def media_ready(self, media, error):
        if self.closed:
            if media:
                media.close()
            return
        if error:
            self.notice("Frame decoding unavailable", str(error))
        else:
            self.media = media

    def wave_ready(self, result, error):
        if self.closed:
            return
        if error:
            self.status.setText(f"Waveform unavailable: {error}")
        else:
            self.wave.duration, self.wave.peaks = result
            self.wave.update()

    def notice(self, title, text):
        QMessageBox.warning(self, title, text)

    def zoom(self):
        if not self.media:
            self.status.setText("Frame index is not ready yet.")
            return
        self.player.engine.pause = True
        position = self.player.position

        def ready(result, error):
            if self.closed:
                return
            if error:
                self.notice("Frame extraction failed", str(error))
            else:
                FrameZoom(self, *result).exec()

        self.media_jobs.submit(lambda: self.media.frames(position), ready)

    def append_text(self, title, text):
        cursor = self.transcript.textCursor()
        cursor.movePosition(QTextCursor.MoveOperation.End)
        cursor.insertHtml(f"<p><b>{escape(title)}</b></p>")
        cursor.insertBlock()
        cursor.insertMarkdown(text)
        cursor.insertText("\n\n")
        self.transcript.setTextCursor(cursor)
        self.transcript.ensureCursorVisible()

    def send(self):
        text = self.input.toPlainText().strip()
        if not text or self.busy:
            return
        command = text.partition(" ")[0]
        if command.startswith("/") and command not in ("/frame", "/frames"):
            self.status.setText("Use /frame [question] or /frames [question].")
            return
        if command in ("/frame", "/frames") and not self.media:
            self.status.setText("Wait for the source frame index to finish loading.")
            return
        position = self.player.position
        self.busy = True
        self.send_button.setEnabled(False)
        self.cancel_button.setEnabled(True)
        self.input.clear()
        self.append_text("You", text)
        self.status.setText(
            "Extracting frames…" if command.startswith("/") else "Thinking…"
        )

        def prepared(result, error):
            if self.closed:
                return
            if error:
                self.answered(None, error)
                return
            if self.chat.cancelled.is_set():
                self.answered(None, None)
                return
            center, frames = result
            if frames:
                from PySide6.QtCore import QUrl
                from PySide6.QtGui import QTextImageFormat

                cursor = self.transcript.textCursor()
                cursor.movePosition(QTextCursor.MoveOperation.End)
                for frame in frames:
                    name = QUrl(f"frame:{self.chat.session.turn + 1}/{frame.index}")
                    self.transcript.document().addResource(
                        2, name, QImage.fromData(frame.jpeg)
                    )
                    fmt = QTextImageFormat()
                    fmt.setName(name.toString())
                    fmt.setWidth(160)
                    fmt.setHeight(
                        160
                        * QImage.fromData(frame.jpeg).height()
                        / QImage.fromData(frame.jpeg).width()
                    )
                    cursor.insertImage(fmt)
                    cursor.insertText(f" #{frame.index} {frame.seconds:.6f}s\n")
                self.transcript.setTextCursor(cursor)
            try:
                content = request_content(text, frames, center)
            except Exception as exc:
                self.answered(None, exc)
                return
            metadata = {
                "path": str(self.path),
                "playhead_seconds": position,
                "frames": [{"index": f.index, "seconds": f.seconds} for f in frames],
            }
            self.status.setText("Thinking…")
            self.chat_jobs.submit(
                lambda: self.chat.ask(content, metadata), self.answered
            )

        self.chat.cancelled.clear()
        if command in ("/frame", "/frames"):
            radius = 0 if command == "/frame" else 3
            self.media_jobs.submit(
                lambda: self.media.frames(position, radius), prepared
            )
        else:
            prepared((None, []), None)

    def cancel(self):
        self.chat.cancelled.set()
        self.status.setText("Cancelling…")

    def answered(self, answer, error):
        if self.closed:
            return
        self.busy = False
        self.send_button.setEnabled(True)
        self.cancel_button.setEnabled(False)
        if error:
            self.append_text("Error", str(error))
        elif answer is not None:
            self.append_text("Slop Reel", answer)
        else:
            self.append_text("Status", "Request cancelled.")
        self.status.setText(f"Trace: {self.chat.session.path.name}")

    def closeEvent(self, event):
        self.closed = True
        self.commands.stop()
        self.timer.stop()
        self.chat.cancelled.set()
        self.player.close_player()
        if self.media:
            self.media_jobs.pool.submit(self.media.close)
        self.chat_jobs.pool.submit(self.chat.close)
        for jobs in (self.media_jobs, self.wave_jobs, self.chat_jobs):
            jobs.pool.shutdown(wait=False)
        event.accept()


def main():
    parser = argparse.ArgumentParser(
        description="Video inspection with local multimodal chat"
    )
    parser.add_argument("video", type=Path)
    args = parser.parse_args()
    if not args.video.is_file():
        parser.error(f"Video does not exist: {args.video}")
    app = QApplication(sys.argv)
    app.setApplicationName("Slop Reel")
    app.setStyle("Fusion")
    window = Window(args.video.resolve())
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
