"""Non-modal feedback with prominent warnings and ordinary routine updates."""
from PySide6.QtWidgets import QStatusBar


class StatusLine(QStatusBar):
    NORMAL_STYLE = '''QStatusBar {
        border-top: 2px solid transparent;
    } QStatusBar::item { border: none; }'''
    WARNING_STYLE = '''QStatusBar {
        background-color: #634400;
        color: #fff2c2;
        font-weight: 600;
        border-top: 2px solid #ffc45c;
    } QStatusBar::item { border: none; }'''

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumHeight(28)
        self.setStyleSheet(self.NORMAL_STYLE)
        self.messageChanged.connect(self.message_changed)

    def showMessage(self, text, timeout=0, *, warning=False):
        self.setProperty('warning', bool(text and warning))
        self.setStyleSheet(self.WARNING_STYLE if text and warning else self.NORMAL_STYLE)
        super().showMessage(f'⚠ {text}' if text and warning else text, timeout)

    def message_changed(self, text):
        if not text:
            self.setProperty('warning', False)
            self.setStyleSheet(self.NORMAL_STYLE)
