"""Background filesystem transfers with explicit destinations and no overwrites."""
import ctypes
import errno
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile

from PySide6.QtCore import QObject, QRunnable, QThreadPool, Signal


def exists(path):
    return os.path.lexists(path)


def plan_transfer(paths, destination, copy):
    destination = Path(destination).resolve(strict=True)
    if not destination.is_dir():
        raise ValueError('Drop onto a directory.')
    paths = list(dict.fromkeys(Path(os.path.abspath(path)) for path in paths))
    # A selected directory already contains its selected descendants.
    paths = [path for path in paths if not any(
        other != path and not other.is_symlink() and other.is_dir() and path.is_relative_to(other)
        for other in paths
    )]
    plan, names = [], set()
    for source in paths:
        mode = source.lstat().st_mode
        if source.parent == source:
            raise ValueError('Cannot transfer a filesystem root.')
        if not (stat.S_ISREG(mode) or stat.S_ISDIR(mode) or stat.S_ISLNK(mode)):
            raise ValueError(f'Unsupported file type: {source}')
        if stat.S_ISDIR(mode) and destination.is_relative_to(source.resolve()):
            raise ValueError(f'Cannot put a directory inside itself: {source.name}')
        if not copy and source.parent.resolve() == destination:
            continue
        target = destination / source.name
        if exists(target) or source.name.casefold() in names:
            raise FileExistsError(f'Destination already contains {source.name!r}; nothing was overwritten.')
        names.add(source.name.casefold())
        plan.append((source, target, copy))
    return plan


def rename_exclusive(source, target):
    # macOS RENAME_EXCL atomically refuses even a destination created after preflight.
    function = ctypes.CDLL(None, use_errno=True).renamex_np
    function.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_uint]
    function.restype = ctypes.c_int
    if function(os.fsencode(source), os.fsencode(target), 0x4) != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), str(target))


def copy_then_publish(source, target):
    # Stage on the destination volume; ditto preserves macOS metadata and packages.
    staging = Path(tempfile.mkdtemp(prefix='.pip-rot-transfer-', dir=target.parent))
    temporary = staging / source.name
    try:
        if source.is_symlink():
            temporary.symlink_to(os.readlink(source))
        else:
            result = subprocess.run(['/usr/bin/ditto', str(source), str(temporary)], capture_output=True, text=True)
            if result.returncode:
                raise OSError(result.stderr.strip() or f'Could not copy {source}')
        rename_exclusive(temporary, target)
    finally:
        shutil.rmtree(staging)


def transfer_one(source, target, copy):
    if not copy:
        try:
            rename_exclusive(source, target)
            return
        except OSError as error:
            if error.errno != errno.EXDEV:
                raise
    before = source.lstat()
    copy_then_publish(source, target)
    if not copy:
        after = source.lstat()
        if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) != (
            after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns
        ):
            raise OSError(f'Copied to {target}, but the source changed; it was left in place.')
        if source.is_dir() and not source.is_symlink():
            shutil.rmtree(source)
        else:
            source.unlink()


class TransferJob(QRunnable):
    def __init__(self, owner, paths, destination, copy):
        super().__init__()
        self.owner, self.paths, self.destination, self.copy = owner, paths, destination, copy

    def run(self):
        completed, errors = [], []
        try:
            plan = plan_transfer(self.paths, self.destination, self.copy)
        except Exception as error:
            errors.append(str(error))
            plan = []
        for source, target, copy in plan:
            try:
                transfer_one(source, target, copy)
                completed.append((source, target, copy))
            except Exception as error:
                errors.append(f'{source.name}: {error}')
        self.owner.finished.emit(completed, errors)


class Transfers(QObject):
    finished = Signal(object, object)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.pool = QThreadPool(self)
        self.pool.setMaxThreadCount(1)
        self.pending = 0
        self.finished.connect(self.done)

    @property
    def busy(self):
        return self.pending > 0

    def submit(self, paths, destination, copy):
        self.pending += 1
        self.pool.start(TransferJob(self, paths, destination, copy))

    def done(self, *_):
        self.pending -= 1
