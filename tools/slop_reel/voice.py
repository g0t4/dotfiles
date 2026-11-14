"""Private push-to-talk client for the resident voiced Whisper daemon."""

import json
import os
from pathlib import Path

from PySide6.QtCore import QObject, QTimer, Signal
from PySide6.QtNetwork import QLocalSocket


class Dictation(QObject):
    transcript = Signal(str)
    status = Signal(str)
    active_changed = Signal(bool)

    def __init__(self, parent=None, path=None):
        super().__init__(parent)
        state = Path(os.getenv("XDG_STATE_HOME", str(Path.home() / ".local/state")))
        self.path = str(
            path
            or os.getenv(
                "SLOP_REEL_VOICED_SOCKET", str(state / "ask-openai/voiced.sock")
            )
        )
        self.socket = QLocalSocket(self)
        self.socket.connected.connect(lambda: self.send("hello"))
        self.socket.readyRead.connect(self.read)
        self.socket.errorOccurred.connect(
            lambda error: self.finish(f"Voiced: {self.socket.errorString()}")
        )
        self.socket.disconnected.connect(self.disconnected)
        self.timeout = QTimer(self)
        self.timeout.setSingleShot(True)
        self.timeout.timeout.connect(
            lambda: self.finish("Voiced timed out; check the daemon.")
        )
        self.active = False
        self.released = False
        self.started = False

    def send(self, kind):
        self.socket.write((json.dumps({"type": kind}) + "\n").encode())
        self.socket.flush()

    def press(self):
        if self.active:
            return
        self.active, self.released, self.started = True, False, False
        self.active_changed.emit(True)
        self.status.emit("Connecting to voiced…")
        self.timeout.start(5000)
        self.socket.connectToServer(self.path)

    def release(self):
        if not self.active or self.released:
            return
        self.released = True
        if self.started:
            self.stop()

    def stop(self):
        self.send("dictation_stop")
        self.status.emit("Transcribing…")
        self.timeout.start(120000)

    def read(self):
        while self.socket.canReadLine():
            try:
                event = json.loads(bytes(self.socket.readLine()))
            except (ValueError, UnicodeDecodeError):
                self.finish("Invalid voiced response")
                return
            if not self.active:
                continue
            kind = event.get("type")
            if kind == "hello":
                if event.get("private_dictation") != 1:
                    self.finish(
                        "Restart voiced with private dictation support; no recording started."
                    )
                    return
                if self.released:
                    self.finish("Dictation cancelled before recording started.")
                    return
                self.send("dictation_start")
            elif kind == "error":
                self.finish(f"Voiced: {event.get('message', 'unknown error')}")
            elif kind == "status" and event.get("state") == "listening":
                self.started = True
                self.timeout.stop()
                self.status.emit("Listening… release to insert text")
                if self.released:
                    self.stop()
            elif kind == "transcription":
                if event.get("final"):
                    text = event.get("text", "").strip()
                    if text:
                        self.transcript.emit(text)
                    self.finish("Dictation inserted; review and send when ready.")
                else:
                    self.status.emit(f"Hearing: {event.get('text', '')}")
            elif kind == "status" and event.get("state") == "idle":
                self.finish("No speech recognized.")

    def disconnected(self):
        if self.active:
            self.finish("Voiced disconnected.")

    def finish(self, message):
        self.active = False
        self.timeout.stop()
        self.socket.abort()
        self.active_changed.emit(False)
        self.status.emit(message)

    def close(self):
        if self.active and self.started:
            self.send("dictation_stop")
        self.finish("Dictation closed.")
