"""Render the editable vector master into macOS icon sizes."""

from pathlib import Path

from PIL import Image
from PySide6.QtCore import Qt
from PySide6.QtGui import QImage, QPainter
from PySide6.QtSvg import QSvgRenderer


def build():
    root = Path(__file__).resolve().parent
    renderer = QSvgRenderer(str(root / "assets/slop-reel.svg"))
    if not renderer.isValid():
        raise RuntimeError("Invalid Slop Reel icon SVG")
    iconset = root / "build/slop-reel.iconset"
    iconset.mkdir(parents=True, exist_ok=True)
    for size in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            pixels = size * scale
            image = QImage(pixels, pixels, QImage.Format.Format_ARGB32_Premultiplied)
            image.fill(Qt.GlobalColor.transparent)
            painter = QPainter(image)
            renderer.render(painter)
            painter.end()
            suffix = "@2x" if scale == 2 else ""
            if not image.save(str(iconset / f"icon_{size}x{size}{suffix}.png")):
                raise RuntimeError("Could not save icon")
            if pixels == 1024:
                image.save(str(root / "assets/slop-reel.png"))
    # Pillow writes the standard multi-resolution ICNS container directly.
    # This also works when the system iconutil service is unavailable.
    with Image.open(root / "assets/slop-reel.png") as master:
        master.save(root / "assets/slop-reel.icns", format="ICNS")


if __name__ == "__main__":
    build()
