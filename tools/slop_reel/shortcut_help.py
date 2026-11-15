"""A compact reference for Slop Reel's fixed keyboard shortcuts."""

import sys

from PySide6.QtWidgets import (
    QDialog,
    QDialogButtonBox,
    QGridLayout,
    QLabel,
    QVBoxLayout,
)


class ShortcutHelp(QDialog):
    def __init__(self, parent):
        super().__init__(parent)
        self.setObjectName("shortcutHelp")
        self.setWindowTitle("Keyboard shortcuts")
        layout = QVBoxLayout(self)
        hint = QLabel(
            "Player shortcuts apply outside the chat editor.\nHold F6 to dictate, including while editing your message."
        )
        layout.addWidget(hint)
        grid = QGridLayout()
        grid.setHorizontalSpacing(32)
        grid.setVerticalSpacing(9)
        layout.addLayout(grid)
        command = "⌘" if sys.platform == "darwin" else "Ctrl+"
        rows = [
            ("?", "Show keyboard shortcuts"),
            ("Space", "Play / pause"),
            ("← / →", "Previous / next source frame"),
            ("↓ / ↑", "Previous / next material change"),
            ("Z", "Frame zoom"),
            ("Shift+Z", "Changed-frame sequence"),
            ("F6 (hold)", "Dictate into the chat box; release to insert"),
            (command + "Return", "Send message"),
            (command + "O", "Open video"),
            (command + "W", "Close review window"),
            (command + "Q / F9", "Quit Slop Reel"),
            ("Esc", "Close this reference or a frame popup"),
        ]
        for row, (keys, action) in enumerate(rows):
            grid.addWidget(QLabel(keys), row, 0)
            grid.addWidget(QLabel(action), row, 1)
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Close)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
