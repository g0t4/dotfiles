"""Native keyboard/diff/page acceptance check against the generated slide fixture."""

import argparse
import time
from datetime import datetime
from pathlib import Path

from PySide6.QtCore import Qt, QTimer
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication, QPushButton

from app import Window


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("video", type=Path)
    args = parser.parse_args()
    output = (
        Path.home()
        / ".local/state/nvim/ask-openai/slop_reel_validation"
        / datetime.now().strftime("%Y%m%d_%H%M%S_changes")
    )
    output.mkdir(parents=True, exist_ok=True)
    app = QApplication([])
    window = Window(args.video.resolve(), output)
    window.show()
    state = {"phase": 0, "start": time.monotonic()}
    errors = []

    def key(widget, code, modifiers=Qt.KeyboardModifier.NoModifier):
        QTest.keyClick(widget, code, modifiers)

    def at(index):
        return window.media.index_at(window.player.position) == index

    def tick():
        try:
            if time.monotonic() - state["start"] > 40:
                raise AssertionError(
                    f"Timeout in phase {state['phase']}: {window.change_status.text()}, position {window.player.position}, center {window.change_dialog.center if window.change_dialog else None}"
                )
            phase = state["phase"]
            if phase == 0 and window.changes is not None and window.player.engine.width:
                assert [c.index for c in window.changes] == [
                    20,
                    40,
                    60,
                    80,
                    100,
                    115,
                    116,
                    120,
                    140,
                    160,
                    180,
                    200,
                    220,
                ]
                window.player.engine.pause = True
                window.player.seek(0)
                state["phase"] = 1
            elif phase == 1 and at(0):
                key(window.wave, Qt.Key.Key_Up)
                state["phase"] = 2
            elif phase == 2 and at(20):
                key(window.wave, Qt.Key.Key_Up)
                state["phase"] = 3
            elif phase == 3 and at(40):
                key(window.wave, Qt.Key.Key_Up)
                key(window.wave, Qt.Key.Key_Up)
                state["phase"] = 30
            elif phase == 30 and at(80):
                key(window.wave, Qt.Key.Key_Down)
                key(window.wave, Qt.Key.Key_Down)
                state["phase"] = 31
            elif phase == 31 and at(40):
                key(window.wave, Qt.Key.Key_Down)
                state["phase"] = 4
            elif phase == 4 and at(20):
                key(window.wave, Qt.Key.Key_Z, Qt.KeyboardModifier.ShiftModifier)
                state["phase"] = 5
            elif phase == 5 and window.change_dialog and not window.review_busy:
                dialog = window.change_dialog
                assert list(dialog.frames) == [20, 40, 60, 80]
                dialog.diff.setChecked(True)
                dialog.grab().save(str(output / "change-diffs.png"))
                for button in dialog.findChildren(QPushButton):
                    if button.text() == "Later changes ▶":
                        button.click()
                        break
                state["phase"] = 6
            elif phase == 6 and not window.review_busy:
                dialog = window.change_dialog
                assert list(dialog.frames) == [100, 115, 116, 120, 140, 160, 180]
                assert dialog.diff.isChecked()
                assert 114 in dialog.predecessors and 115 in dialog.predecessors
                dialog.grab().save(str(output / "flash-sequence-diffs.png"))
                key(dialog, Qt.Key.Key_Up)
                state["phase"] = 7
            elif phase == 7 and at(40) and not window.review_busy:
                assert window.change_dialog.center == 40
                window.change_dialog.close()
                window.input.setPlainText("first\nsecond")
                window.input.setFocus()
                key(window.input, Qt.Key.Key_Up)
                assert window.input.toPlainText() == "first\nsecond"
                assert at(40)
                window.grab().save(str(output / "player.png"))
                print(
                    "PASS: Up/Down change jumps, Shift+Z sequence, nonoverlapping pages, source-adjacent diffs, editor key isolation",
                    flush=True,
                )
                print(f"Artifacts: {output}", flush=True)
                window.close()
                app.quit()
        except Exception as exc:
            errors.append(exc)
            if window.change_dialog:
                window.change_dialog.close()
            window.close()
            app.quit()

    timer = QTimer()
    timer.timeout.connect(tick)
    timer.start(50)
    app.exec()
    if errors:
        raise errors[0]


if __name__ == "__main__":
    main()
