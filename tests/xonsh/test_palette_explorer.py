from test_setup import ROOT

import argparse
import base64
import io
import json
import subprocess
import sys

from PIL import Image
from rich.console import Console

LAB = ROOT / 'tools/syntax-lab'
sys.path.insert(0, str(LAB))
import explorer
import highlight as lab


def options(*args):
    parser = argparse.ArgumentParser()
    explorer.add_arguments(parser)
    return parser.parse_args(args)


def test_background_sweep_changes_only_background_and_contains_baseline():
    colors, _ = lab.load_style(LAB / 'palette.json')
    variants = explorer.backgrounds(colors, options('--steps', '7'))
    assert variants[3].colors == colors
    lightness = [explorer.oklch(v.colors['background'])[0] for v in variants]
    assert lightness == sorted(lightness)
    for variant in variants:
        assert {k: v for k, v in variant.colors.items() if k != 'background'} == {k: v for k, v in colors.items() if k != 'background'}


def test_hue_shuffles_are_repeatable_and_preserve_role_lightness():
    colors, _ = lab.load_style(LAB / 'palette.json')
    variant = explorer.hue_shuffle(colors, 42)
    assert variant == explorer.hue_shuffle(colors, 42)
    assert variant != explorer.hue_shuffle(colors, 43)
    for role in ('background', 'text', 'comment', 'operator', 'punctuation'):
        assert variant[role] == colors[role]
    for role in colors:
        assert abs(explorer.oklch(variant[role])[0] - explorer.oklch(colors[role])[0]) < .005
    assert variant['builtin'] == variant['decorator']
    assert colors['keyword'] == '#b394e3'


def test_grid_fits_reported_terminal_width():
    colors, _ = lab.load_style(LAB / 'palette.json')
    variants = explorer.shuffles(colors, options('--steps', '7'))
    _, narrow = explorer.layout('short sample', variants, options(), Console(width=80))
    _, wide = explorer.layout('short sample', variants, options(), Console(width=160))
    assert wide > narrow


def test_file_is_used_for_blur_sweep_and_palette_exports(tmp_path):
    source = tmp_path / 'project.py'
    source.write_text('def project_specific():\n    return "SIGNAL"\n')
    output = tmp_path / 'blur.png'
    exports = tmp_path / 'variants'
    result = subprocess.run([sys.executable, str(LAB / 'highlight.py'), str(source), '--sweep', 'blur', '--steps', '2', '--columns', '2', '--output', str(output), '--export-dir', str(exports)], capture_output=True, text=True, check=True)
    assert str(output) in result.stdout
    with Image.open(output) as image:
        first = image.crop((0, 30, image.width // 2 - 12, image.height - 12))
        second = image.crop((image.width // 2, 30, image.width - 12, image.height - 12))
        assert first.size == second.size
        assert first.tobytes() != second.tobytes()
    manifest = json.loads((exports / 'manifest.json').read_text())
    assert [v['blur'] for v in manifest] == [0, 3]
    assert (exports / '01.json').exists()


def test_terminal_sweep_contains_passed_file_and_paints_background(tmp_path):
    source = tmp_path / 'project.lua'
    source.write_text('local PROJECT_SIGNAL = 123\n')
    result = subprocess.run([sys.executable, str(LAB / 'highlight.py'), str(source), '--sweep', 'background', '--steps', '3', '--columns', '1', '--force-color'], capture_output=True, text=True, check=True)
    assert result.stdout.count('PROJECT_SIGNAL') == 3
    assert '48;2;' in result.stdout


def test_invalid_blur_is_reported_without_traceback():
    result = subprocess.run([sys.executable, str(LAB / 'highlight.py'), '--blur=-1'], capture_output=True, text=True)
    assert result.returncode == 2
    assert 'Traceback' not in result.stderr


def test_inline_image_uses_terminal_cell_width_and_preserves_payload(tmp_path, monkeypatch):
    output = tmp_path / 'sample.png'
    payload = b'PNG test payload'
    output.write_bytes(payload)
    monkeypatch.setenv('TERM_PROGRAM', 'iTerm.app')
    monkeypatch.setenv('TERM', 'xterm-256color')
    stream = io.StringIO()
    console = Console(file=stream, force_terminal=True, width=240)
    # A native 2000px image may occupy only half a Retina pane, but this
    # specimen should occupy 200 terminal cells at 10px/rendered character.
    explorer.display_iterm_image(output, columns=240, char_width=10, image_width=2000, console=console)
    sequence = stream.getvalue()
    assert ';width=200;height=auto;preserveAspectRatio=1:' in sequence
    assert base64.b64decode(sequence.split(':', 1)[1].rstrip('\a\n')) == payload
    stream.seek(0)
    stream.truncate()
    explorer.display_iterm_image(output, columns=240, char_width=10, image_width=4000, console=console)
    assert ';width=240;' in stream.getvalue()


def test_redirected_output_does_not_emit_inline_images(tmp_path, monkeypatch):
    monkeypatch.setenv('TERM_PROGRAM', 'iTerm.app')
    stream = io.StringIO()
    explorer.display_iterm_image(tmp_path / 'not-read.png', columns=80, char_width=10, image_width=800, console=Console(file=stream, force_terminal=False))
    assert stream.getvalue() == ''
