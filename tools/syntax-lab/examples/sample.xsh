#!/usr/bin/env xonsh
"""Mixed Python and shell code; this specimen is displayed, never executed."""

from pathlib import Path

$PROJECT_ROOT = str(Path.cwd())
files = ["foo.py", "./foo.py", "/tmp/foo.py"]

def describe(path: str) -> str:
    return f"source: {path}\n"

# Explicit subprocess expressions enter Xonsh's shell mode.
contents = $(cat foo.py)
relative = $(cat ./foo.py)
absolute = $(cat /tmp/foo.py)
$[echo "project root:" $PROJECT_ROOT]
![printf '%s\n' @(files)]

# Bare commands exercise the native lexer's file-mode limitations.
cat foo.py
cat ./foo.py
cat /tmp/foo.py
git status --short | head -20

for path in files:
    print(describe(path))
    $[cat @(path)]
