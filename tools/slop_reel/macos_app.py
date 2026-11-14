"""Desktop entry points, including queued Finder file-open events."""

from pathlib import Path

from PySide6.QtCore import QEvent, Qt, QTimer
from PySide6.QtGui import QAction, QIcon, QKeySequence, QPixmap
from PySide6.QtWidgets import (
    QApplication,
    QFileDialog,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

ROOT = Path(__file__).resolve().parent
VIDEO_FILTER = "Videos (*.mp4 *.mov *.m4v *.mkv *.webm *.avi *.mpg *.mpeg *.mts *.m2ts *.ts *.ogv);;All files (*)"


class Welcome(QMainWindow):
    def __init__(self, application):
        super().__init__()
        self.setWindowTitle("Slop Reel")
        self.resize(560, 440)
        self.setAcceptDrops(True)
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(50, 35, 50, 40)
        icon = QLabel()
        icon.setPixmap(QPixmap(str(ROOT / "assets/slop-reel.png")).scaledToWidth(180))
        icon.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(icon)
        label = QLabel("Slop Reel")
        label.setStyleSheet("font-size:28px; font-weight:600; color:#ffcc66")
        label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(label)
        hint = QLabel("Drop a video here to start reviewing.")
        hint.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(hint)
        button = QPushButton("Open video…  ⌘O")
        button.clicked.connect(application.choose_videos)
        layout.addWidget(button)
        self.setCentralWidget(widget)
        self.setStyleSheet(
            "QWidget { background:#171b23; color:#cad3df; } QPushButton { padding:12px; background:#394355; border-radius:8px; }"
        )

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls() and any(
            url.isLocalFile() for url in event.mimeData().urls()
        ):
            event.acceptProposedAction()

    def dropEvent(self, event):
        QApplication.instance().open_paths(
            [url.toLocalFile() for url in event.mimeData().urls() if url.isLocalFile()]
        )
        event.acceptProposedAction()


class Application(QApplication):
    def __init__(self, argv, window_factory=None):
        self.pending = []
        self.windows = []
        self.ready = False
        self.welcome = None
        self.window_factory = window_factory
        super().__init__(argv)
        self.setApplicationName("Slop Reel")
        self.setOrganizationDomain("g0t4.com")
        self.setWindowIcon(QIcon(str(ROOT / "assets/slop-reel.png")))
        self.setStyle("Fusion")
        self.aboutToQuit.connect(self.close_reviews)
        self.installEventFilter(self)

    def eventFilter(self, watched, event):
        if (
            event.type() in (QEvent.Type.ShortcutOverride, QEvent.Type.KeyPress)
            and event.key() == Qt.Key.Key_F9
        ):
            event.accept()
            if event.type() == QEvent.Type.KeyPress:
                self.quit()
            return True
        return super().eventFilter(watched, event)

    def event(self, event):
        if event.type() == QEvent.Type.FileOpen:
            path = event.file()
            if not path and event.url().isLocalFile():
                path = event.url().toLocalFile()
            if path:
                if self.ready:
                    self.open_paths([path])
                else:
                    self.pending.append(path)
                return True
        return super().event(event)

    def add_menu(self, window):
        menu = window.menuBar().addMenu("File")
        action = QAction("Open Video…", window)
        action.setShortcut(QKeySequence.StandardKey.Open)
        action.triggered.connect(self.choose_videos)
        menu.addAction(action)
        close = QAction("Close Window", window)
        close.setShortcut(QKeySequence.StandardKey.Close)
        close.triggered.connect(window.close)
        menu.addAction(close)
        quit_action = QAction("Quit Slop Reel", window)
        quit_action.setMenuRole(QAction.MenuRole.QuitRole)
        quit_action.setShortcut(QKeySequence.StandardKey.Quit)
        quit_action.triggered.connect(self.quit)
        menu.addAction(quit_action)

    def choose_videos(self):
        paths, _ = QFileDialog.getOpenFileNames(
            self.activeWindow(), "Open videos for review", "", VIDEO_FILTER
        )
        self.open_paths(paths)

    def open_paths(self, paths):
        if self.window_factory is None:
            from app import Window

            self.window_factory = Window
        for value in paths:
            path = Path(value).expanduser().resolve()
            if not path.is_file():
                QMessageBox.warning(
                    self.activeWindow(),
                    "Cannot open video",
                    f"File does not exist: {path}",
                )
                continue
            # Repeated Finder opens focus the existing review and its conversation.
            window = next(
                (w for w in self.windows if not w.closed and w.path == path), None
            )
            if window is None:
                window = self.window_factory(path)
                self.windows.append(window)
                window.review_closed.connect(self.release_review)
                self.add_menu(window)
            window.show()
            window.raise_()
            window.activateWindow()
            if self.welcome is not None:
                self.welcome.hide()

    def start(self, paths=()):
        self.pending.extend(map(str, paths))

        def finish_start():
            self.ready = True
            paths, self.pending = list(dict.fromkeys(self.pending)), []
            self.open_paths(paths)
            if not any(not window.closed for window in self.windows):
                self.welcome = Welcome(self)
                self.add_menu(self.welcome)
                self.welcome.show()

        QTimer.singleShot(0, finish_start)

    def close_reviews(self):
        # QApplication.quit() does not deliver a window close event by itself.
        for window in list(self.windows):
            if not window.closed:
                window.close()

    def release_review(self, window):
        if window in self.windows:
            self.windows.remove(window)
