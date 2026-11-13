"""Native render/step/seek/chat check. Run on a desktop, not QT_QPA_PLATFORM=offscreen."""

import argparse
import time
from datetime import datetime
from pathlib import Path

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from app import FrameZoom, Window


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("video", type=Path)
    parser.add_argument("--live", action="store_true")
    args = parser.parse_args()
    output = (
        Path.home()
        / ".local/state/nvim/ask-openai/slop_reel_validation"
        / datetime.now().strftime("%Y%m%d_%H%M%S")
    )
    output.mkdir(parents=True, exist_ok=True)
    app = QApplication([])
    window = Window(args.video.resolve(), output)
    window.show()
    state = {"phase": 0, "at": time.monotonic(), "started": time.monotonic()}
    errors = []
    dialogs = []

    def advance(phase):
        state.update(phase=phase, at=time.monotonic())

    def tick():
        try:
            if time.monotonic() - state["started"] > 60:
                raise AssertionError("Native smoke test timed out")
            phase, elapsed = state["phase"], time.monotonic() - state["at"]
            if (
                phase == 0
                and window.media
                and window.player.engine.width
                and elapsed > 1
            ):
                assert window.player.error is None
                state["initial"] = window.player.position
                assert window.media.index_at(state["initial"]) == 0
                window.player.step(1)
                advance(1)
            elif phase == 1 and elapsed > 0.3:
                assert window.player.position > state["initial"]
                window.player.step(-1)
                advance(2)
            elif phase == 2 and elapsed > 0.3:
                assert abs(window.player.position - state["initial"]) < 0.002
                window.toggle()
                advance(3)
            elif phase == 3 and elapsed > 2.0:
                assert window.player.position > state["initial"] + 0.3, (
                    window.player.position,
                    state["initial"],
                    window.player.engine.pause,
                )
                window.toggle()
                window.player.seek(0.5)
                advance(4)
            elif phase == 4 and elapsed > 0.3:
                assert abs(window.player.position - 0.5) < 0.05
                position = window.player.position

                def ready(result, error):
                    try:
                        assert error is None, error
                        center, frames = result
                        assert len(frames) == 7
                        dialog = FrameZoom(window, center, frames)
                        dialogs.append(dialog)
                        dialog.show()
                        advance(5)
                    except Exception as exc:
                        errors.append(exc)
                        app.quit()

                window.media_jobs.submit(lambda: window.media.frames(position), ready)
                advance(40)
            elif phase == 5 and elapsed > 0.3:
                dialogs[0].grab().save(str(output / "frame-zoom.png"))
                dialogs[0].close()
                window.grab().save(str(output / "player.png"))
                if args.live:
                    window.input.setPlainText(
                        "/frames Describe what is visible and cite a source frame timestamp. Be brief."
                    )
                    window.send()
                    advance(6)
                else:
                    advance(8)
            elif phase == 6 and not window.busy:
                text = window.transcript.toPlainText()
                assert "Slop Reel" in text, text
                assert "Error" not in text, text
                window.input.setPlainText(
                    "What did I just ask you to inspect? Answer briefly."
                )
                window.send()
                advance(7)
            elif phase == 7 and not window.busy:
                assert window.chat.session.turn == 2
                assert "Error" not in window.transcript.toPlainText(), (
                    window.transcript.toPlainText()
                )
                advance(8)
            elif phase == 8:
                window.grab().save(str(output / "chat.png"))
                print(
                    "PASS: native rendering, playback, forward/back stepping, seek, seven-frame zoom"
                    + (", live multimodal chat and follow-up" if args.live else ""),
                    flush=True,
                )
                print(f"Artifacts: {output}", flush=True)
                window.close()
                app.quit()
        except Exception as exc:
            errors.append(exc)
            window.close()
            app.quit()

    timer = QTimer()
    timer.timeout.connect(tick)
    timer.start(50)
    app.exec()
    if not window.closed:
        window.close()
    if errors:
        raise errors[0]


if __name__ == "__main__":
    main()
