"""Qt chat rendering with syntax-lab's shared Markdown token styles."""

from PySide6.QtGui import QColor, QFontDatabase, QPalette, QTextCharFormat, QTextCursor
from wes_syntax import load_style, source_lexer, style_for_lexer


def apply_chat_theme(*widgets):
    colors, _ = load_style()
    for widget in widgets:
        palette = widget.palette()
        for role, color in (
            (QPalette.ColorRole.Base, colors["background"]),
            (QPalette.ColorRole.Window, colors["background"]),
            (QPalette.ColorRole.Text, colors["text"]),
            (QPalette.ColorRole.WindowText, colors["text"]),
            (QPalette.ColorRole.Link, colors["function"]),
            (QPalette.ColorRole.PlaceholderText, colors["comment"]),
            (QPalette.ColorRole.Highlight, colors["builtin"]),
            (QPalette.ColorRole.HighlightedText, colors["background"]),
        ):
            palette.setColor(role, QColor(color))
        widget.setPalette(palette)
    font = QFontDatabase.systemFont(QFontDatabase.SystemFont.FixedFont)
    families = QFontDatabase.families()
    if "Menlo" in families:
        font.setFamily("Menlo")
    font.setPointSize(12)
    for widget in widgets[:2]:
        widget.setFont(font)


def append_markdown(browser, title, text):
    """Keep Markdown source editable/copyable; never interpret model text as HTML."""
    colors, base = load_style()
    lexer = source_lexer("markdown")
    lexer.stripnl = False
    lexer.ensurenl = False
    style = style_for_lexer(lexer, colors, base)
    cursor = browser.textCursor()
    cursor.movePosition(QTextCursor.MoveOperation.End)
    label = QTextCharFormat()
    label.setForeground(
        QColor(
            colors[
                "error"
                if title == "Error"
                else "comment"
                if title in ("Inspection", "Status")
                else "function"
            ]
        )
    )
    cursor.insertText(title + "\n", label)
    for token, value in lexer.get_tokens(text):
        token_style = style.style_for_token(token)
        fmt = QTextCharFormat()
        fmt.setForeground(
            QColor(
                "#" + token_style["color"] if token_style["color"] else colors["text"]
            )
        )
        # syntax-lab deliberately uses color rather than bold/italic font changes.
        cursor.insertText(value, fmt)
    neutral = QTextCharFormat()
    neutral.setForeground(QColor(colors["text"]))
    cursor.insertText("\n\n", neutral)
    browser.setTextCursor(cursor)
    browser.ensureCursorVisible()


def trace_link(label, path, *, copied=False):
    """The link is an explicit clipboard action, never a file opener."""
    from html import escape

    colors, _ = load_style()
    label.setToolTip(f"Click to copy full trace path:\n{path}")
    link_color = colors["function"]
    label.setText(
        f'{"Copied trace path" if copied else "Trace"}: <a href="copy-trace" style="color:{link_color};">{escape(path.name)}</a>'
    )
