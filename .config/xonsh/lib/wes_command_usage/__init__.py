"""Disposable command evidence, independent of GUI file history and picker data."""
import os
from pathlib import Path
from .capture import Recorder
from .analysis import analyze, explain_source
from .store import Store


def default_path():
    return Path(os.environ.get('XDG_STATE_HOME', str(Path.home()/'.local/state'))) / 'command-usage/events.sqlite3'

__all__ = ['Recorder', 'Store', 'analyze', 'explain_source', 'default_path']
