"""Turn a freshly created empty folder into a relative path, without overwrites."""
import os
from pathlib import Path

from transfers import rename_exclusive


def finish_empty_folder(source, text):
    source = Path(source)
    relative = Path(text)
    if not text or '\0' in text or relative.is_absolute() or '..' in relative.parts or relative == Path('.'):
        raise ValueError("Use a relative path without '..'.")
    if source.is_symlink() or not source.is_dir() or any(source.iterdir()):
        raise ValueError('Path entry is only available for a new, empty folder.')
    target = source.parent / relative
    directory = text.endswith('/')
    if target == source:
        if directory:
            return source
        raise ValueError('Choose a different path for the new file.')
    if target.is_relative_to(source):
        raise ValueError('The path must be beside the temporary folder, not inside it.')
    if not target.parent.resolve().is_relative_to(source.parent.resolve()):
        raise ValueError('The path must stay inside the creation directory.')
    if os.path.lexists(target):
        raise FileExistsError(f'Destination already exists: {target.name}')
    created = []
    try:
        missing = []
        parent = target.parent
        while not parent.exists():
            missing.append(parent)
            parent = parent.parent
        for parent in reversed(missing):
            parent.mkdir()
            created.append(parent)
        if directory:
            rename_exclusive(source, target)
        else:
            # rmdir refuses a folder that acquired contents while being edited.
            source.rmdir()
            try:
                with target.open('xb'):
                    pass
            except Exception:
                source.mkdir(exist_ok=True)
                raise
    except Exception:
        for parent in reversed(created):
            try:
                parent.rmdir()
            except OSError:
                pass
        raise
    return target
