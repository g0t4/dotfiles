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

    SUCCESS_STYLE = '''QStatusBar {
        background-color: #185631;
        color: #dcffe7;
        font-weight: 600;
        border-top: 2px solid #69e899;
    } QStatusBar::item { border: none; }'''

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumHeight(28)
        self.setStyleSheet(self.NORMAL_STYLE)
        self.messageChanged.connect(self.message_changed)

    def showMessage(self, text, timeout=0, *, warning=False, success=False):
        self.setProperty('warning', bool(text and warning))
        self.setProperty('success', bool(text and success and not warning))
        style, prefix = (self.WARNING_STYLE, '⚠ ') if warning else (
            (self.SUCCESS_STYLE, '✓ ') if success else (self.NORMAL_STYLE, '')
        )
        self.setStyleSheet(style if text else self.NORMAL_STYLE)
        super().showMessage(f'{prefix}{text}' if text else text, timeout)

    def message_changed(self, text):
        if not text:
            self.setProperty('warning', False)
            self.setProperty('success', False)
            self.setStyleSheet(self.NORMAL_STYLE)
