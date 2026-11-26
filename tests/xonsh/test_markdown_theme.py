from test_setup import ROOT

import importlib.util
import re
import subprocess
import sys


WES_PACKAGE_DIR = ROOT / 'tools/wes_package'


def test_markdown_preserves_source_and_highlights_embedded_code():
    path = WES_PACKAGE_DIR / 'examples/sample.md'
    result = subprocess.run([sys.executable, str(WES_PACKAGE_DIR / 'bat.py'), '--color=always', str(path)], capture_output=True, text=True, check=True)
    assert re.sub(r'\x1b\[[0-9;]*m', '', result.stdout) == path.read_text()
    assert '38;2;179;148;227' in result.stdout  # purple headings and keywords
    assert '38;2;172;208;149' in result.stdout  # green fenced code strings
    assert '38;2;217;189;131' in result.stdout  # amber strong text and escapes
    assert not re.search(r'\x1b\[(?:1m|1;|3m|3;|48;)', result.stdout)


def test_grayscale_removes_chroma_without_changing_default():
    spec = importlib.util.spec_from_file_location('lab', WES_PACKAGE_DIR / 'highlight.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    original, _ = module.load_style(WES_PACKAGE_DIR / 'wes/syntax/palette.json')
    gray, _ = module.load_style(WES_PACKAGE_DIR / 'wes/syntax/palette.json', grayscale=True)
    for role, color in gray.items():
        assert color[1:3] == color[3:5] == color[5:7]
        assert abs(module.contrast(original[role], original['background']) - module.contrast(color, gray['background'])) < 0.15
    assert original['keyword'] == '#b394e3'
    for args in ([str(WES_PACKAGE_DIR / 'bat.py'), '--theme=wes-gray', str(WES_PACKAGE_DIR / 'examples/sample.md')], [str(WES_PACKAGE_DIR / 'highlight.py'), '--grayscale', '-l', 'python'], [str(WES_PACKAGE_DIR / 'highlight.py'), '--grayscale', '-l', 'md', '--renderer', 'rich']):
        flag = '--color=always' if args[0].endswith('bat.py') else '--force-color'
        result = subprocess.run([sys.executable, *args, flag], capture_output=True, text=True, check=True)
        channels = re.findall(r'38;2;(\d+);(\d+);(\d+)', result.stdout)
        assert channels
        assert all(r == g == b for r, g, b in channels)
