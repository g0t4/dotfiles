"""libmpv rendering in Qt's OpenGL context (no foreign-window embedding)."""

import ctypes.util
import locale
from pathlib import Path

# Homebrew and Nix may expose libmpv outside dyld's default search paths.
if not ctypes.util.find_library("mpv"):
    for candidate in (
        Path.home() / ".nix-profile/lib/libmpv.dylib",
        Path("/opt/homebrew/lib/libmpv.dylib"),
    ):
        if candidate.exists():
            original_find = ctypes.util.find_library
            ctypes.util.find_library = (
                lambda name, candidate=candidate, original_find=original_find: (
                    str(candidate) if name == "mpv" else original_find(name)
                )
            )
            break
try:
    import mpv
finally:
    if "original_find" in globals():
        ctypes.util.find_library = original_find
from PySide6.QtCore import Qt, Signal
from PySide6.QtOpenGLWidgets import QOpenGLWidget


class Player(QOpenGLWidget):
    redraw = Signal()
    failed = Signal(str)
    navigation = Signal()

    def __init__(self, path, parent=None):
        super().__init__(parent)
        self.path = str(path)
        # QApplication applies the user's locale after python-mpv's import-time
        # reset. libmpv requires C numeric parsing for its entire lifetime.
        locale.setlocale(locale.LC_NUMERIC, "C")
        self.engine = mpv.MPV(
            vo="libmpv",
            pause=True,
            keep_open=True,
            input_default_bindings=False,
            input_vo_keyboard=False,
            config=False,
            terminal=False,
        )
        self.renderer = None
        self.error = None
        self.redraw.connect(self.update, Qt.ConnectionType.QueuedConnection)
        self.setMinimumSize(480, 270)

    def initializeGL(self):
        try:
            self.proc_address = mpv.MpvGlGetProcAddressFn(
                lambda _, name: self.context().getProcAddress(name.decode())
            )
            self.renderer = mpv.MpvRenderContext(
                self.engine,
                "opengl",
                opengl_init_params={"get_proc_address": self.proc_address},
            )
            self.renderer.update_cb = self.redraw.emit
            self.engine.play(self.path)
        except Exception as exc:
            self.error = str(exc)
            self.failed.emit(self.error)

    def paintGL(self):
        if self.renderer:
            ratio = self.devicePixelRatioF()
            self.renderer.render(
                flip_y=True,
                opengl_fbo={
                    "fbo": self.defaultFramebufferObject(),
                    "w": int(self.width() * ratio),
                    "h": int(self.height() * ratio),
                },
            )

    @property
    def position(self):
        return self.engine.time_pos or 0.0

    def seek(self, seconds):
        self.navigation.emit()
        self.engine.seek(max(0, seconds), "absolute+exact")

    def step(self, direction):
        self.navigation.emit()
        self.engine.pause = True
        self.engine.command("frame-step" if direction > 0 else "frame-back-step")

    def close_player(self):
        if self.renderer:
            self.makeCurrent()
            self.renderer.update_cb = None
            self.renderer.free()
            self.renderer = None
            self.doneCurrent()
        self.engine.terminate()
