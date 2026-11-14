"""Exercise the real Qt socket client with an isolated voiced protocol server."""

import os
import subprocess
import sys


def test_private_voice_qt_client(tmp_path):
    script = r"""
import json
import tempfile
from pathlib import Path
from PySide6.QtCore import QTimer
from PySide6.QtNetwork import QLocalServer
from PySide6.QtWidgets import QApplication, QPlainTextEdit
from types import SimpleNamespace
from app import Window
from voice import Dictation

app = QApplication([])
editor = QPlainTextEdit()
editor.setPlainText('before replace after')
cursor = editor.textCursor()
cursor.setPosition(7)
cursor.setPosition(14, cursor.MoveMode.KeepAnchor)
target = SimpleNamespace(input=editor, dictation_cursor=cursor)
Window.insert_dictation(target, 'dictated words')
assert editor.toPlainText() == 'before dictated words after'

with tempfile.TemporaryDirectory(dir='/tmp', prefix='sr-voice-') as directory:
    server = QLocalServer()
    assert server.listen(str(Path(directory) / 'v.sock'))
    voice = Dictation(path=server.fullServerName())
    commands, texts, statuses, connections = [], [], [], []
    voice.transcript.connect(texts.append)
    voice.status.connect(statuses.append)
    mode = ['normal']

    def accept():
        peer = server.nextPendingConnection()
        connections.append(peer)
        def read():
            while peer.canReadLine():
                kind = json.loads(bytes(peer.readLine()))['type']
                commands.append(kind)
                if kind == 'hello':
                    reply = {'type': 'hello', 'private_dictation': 1 if mode[0] != 'old' else 0}
                elif kind == 'dictation_start':
                    reply = {'type': 'status', 'state': 'listening'}
                    QTimer.singleShot(10, voice.release)
                elif kind == 'dictation_stop':
                    # A live hypothesis must never be inserted alongside the final text.
                    peer.write(b'{"type":"transcription","text":"partial","final":false}\n')
                    reply = {'type':'transcription', 'text':'find black frames', 'final':True}
                else:
                    raise AssertionError(kind)
                payload = (json.dumps(reply) + '\n').encode()
                peer.write(payload[:5])
                QTimer.singleShot(1, lambda payload=payload, peer=peer: peer.write(payload[5:]))
        peer.readyRead.connect(read)
    server.newConnection.connect(accept)

    def wait_done():
        if voice.active:
            QTimer.singleShot(5, wait_done)
        else:
            app.quit()
    def run():
        QTimer.singleShot(5, wait_done)
        watchdog = QTimer()
        watchdog.setSingleShot(True)
        watchdog.timeout.connect(lambda: (_ for _ in ()).throw(AssertionError('timeout')))
        watchdog.start(2000)
        app.exec()
    voice.press()
    run()
    assert texts == ['find black frames'], texts
    assert commands == ['hello', 'dictation_start', 'dictation_stop'], commands
    mode[0] = 'old'
    commands.clear()
    voice.press()
    run()
    assert commands == ['hello']  # Never fall back to broadcast recording.
    assert 'Restart voiced' in statuses[-1]
    mode[0] = 'normal'
    commands.clear()
    voice.press()
    voice.release()  # Release before handshake: never leave recording running.
    run()
    assert commands == ['hello']
    assert texts == ['find black frames']
    voice.close()
    server.close()
print('private dictation Qt client passed')
"""
    result = subprocess.run(
        [sys.executable, "-c", script],
        cwd=os.path.dirname(__file__),
        env={**os.environ, "QT_QPA_PLATFORM": "offscreen"},
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr
