"""Shared dark-blue application chrome and native macOS title bars."""

from PySide6.QtCore import QEvent, QObject, Qt, QTimer
from PySide6.QtGui import QColor, QPalette
from PySide6.QtWidgets import QWidget
from wes_syntax import load_style


def blend(a, b, amount):
    first, second = QColor(a), QColor(b)
    return QColor(
        *(
            round(x * (1 - amount) + y * amount)
            for x, y in zip(first.getRgb()[:3], second.getRgb()[:3], strict=True)
        )
    ).name()


def apply_app_theme(app):
    colors, _ = load_style()
    background, text = colors["background"], colors["text"]
    button = blend(background, colors["function"], 0.16)
    hover = blend(background, colors["function"], 0.29)
    border = blend(background, colors["comment"], 0.34)
    disabled = blend(background, text, 0.44)
    palette = QPalette()
    roles = {
        QPalette.ColorRole.Window: background,
        QPalette.ColorRole.Base: background,
        QPalette.ColorRole.AlternateBase: button,
        QPalette.ColorRole.WindowText: text,
        QPalette.ColorRole.Text: text,
        QPalette.ColorRole.Button: button,
        QPalette.ColorRole.ButtonText: text,
        QPalette.ColorRole.ToolTipBase: button,
        QPalette.ColorRole.ToolTipText: text,
        QPalette.ColorRole.PlaceholderText: colors["comment"],
        QPalette.ColorRole.Link: colors["function"],
        QPalette.ColorRole.LinkVisited: colors["keyword"],
        QPalette.ColorRole.Highlight: colors["builtin"],
        QPalette.ColorRole.HighlightedText: background,
        QPalette.ColorRole.Light: hover,
        QPalette.ColorRole.Midlight: border,
        QPalette.ColorRole.Mid: border,
        QPalette.ColorRole.Dark: background,
        QPalette.ColorRole.Shadow: background,
    }
    for role, value in roles.items():
        palette.setColor(role, QColor(value))
    for role in (
        QPalette.ColorRole.Text,
        QPalette.ColorRole.WindowText,
        QPalette.ColorRole.ButtonText,
    ):
        palette.setColor(QPalette.ColorGroup.Disabled, role, QColor(disabled))
    app.setPalette(palette)
    app.styleHints().setColorScheme(Qt.ColorScheme.Dark)
    app.setStyleSheet(f"""
        QPushButton {{ background:{button}; color:{text}; border:1px solid {border};
            border-radius:5px; padding:6px 10px; }}
        QPushButton:hover {{ background:{hover}; border-color:{colors["function"]}; }}
        QPushButton:pressed, QPushButton:checked {{ background:{colors["builtin"]}; color:{background}; }}
        QPushButton:focus {{ border:1px solid {colors["type"]}; }}
        QPushButton:disabled {{ background:{background}; color:{disabled}; border-color:{border}; }}
        QPlainTextEdit, QTextBrowser {{ border:1px solid {border}; border-radius:4px; }}
        QPlainTextEdit:focus {{ border-color:{colors["function"]}; }}
        QSplitter::handle {{ background:transparent; border:none; }}
        QMenu {{ background:{background}; color:{text}; border:1px solid {border}; }}
        QMenu::item:selected {{ background:{hover}; }}
        QToolTip {{ background:{button}; color:{text}; border:1px solid {border}; padding:4px; }}
    """)
    app.titlebar_theme = TitlebarTheme(app, background)
    app.installEventFilter(app.titlebar_theme)


class TitlebarTheme(QObject):
    """Color native title bars after Qt has attached its NSView to an NSWindow."""

    def __init__(self, app, background):
        super().__init__(app)
        self.background = background
        self.cocoa = app.platformName() == "cocoa"

    def eventFilter(self, watched, event):
        if (
            self.cocoa
            and event.type() == QEvent.Type.Show
            and isinstance(watched, QWidget)
            and watched.isWindow()
        ):
            QTimer.singleShot(0, lambda: self.apply(watched))
        return False

    def apply(self, widget):
        import logging

        try:
            from macos_titlebar import color_titlebar

            color_titlebar(widget, self.background)
        except (OSError, RuntimeError) as error:
            logging.getLogger(__name__).warning(
                "Could not color native title bar: %s", error
            )
