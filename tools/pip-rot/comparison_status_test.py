"""Exercise the same status-file transport used by the launcher comparison."""
import json
import os
import tempfile
from pathlib import Path
from unittest.mock import patch

from PySide6.QtWidgets import QApplication

from pip_rot import Browser
from restart import RestartController

app = QApplication([])
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    with patch('restart.context_path', return_value=root / f'context-{os.getpid()}.json'):
        window = Browser([directory])
        controller = RestartController(window)
        filename = root / f'status-{os.getpid()}.json'
        for message, warning in [('Files are identical', False), ('Files differ', True),
                                 ('Could not compare files', True)]:
            filename.write_text(json.dumps(dict(version=1, pid=os.getpid(), message=message, warning=warning)))
            controller.poll_status()
            assert window.statusBar().currentMessage().endswith(message)
            assert not filename.exists()
        filename.write_text(json.dumps(dict(version=1, pid=-1, message='wrong process')))
        controller.poll_status()
        assert window.statusBar().currentMessage().endswith('Could not compare files')
        filename.write_text('malformed')
        controller.poll_status()
        assert not filename.exists()
        controller.close()
        window.close()
print('PASS: comparison status delivery, wrong PID rejection, malformed message cleanup')
