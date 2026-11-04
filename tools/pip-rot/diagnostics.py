"""Small rotating local log for filesystem refresh diagnosis."""
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path


def log_refresh(event, root, counts):
    logger = logging.getLogger('pip-rot.filesystem')
    try:
        if not logger.handlers:
            path = Path.home() / '.local/share/devtools/pip-rot.log'
            path.parent.mkdir(parents=True, exist_ok=True)
            handler = RotatingFileHandler(path, maxBytes=2_000_000, backupCount=2)
            handler.setFormatter(logging.Formatter('%(asctime)s pid=%(process)d %(message)s'))
            logger.addHandler(handler)
            logger.setLevel(logging.INFO)
            logger.propagate = False
        logger.info('%s root=%r loaded_rows=%r', event, str(root), counts)
    except OSError:
        # Diagnostics must not prevent navigation if the log cannot be opened.
        pass
