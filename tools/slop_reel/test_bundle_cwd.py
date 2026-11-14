"""Exercise the actual py2app launcher with both apps' packaging options."""

import importlib.util
import json
import plistlib
import subprocess
import sys
from pathlib import Path

import pytest


@pytest.mark.skipif(
    sys.platform != "darwin" or importlib.util.find_spec("py2app") is None,
    reason="Requires macOS and the optional macos build dependencies",
)
@pytest.mark.parametrize(
    "project,name", [("slop_reel", "Slop Reel"), ("pip-rot", "Pip Rot")]
)
def test_bundle_preserves_caller_cwd_and_literal_arguments(tmp_path, project, name):
    tools = Path(__file__).resolve().parents[1]
    setup_file = tools / project / "setup_macos.py"
    # Replace only the application payload, keeping the production bundle options
    # and native launcher. No desktop/OpenGL, installed app or source edits needed.
    probe = tmp_path / "report_cwd.py"
    probe.write_text(
        "import json, os, sys\n"
        "from pathlib import Path\n"
        "print(json.dumps({'cwd': os.getcwd(), 'args': sys.argv[1:], "
        "'resolved': [str(Path(p).resolve()) for p in sys.argv[1:]], "
        "'exists': [Path(p).exists() for p in sys.argv[1:]]}))\n"
    )
    build_script = """
import runpy, sys
from unittest.mock import patch
from setuptools import setup
with patch('setuptools.setup') as capture:
    runpy.run_path(sys.argv[1])
options = capture.call_args.kwargs
options['app'] = [sys.argv[2]]
sys.argv = ['setup.py', 'py2app', '-A']
setup(**options)
"""
    result = subprocess.run(
        [sys.executable, "-c", build_script, str(setup_file), str(probe)],
        cwd=tmp_path,
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    bundle = tmp_path / "dist" / f"{name}.app"
    with (bundle / "Contents/Info.plist").open("rb") as stream:
        assert plistlib.load(stream)["PyOptions"]["no_chdir"] is True
    boot = (bundle / "Contents/Resources/__boot__.py").read_text()
    assert "_chdir_resource()" not in boot
    caller = tmp_path / "course review with spaces"
    caller.mkdir()
    filename = "a clip's [draft] $literal;.mp4"
    (caller / filename).touch()
    args = [".", filename, f"./{filename}"]
    result = subprocess.run(
        [str(bundle / "Contents/MacOS" / name), *args],
        cwd=caller,
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    report = json.loads(result.stdout.strip().splitlines()[-1])
    assert Path(report["cwd"]).samefile(caller)
    assert report["args"] == args
    assert report["resolved"] == [str((caller / p).resolve()) for p in args]
    assert report["exists"] == [True, True, True]
