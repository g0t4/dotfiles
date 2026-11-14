"""Local alias bundle: use this checkout and its existing Python environment."""

import os
import shutil
from pathlib import Path

from setuptools import setup

ROOT = Path(__file__).resolve().parent
# Finder does not read shell startup files. Record the actual media-tool locations
# when installing; keep standard paths available for subprocess dependencies too.
tool_dirs = []
for tool in ("ffmpeg", "ffprobe"):
    executable = shutil.which(tool)
    if not executable:
        raise RuntimeError(f"Install {tool} before building Slop Reel.app")
    tool_dirs.append(str(Path(executable).parent))
search_path = os.pathsep.join(
    dict.fromkeys([*tool_dirs, "/usr/bin", "/bin", "/usr/sbin", "/sbin"])
)

setup(
    name="Slop Reel",
    app=[str(ROOT / "app.py")],
    options={
        "py2app": {
            "alias": True,
            "argv_emulation": False,
            "no_chdir": True,  # CLI paths belong to the caller's working directory.
            "iconfile": str(ROOT / "assets/slop-reel.icns"),
            "plist": {
                "CFBundleIdentifier": "com.g0t4.slop-reel",
                "CFBundleName": "Slop Reel",
                "CFBundleDisplayName": "Slop Reel",
                "CFBundleShortVersionString": "0.1.0",
                "NSHighResolutionCapable": True,
                "LSEnvironment": {"PATH": search_path},
                "CFBundleDocumentTypes": [
                    {
                        "CFBundleTypeName": "Video",
                        "LSItemContentTypes": ["public.movie", "public.video"],
                        "CFBundleTypeExtensions": [
                            "mp4",
                            "mov",
                            "m4v",
                            "mkv",
                            "webm",
                            "avi",
                            "mpg",
                            "mpeg",
                            "mts",
                            "m2ts",
                            "ts",
                            "ogv",
                        ],
                        "CFBundleTypeRole": "Viewer",
                        "LSHandlerRank": "Alternate",
                    }
                ],
            },
        }
    },
)
