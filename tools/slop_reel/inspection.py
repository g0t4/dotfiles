"""Neighbor/source-change strips with optional adjacent-source-frame diffs."""

from PySide6.QtCore import Qt
from PySide6.QtGui import QIcon, QImage, QPixmap
from PySide6.QtWidgets import (
    QCheckBox,
    QDialog,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

from changes import overlay


class FrameStrip(QDialog):
    def __init__(
        self,
        parent,
        center,
        frames,
        *,
        predecessors=None,
        slots=None,
        title="Frames around playhead — click a frame to select",
        page=None,
    ):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.frames = {frame.index: frame for frame in frames}
        self.predecessors = predecessors or self.frames
        self.center = center
        self.tiles = []
        layout = QVBoxLayout(self)
        tools = QHBoxLayout()
        self.diff = QCheckBox("Diff against previous source frame")
        self.diff.toggled.connect(self.refresh)
        tools.addWidget(self.diff)
        if page:
            for label, direction in [("◀ Earlier changes", -1), ("Later changes ▶", 1)]:
                button = QPushButton(label)
                button.clicked.connect(lambda checked=False, d=direction: page(self, d))
                tools.addWidget(button)
        layout.addLayout(tools)
        grid = QGridLayout()
        layout.addLayout(grid)
        for slot, index in enumerate(
            slots if slots is not None else range(center - 3, center + 4)
        ):
            box = QWidget()
            contents = QVBoxLayout(box)
            frame = self.frames.get(index)
            if frame:
                button = QPushButton()
                button.setAutoDefault(False)
                button.clicked.connect(
                    lambda checked=False, t=frame.seconds: parent.player.seek(t)
                )
                contents.addWidget(button)
                label = QLabel()
                label.setWordWrap(True)
                contents.addWidget(label)
                self.tiles.append((frame, button, label))
            else:
                contents.addWidget(QLabel("No frame (start/end of video)"))
            if index == center:
                box.setStyleSheet("background:#394355;")
            grid.addWidget(box, slot // 4, slot % 4)
        self.refresh()
        self.resize(1250, 550)

    def refresh(self):
        for frame, button, label in self.tiles:
            description = f"Frame {frame.index} · {frame.seconds:.6f}s · {frame.index - self.center:+d}"
            data = frame.jpeg
            if self.diff.isChecked():
                previous = self.predecessors.get(frame.index - 1)
                if previous:
                    data, fraction, local = overlay(previous.jpeg, frame.jpeg)
                    description += f"\nvs #{frame.index - 1}: {fraction:.2%} pixels · local {local:.0%}"
                else:
                    description += "\nNo previous source frame available"
            pixmap = QPixmap.fromImage(QImage.fromData(data)).scaledToWidth(
                300, Qt.TransformationMode.SmoothTransformation
            )
            button.setIcon(QIcon(pixmap))
            button.setIconSize(pixmap.size())
            label.setText(description)
