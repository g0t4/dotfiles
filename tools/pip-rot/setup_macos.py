"""Local development bundle: live checkout, existing Python/Qt environment."""
from pathlib import Path
from setuptools import setup

ROOT = Path(__file__).resolve().parent
setup(
    name='Pip Rot',
    app=[str(ROOT / 'pip_rot.py')],
    options={'py2app': {
        'alias': True,
        'argv_emulation': False,
        'no_chdir': True,  # Preserve the shell's cwd for paths such as `.`.
        'iconfile': str(ROOT / 'assets/pip-rot.icns'),
        'plist': {
            'CFBundleIdentifier': 'com.g0t4.pip-rot',
            'CFBundleName': 'Pip Rot',
            'CFBundleDocumentTypes': [{
                'CFBundleTypeName': 'Folder',
                'LSItemContentTypes': ['public.folder'],
                'CFBundleTypeRole': 'Viewer',
            }],
        },
    }},
)
