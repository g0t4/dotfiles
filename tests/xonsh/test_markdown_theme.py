from test_setup import ROOT

import importlib.util
import re
import subprocess
import sys


LAB = ROOT / 'tools/syntax-lab'


def test_markdown_preserves_source_and_highlights_embedded_code():
    path = LAB / 'examples/sample.md'
    result = subprocess.run([sys.executable, str(LAB / 'bat.py'), '--color=always', str(path)], capture_output=True, text=True, check=True)
    assert re.sub(r'\x1b\[[0-9;]*m', '', result.stdout) == path.read_text()
    assert '38;2;179;148;227' in result.stdout  # purple headings and keywords
    assert '38;2;172;208;149' in result.stdout  # green fenced code strings
    assert '38;2;217;189;131' in result.stdout  # amber strong text and escapes
    assert not re.search(r'\x1b\[(?:1m|1;|3m|3;|48;)', result.stdout)


def test_grayscale_removes_chroma_without_changing_default():
    spec = importlib.util.spec_from_file_location('lab', LAB / 'highlight.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    original, _ = module.load_style(LAB / 'palette.json')
    gray, _ = module.load_style(LAB / 'palette.json', grayscale=True)
    for role, color in gray.items():
        assert color[1:3] == color[3:5] == color[5:7]
        assert abs(module.contrast(original[role], original['background']) - module.contrast(color, gray['background'])) < 0.15
    assert original['keyword'] == '#b394e3'
    for args in ([str(LAB / 'bat.py'), '--theme=wes-gray', str(LAB / 'examples/sample.md')], [str(LAB / 'highlight.py'), '--grayscale', '-l', 'python'], [str(LAB / 'highlight.py'), '--grayscale', '-l', 'md', '--renderer', 'rich']):
        flag = '--color=always' if args[0].endswith('bat.py') else '--force-color'
        result = subprocess.run([sys.executable, *args, flag], capture_output=True, text=True, check=True)
        channels = re.findall(r'38;2;(\d+);(\d+);(\d+)', result.stdout)
        assert channels
        assert all(r == g == b for r, g, b in channels)
