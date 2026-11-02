"""Small file-selection contract for the Hammerspoon action picker."""
import json
import os
from pathlib import Path
import tempfile


def context_path():
    return Path.home() / '.local/state/pip-rot' / f'context-{os.getpid()}.json'


def publish_context(root, paths, title):
    target = context_path()
    target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    payload = {'version': 1, 'kind': 'files', 'source': 'pip-rot',
               'pid': os.getpid(), 'directory': str(root),
               'paths': [str(path) for path in paths], 'window_title': title}
    descriptor, temporary = tempfile.mkstemp(dir=target.parent)
    try:
        with os.fdopen(descriptor, 'w') as stream:
            json.dump(payload, stream)
        os.replace(temporary, target)
    finally:
        Path(temporary).unlink(missing_ok=True)


def remove_context():
    context_path().unlink(missing_ok=True)
