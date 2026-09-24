"""Python call completions must leave shell command names untouched."""

import os
from pathlib import Path
import subprocess


ROOT = Path(__file__).parents[2]
RC = ROOT / ".config/xonsh/rc.d/python-call-completions.xsh"
LIB = ROOT / ".config/xonsh/lib"


def test_python_call_completions_preserve_command_and_data_candidates():
    script = f"""
from xonsh.built_ins import XSH
from xonsh.completer import Completer
source {RC}

def sample(value):
    return value

class Thing:
    field = 1
    def method(self, value):
        return value
    @classmethod
    def make(cls):
        return cls()

XSH.ctx['sample'] = sample
XSH.ctx['thing'] = Thing()
for line in ('sam', 'x = sam', 'print(sam', 'echo @(sam',
             'print(thing.met', 'print(thing.fie', 'print(len',
             'print(Thing.mak', 'echo sam'):
    completions, _ = Completer().complete(
        line.split()[-1], line, 0, len(line), ctx=XSH.ctx,
        multiline_text=line, cursor_index=len(line),
    )
    print(repr(line), repr([(str(c), getattr(c, 'display', None),
                            getattr(c, 'provider', None))
                           for c in completions
                           if str(c).startswith(('sample', 'thing.', 'len', 'Thing.'))]))
"""
    env = os.environ.copy()
    env["PYTHONPATH"] = str(LIB)
    env["XONSH_LOG"] = os.devnull
    result = subprocess.run(
        ["xonsh", "--no-rc", "-c", script],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
        check=True,
    )
    lines = result.stdout.splitlines()
    assert "sample()" not in lines[0]  # bare command/function alias position
    assert "('sample()', 'sample()'" in lines[1]
    assert "('sample()', 'sample()'" in lines[2]
    assert "('sample()', 'sample()'" in lines[3]
    assert "('thing.method()', 'thing.method()'" in lines[4]
    assert "('thing.field', None" in lines[5]
    assert "('len()', 'len()'" in lines[6]
    assert "('Thing.make()', 'Thing.make()'" in lines[7]
    assert "sample()" not in lines[8]  # ordinary command argument
