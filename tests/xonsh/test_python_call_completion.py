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

def dump_events():
    pass

class Thing:
    field = 1
    def method(self, value):
        return value
    @classmethod
    def make(cls):
        return cls()

XSH.ctx['sample'] = sample
XSH.ctx['dump_events'] = dump_events
XSH.ctx['thing'] = Thing()
XSH.aliases['shell_widget'] = lambda args: None
for line in ('sam', 'dump_e', '@.debug.break', 'x = sam', 'print(sam', 'echo @(sam',
             'print(thing.met', 'print(thing.fie', 'print(len',
             'print(Thing.mak', 'echo sam', 'shell_wid'):
    completions, _ = Completer().complete(
        line.split()[-1], line, 0, len(line), ctx=XSH.ctx,
        multiline_text=line, cursor_index=len(line),
    )
    print(repr(line), repr([(str(c), getattr(c, 'display', None),
                            getattr(c, 'provider', None))
                           for c in completions
                           if str(c).startswith(('sample', 'dump_events', '@.debug.',
                                                 'shell_widget',
                                                 'thing.', 'len', 'Thing.'))]))
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
    assert "('sample()', 'sample()', 'python')" in lines[0]
    assert "('sample ', None, 'command')" in lines[0]
    assert "('dump_events()', 'dump_events()', 'python')" in lines[1]
    assert "('@.debug.breakpoint()', '@.debug.breakpoint()', 'python')" in lines[2]
    assert "('sample()', 'sample()'" in lines[3]
    assert "('sample()', 'sample()'" in lines[4]
    assert "('sample()', 'sample()'" in lines[5]
    assert "('thing.method()', 'thing.method()'" in lines[6]
    assert "('thing.field', None" in lines[7]
    assert "('len()', 'len()'" in lines[8]
    assert "('Thing.make()', 'Thing.make()'" in lines[9]
    assert "sample()" not in lines[10]  # ordinary command argument
    assert "('shell_widget ', None, 'alias')" in lines[11]
    assert "shell_widget()" not in lines[11]
