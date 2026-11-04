"""Render bundled nvim-web-devicons mappings without a Neovim runtime."""
import json
from pathlib import Path

from PySide6.QtCore import QRectF, Qt
from PySide6.QtGui import QColor, QFont, QFontDatabase, QIcon, QPainter, QPixmap, QRawFont
from PySide6.QtWidgets import QApplication


class FileIcons:
    def __init__(self):
        self.mappings = json.loads((Path(__file__).parent / 'assets/devicons/icons.json').read_text())
        families = QFontDatabase.families()
        family = ('SauceCodePro Nerd Font' if 'SauceCodePro Nerd Font' in families else
                  next((name for name in families if 'Nerd Font' in name), None))
        self.font = QFont(family) if family else None
        if self.font:
            self.font.setPixelSize(17)
        self.cache = {}

    def specification(self, name, directory=False):
        light = QApplication.palette().color(QApplication.palette().ColorRole.Base).lightness() > 128
        if directory:
            return {'icon': '\uf07b', 'color': '#3b80ae' if light else '#74b7e5'}
        mappings = self.mappings['light' if light else 'default']
        names = mappings['filenames']
        match = names.get(name) or names.get(name.lower())
        if match:
            return match
        # Longest extension first, so compound extensions can win.
        pieces = name.split('.')
        for start in range(1, len(pieces)):
            match = mappings['extensions'].get('.'.join(pieces[start:]).lower())
            if match:
                return match
        return {'icon': '\uf0f6', 'color': '#6d8086'}

    def icon(self, name, directory=False):
        if self.font is None:
            return None
        spec = self.specification(name, directory)
        key = (spec['icon'], spec['color'])
        if key not in self.cache:
            if not QRawFont.fromFont(self.font).supportsCharacter(ord(spec['icon'])):
                return None
            # Render at 2x for crisp Retina icons; filenames keep their normal font.
            pixmap = QPixmap(40, 40)
            pixmap.setDevicePixelRatio(2)
            pixmap.fill(Qt.GlobalColor.transparent)
            painter = QPainter(pixmap)
            painter.setRenderHint(QPainter.RenderHint.TextAntialiasing)
            painter.setFont(self.font)
            painter.setPen(QColor(spec['color']))
            painter.drawText(QRectF(0, 0, 20, 20), Qt.AlignmentFlag.AlignCenter, spec['icon'])
            painter.end()
            self.cache[key] = QIcon(pixmap)
        return self.cache[key]
