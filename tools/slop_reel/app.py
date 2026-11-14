"""Slop Reel: player, source-frame inspection and explicit multimodal chat."""

import argparse
import sys
from concurrent.futures import ThreadPoolExecutor
from html import escape
from pathlib import Path

from PySide6.QtCore import QEvent, QObject, Qt, QTimer, Signal
from PySide6.QtGui import (
    QColor,
    QImage,
    QKeySequence,
    QPainter,
    QPen,
    QShortcut,
    QTextCursor,
)
from PySide6.QtWidgets import (
    QApplication,
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

from changes import next_change, page_changes, scan, sequence
from chat import Chat, request_content
from commands import Commands
from inspection import FrameStrip
from media import Media, waveform
from player import Player
from video_tools import VideoTools
from voice import Dictation


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


class FrameZoom(FrameStrip):
    """The familiar seven-neighbor strip, now with adjacent frame diffs."""


class Window(QMainWindow):
    tool_status = Signal(str)
    change_progress = Signal(int, int)
    review_closed = Signal(object)

    def __init__(self, path, trace_dir=None):
        super().__init__()
        self.path = path
        self.setWindowTitle(f"Slop Reel — {path.name}")
        self.resize(1400, 850)
        self.closed = False
        self.commands = Commands()
        self.media = None
        self.changes = None
        self.change_error = None
        self.change_dialog = None
        self.change_target = None
        self.pending_review = None
        self.review_busy = False
        self.busy = False
        self.chat = Chat(trace_dir)
        self.chat.video = VideoTools(
            path, Commands(), self.chat.cancelled, self.tool_status.emit
        )
        self.chat.notify = self.tool_status.emit
        self.tool_status.connect(self.show_tool_status)
        self.media_jobs, self.chat_jobs, self.wave_jobs = (
            Jobs(self),
            Jobs(self),
            Jobs(self),
        )
        self.player = Player(path)
        self.player.navigation.connect(self.clear_change_target)
        self.player.failed.connect(lambda error: self.notice("Playback error", error))
        self.change_jobs = Jobs(self)
        self.change_progress.connect(self.change_scanning)
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
        review = QHBoxLayout()
        for label, callback in [
            ("Previous change ↓", lambda: self.jump_change(-1)),
            ("Next change ↑", lambda: self.jump_change(1)),
            ("Change sequence", self.show_changes),
        ]:
            button = QPushButton(label)
            button.clicked.connect(callback)
            review.addWidget(button)
        layout.addLayout(review)
        self.change_status = QLabel("Waiting for frame index…")
        layout.addWidget(self.change_status)
        QApplication.instance().installEventFilter(self)
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
        self.dictation = Dictation(self)
        self.dictation_cursor = None
        self.dictation.transcript.connect(self.insert_dictation)
        self.dictation.status.connect(self.status.setText)
        self.dictation.active_changed.connect(self.dictation_active)
        self.talk_button = QPushButton("Hold to talk · F6")
        self.talk_button.setToolTip(
            "Private Whisper dictation via voiced; release to insert, then send."
        )
        self.talk_button.pressed.connect(self.start_dictation)
        self.talk_button.released.connect(self.dictation.release)
        row.addWidget(self.talk_button)
        row.addWidget(self.send_button)
        row.addWidget(self.cancel_button)
        chat_layout.addLayout(row)
        split = QSplitter()
        split.addWidget(left)
        split.addWidget(right)
        split.setSizes([900, 500])
        self.setCentralWidget(split)
        for key, callback in [("F9", self.close), ("Ctrl+Return", self.send)]:
            if key == "F9" and hasattr(QApplication.instance(), "close_reviews"):
                continue  # The desktop application owns one global quit action.
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

    def eventFilter(self, watched, event):
        if (
            not self.closed
            and isinstance(watched, QWidget)
            and (watched is self or self.isAncestorOf(watched))
        ):
            if (
                event.type() in (QEvent.Type.KeyPress, QEvent.Type.KeyRelease)
                and event.key() == Qt.Key.Key_F6
            ):
                if not event.isAutoRepeat():
                    if event.type() == QEvent.Type.KeyPress:
                        self.start_dictation()
                    else:
                        self.dictation.release()
                return True
            if watched is self and event.type() == QEvent.Type.WindowDeactivate:
                self.dictation.release()
        # Capture player keys before focused buttons/scroll views consume them;
        # leave all editor keys alone, including ordinary Up/Down text navigation.
        if (
            not self.closed
            and event.type() == QEvent.Type.KeyPress
            and isinstance(watched, QWidget)
            and (
                watched is self
                or self.isAncestorOf(watched)
                or watched.window().parentWidget() is self
            )
            and not self.input.hasFocus()
            and watched is not self.input
            and not self.input.isAncestorOf(watched)
        ):
            key = event.key()
            if key == Qt.Key.Key_Up:
                self.jump_change(1)
            elif key == Qt.Key.Key_Down:
                self.jump_change(-1)
            elif key == Qt.Key.Key_Space:
                self.toggle()
            elif key == Qt.Key.Key_Right:
                self.player.step(1)
            elif key == Qt.Key.Key_Left:
                self.player.step(-1)
            elif key == Qt.Key.Key_Z:
                if event.modifiers() & Qt.KeyboardModifier.ShiftModifier:
                    self.show_changes()
                else:
                    self.zoom()
            else:
                return super().eventFilter(watched, event)
            return True
        return super().eventFilter(watched, event)

    def change_scanning(self, count, total):
        if not self.closed:
            self.change_status.setText(f"Scanning frame changes: {count}/{total}…")

    def changes_ready(self, changes, error):
        if self.closed:
            return
        if error:
            self.change_error = str(error)
            self.change_status.setText(f"Change scan unavailable: {error}")
        else:
            self.changes = changes
            self.change_status.setText(
                f"{len(changes)} changed frames · Up next / Down previous · Shift+Z sequence"
            )

    def ready_to_review(self):
        if self.changes is None:
            if self.change_error:
                self.change_status.setText(
                    f"Change scan unavailable: {self.change_error}"
                )
            else:
                self.change_status.setText("Change index is still scanning…")
            return False
        if not self.changes:
            self.change_status.setText("No material frame changes detected.")
            return False
        return True

    def clear_change_target(self):
        self.change_target = None

    def jump_change(self, direction):
        if not self.ready_to_review():
            return
        self.player.engine.pause = True
        index = (
            self.change_target
            if self.change_target is not None
            else self.media.index_at(self.player.position)
        )
        change = next_change(self.changes, index, direction)
        if change is None:
            self.change_status.setText(
                "No later change." if direction > 0 else "No earlier change."
            )
            return
        self.player.seek(change.seconds)
        self.change_target = change.index
        self.change_status.setText(
            f"Change #{change.index} · {change.seconds:.6f}s · {change.fraction:.2%} pixels"
        )
        if self.change_dialog and self.change_dialog.isVisible():
            self.show_changes(frame_index=change.index)

    def show_changes(self, checked=False, *, frame_index=None, selection=None):
        if not self.ready_to_review():
            return
        if self.review_busy:
            self.pending_review = (frame_index, selection)
            return
        self.player.engine.pause = True
        index = (
            self.media.index_at(self.player.position)
            if frame_index is None
            else frame_index
        )
        if selection is None:
            center, selected = sequence(self.changes, index)
        else:
            selected = selection
            center = selected[min(3, len(selected) - 1)].index
        indices = [change.index for change in selected]
        self.review_busy = True
        self.change_status.setText("Loading changed frames…")

        def extract():
            nearby = self.media.frames_at(
                [i for index in indices for i in (index - 1, index)]
            )
            by_index = {frame.index: frame for frame in nearby}
            return [by_index[i] for i in indices], by_index

        def ready(result, error):
            self.review_busy = False
            if self.closed:
                return
            if self.pending_review is not None:
                frame_index, selection = self.pending_review
                self.pending_review = None
                self.show_changes(frame_index=frame_index, selection=selection)
                return
            if error:
                self.change_status.setText(f"Change sequence unavailable: {error}")
                return
            frames, predecessors = result
            old = self.change_dialog

            def page(dialog, direction):
                boundary = max(dialog.frames) if direction > 0 else min(dialog.frames)
                items = page_changes(self.changes, boundary, direction)
                if items:
                    self.show_changes(selection=items)
                else:
                    self.change_status.setText(
                        "No later changes." if direction > 0 else "No earlier changes."
                    )

            dialog = FrameStrip(
                self,
                center,
                frames,
                predecessors=predecessors,
                slots=indices,
                title="Material changes — each diff compares to its previous source frame",
                page=page,
            )
            dialog.setWindowModality(Qt.WindowModality.WindowModal)
            if old:
                dialog.diff.setChecked(old.diff.isChecked())
                old.close()
                old.deleteLater()
            self.change_dialog = dialog
            dialog.show()
            self.change_status.setText(
                f"Showing {len(frames)} changed frames · Up/Down to step changes"
            )

        self.media_jobs.submit(extract, ready)

    def toggle(self):
        self.clear_change_target()
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
            self.change_status.setText("Scanning frame changes…")
            self.change_jobs.submit(
                lambda: scan(
                    self.path, media.times, self.commands, self.change_progress.emit
                ),
                self.changes_ready,
            )

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
                center, frames, predecessors = result
                dialog = FrameZoom(self, center, frames, predecessors=predecessors)
                dialog.exec()
                dialog.deleteLater()

        self.media_jobs.submit(lambda: self.media.inspection(position), ready)

    def append_text(self, title, text):
        cursor = self.transcript.textCursor()
        cursor.movePosition(QTextCursor.MoveOperation.End)
        cursor.insertHtml(f"<p><b>{escape(title)}</b></p>")
        cursor.insertBlock()
        cursor.insertMarkdown(text)
        cursor.insertText("\n\n")
        self.transcript.setTextCursor(cursor)
        self.transcript.ensureCursorVisible()

    def show_tool_status(self, text):
        if not self.closed:
            self.status.setText(text)
            self.append_text("Inspection", text)

    def start_dictation(self):
        if not self.dictation.active:
            self.dictation_cursor = self.input.textCursor()
            self.dictation.press()

    def dictation_active(self, active):
        self.send_button.setEnabled(not active and not self.busy)
        self.input.setReadOnly(active)

    def insert_dictation(self, text):
        cursor = self.dictation_cursor or self.input.textCursor()
        before = self.input.toPlainText()[: cursor.selectionStart()]
        after = self.input.toPlainText()[cursor.selectionEnd() :]
        cursor.insertText(
            (" " if before and not before[-1].isspace() else "")
            + text
            + (" " if after and not after[0].isspace() else "")
        )
        self.input.setTextCursor(cursor)
        self.input.setFocus()

    def send(self):
        text = self.input.toPlainText().strip()
        if not text or self.busy or self.dictation.active:
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
        self.chat.video.commands.stop()
        self.status.setText("Cancelling…")

    def answered(self, answer, error):
        if self.closed:
            return
        self.busy = False
        self.send_button.setEnabled(not self.dictation.active)
        self.cancel_button.setEnabled(False)
        if error:
            self.append_text("Error", str(error))
        elif answer is not None:
            self.append_text("Sloppy", answer)
        else:
            self.append_text("Status", "Request cancelled.")
        self.status.setText(f"Trace: {self.chat.session.path.name}")

    def closeEvent(self, event):
        self.closed = True
        QApplication.instance().removeEventFilter(self)
        self.dictation.close()
        self.chat.video.commands.stop()
        self.commands.stop()
        self.timer.stop()
        self.chat.cancelled.set()
        self.player.close_player()
        if self.media:
            self.media_jobs.pool.submit(self.media.close)
        self.chat_jobs.pool.submit(self.chat.close)
        for jobs in (self.media_jobs, self.wave_jobs, self.chat_jobs, self.change_jobs):
            jobs.pool.shutdown(wait=False)
        event.accept()
        self.review_closed.emit(self)


def main():
    parser = argparse.ArgumentParser(
        description="Video inspection with local multimodal chat"
    )
    parser.add_argument(
        "videos",
        type=Path,
        nargs="*",
        help="Videos to open, one review window per file",
    )
    args = parser.parse_args()
    for video in args.videos:
        if not video.expanduser().is_file():
            parser.error(f"Video does not exist: {video}")
    from macos_app import Application

    app = Application(sys.argv[:1])
    app.start(args.videos)
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
