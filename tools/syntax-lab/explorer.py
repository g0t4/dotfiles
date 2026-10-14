"""Palette transformations and a common terminal/image sweep renderer.

Add a sweep by registering a builder returning Variant objects in SWEEPS.
Builders do not know about files, grids, or output formats.
"""

from dataclasses import dataclass, replace
import math
from pathlib import Path
import random
import re

from rich.syntax import Syntax, PygmentsSyntaxTheme
from rich.table import Table
from rich.text import Text


@dataclass(frozen=True)
class Variant:
    label: str
    colors: dict
    blur: float = 0


def linear_rgb(color):
    channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]


def rgb_hex(channels):
    encoded = [12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055 for c in channels]
    return '#' + ''.join(f'{round(min(1, max(0, c)) * 255):02x}' for c in encoded)


def oklch(color):
    r, g, b = linear_rgb(color)
    l = (0.4122214708*r + 0.5363325363*g + 0.0514459929*b) ** (1/3)
    m = (0.2119034982*r + 0.6806995451*g + 0.1073969566*b) ** (1/3)
    s = (0.0883024619*r + 0.2817188376*g + 0.6299787005*b) ** (1/3)
    lightness = 0.2104542553*l + 0.7936177850*m - 0.0040720468*s
    a = 1.9779984951*l - 2.4285922050*m + 0.4505937099*s
    b = 0.0259040371*l + 0.7827717662*m - 0.8086757660*s
    return lightness, math.hypot(a, b), math.atan2(b, a)


def from_oklch(lightness, chroma, hue):
    def convert(c):
        a, b = c * math.cos(hue), c * math.sin(hue)
        l = (lightness + 0.3963377774*a + 0.2158037573*b) ** 3
        m = (lightness - 0.1055613458*a - 0.0638541728*b) ** 3
        s = (lightness - 0.0894841775*a - 1.2914855480*b) ** 3
        return (4.0767416621*l - 3.3077115913*m + 0.2309699292*s,
                -1.2684380046*l + 2.6097574011*m - 0.3413193965*s,
                -0.0041960863*l - 0.7034186147*m + 1.7076147010*s)
    # Keep perceptual lightness/hue; reduce chroma when a hue leaves sRGB.
    channels = convert(chroma)
    if not all(0 <= c <= 1 for c in channels):
        low, high = 0.0, chroma
        for _ in range(24):
            mid = (low + high) / 2
            if all(0 <= c <= 1 for c in convert(mid)):
                low = mid
            else:
                high = mid
        channels = convert(low)
    return rgb_hex(channels)


def hue_shuffle(colors, seed):
    neutrals = {'background', 'text', 'comment', 'operator', 'punctuation'}
    unique = list(dict.fromkeys(color for role, color in colors.items() if role not in neutrals))
    hues = [oklch(color)[2] for color in unique]
    random.Random(seed).shuffle(hues)
    mapping = dict(zip(unique, hues))
    return {role: color if role in neutrals else from_oklch(*oklch(color)[:2], mapping[color]) for role, color in colors.items()}


VISION = {'protan': 'protanomaly', 'deutan': 'deuteranomaly', 'tritan': 'tritanomaly'}


def simulate_vision(colors, kind, severity):
    from colorspacious import machado_et_al_2009_matrix
    matrix = machado_et_al_2009_matrix(VISION[kind], severity)
    return {role: rgb_hex(matrix @ linear_rgb(color)) for role, color in colors.items()}


def backgrounds(colors, args):
    l, c, h = oklch(colors['background'])
    offsets = [0] if args.steps == 1 else [(i / (args.steps - 1) - .5) * args.bg_span for i in range(args.steps)]
    variants = []
    for offset in offsets:
        bg = colors['background'] if offset == 0 else from_oklch(min(.95, max(.02, l + offset)), c, h)
        variants.append(Variant(f"L={l + offset:.3f} {bg}", {**colors, 'background': bg}))
    return variants


def background_tints(colors, args):
    l, _, _ = oklch(colors['background'])
    variants = [Variant('current ' + colors['background'], colors), Variant('neutral', {**colors, 'background': from_oklch(l, 0, 0)})]
    for name, degrees in [('warm', 60), ('green', 150), ('teal', 210), ('blue', 270), ('violet', 320)]:
        variants.append(Variant(name, {**colors, 'background': from_oklch(l, .025, math.radians(degrees))}))
    return variants


def shuffles(colors, args):
    return [Variant('original', colors)] + [Variant(f'hue seed={args.seed + i}', hue_shuffle(colors, args.seed + i)) for i in range(args.steps - 1)]


def visions(colors, args):
    return [Variant('original', colors)] + [Variant(f'{kind} severity={args.severity:g}', simulate_vision(colors, kind, args.severity)) for kind in VISION]


def blurs(colors, args):
    maximum = args.blur if args.blur is not None else 3.0
    return [Variant(f'blur={radius:.2f}px', colors, radius) for radius in ([0] if args.steps == 1 else [maximum * i / (args.steps - 1) for i in range(args.steps)])]


SWEEPS = {'background': backgrounds, 'background-tint': background_tints, 'hue-shuffle': shuffles, 'vision': visions, 'blur': blurs}


def add_arguments(parser):
    parser.add_argument('--sweep', choices=SWEEPS)
    parser.add_argument('--steps', type=int, default=7, help='variants for background/hue/blur sweeps (includes original for hue)')
    parser.add_argument('--columns', type=int, help='grid columns; default fits sample width to terminal columns')
    parser.add_argument('--sample-lines', type=int, default=0, help='excerpt length for sweeps; 0 uses entire file')
    parser.add_argument('--blur', type=float, nargs='?', const=2.0, help='Gaussian radius in image pixels; saves PNG (default 2)')
    parser.add_argument('--vision', choices=VISION, help='protan: red, deutan: green, tritan: blue/yellow discrimination simulation')
    parser.add_argument('--severity', type=float, default=100, help='Machado simulation severity, 0..100')
    parser.add_argument('--hue-shuffle', action='store_true')
    parser.add_argument('--seed', type=int, default=0)
    parser.add_argument('--background', help='one-off #RRGGBB background')
    parser.add_argument('--bg-span', type=float, default=.21, help='total OKLab lightness span, centered on current background')
    parser.add_argument('--output', type=Path, help='PNG output; implies image view')
    parser.add_argument('--font-size', type=int, default=16)
    parser.add_argument('--font', type=Path, help='monospace TTF/TTC for image views')
    parser.add_argument('--export-dir', type=Path, help='save numbered palette JSON variants for later testing')


def text_sample(code, lexer, colors, console):
    from highlight import make_style, style_for_lexer
    style = style_for_lexer(lexer, colors, make_style(colors))
    syntax = Syntax(code, lexer, theme=PygmentsSyntaxTheme(style), background_color=colors['background'])
    return syntax.highlight(code)


def layout(code, variants, args, console):
    width = max(32, max((len(line.expandtabs(4)) for line in code.splitlines()), default=0), max(len(v.label) + 4 for v in variants))
    columns = args.columns or max(1, console.width // (width + 3))
    return width, min(columns, len(variants))


def terminal_grid(code, lexer, variants, args, console):
    width, columns = layout(code, variants, args, console)
    table = Table.grid(padding=(0, 1, 1, 0))
    for _ in range(columns):
        table.add_column(width=width, no_wrap=True)
    cells = []
    for index, variant in enumerate(variants, 1):
        cell = Text(f'{index:02} {variant.label}\n', style='#cecece')
        for line in text_sample(code, lexer, variant.colors, console).split('\n'):
            line.style = f"{variant.colors['text']} on {variant.colors['background']}"
            line.pad_right(max(0, width - len(line.plain)))
            cell.append_text(line)
            cell.append('\n')
        cells.append(cell)
    for start in range(0, len(cells), columns):
        row = cells[start:start + columns]
        table.add_row(*row, *([Text('')] * (columns - len(row))))
    console.print(f'{len(variants)} variants · {columns} columns · sample width {width} · terminal {console.width}')
    console.print(table)


def display_iterm_image(output, *, columns, char_width, image_width, console):
    """Size in terminal cells, independent of native PNG pixels/Retina scale."""
    import base64
    import os

    if not console.is_terminal or os.environ.get('TERM_PROGRAM') != 'iTerm.app':
        return
    # Account for the raster padding as well as glyphs, but never exceed the
    # pane width. Forced oversized grids are proportionally scaled to fit.
    display_columns = min(columns, max(1, math.ceil(image_width / char_width)))
    payload = output.read_bytes()
    name = base64.b64encode(output.name.encode()).decode('ascii')
    data = base64.b64encode(payload).decode('ascii')
    sequence = f'\x1b]1337;File=name={name};size={len(payload)};inline=1;width={display_columns};height=auto;preserveAspectRatio=1:{data}\a'
    # Match imgcat's passthrough handling when running under tmux/screen.
    if os.environ.get('TERM', '').startswith(('screen', 'tmux')):
        sequence = '\x1bPtmux;' + sequence.replace('\x1b', '\x1b\x1b') + '\x1b\\'
    console.file.write(sequence + '\n')
    console.file.flush()


def image_grid(code, lexer, variants, args, console):
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
    font_candidates = [args.font] if args.font else [Path('/System/Library/Fonts/Menlo.ttc'), Path('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf')]
    font_path = next((path for path in font_candidates if path.exists()), None)
    if font_path is None:
        raise ValueError('No monospace font found; supply --font path/to/font.ttf')
    font = ImageFont.truetype(str(font_path), args.font_size)
    width, columns = layout(code, variants, args, console)
    char_width = font.getlength('M')
    line_height = sum(font.getmetrics()) + 3
    lines = code.split('\n')
    tile_width = math.ceil(width * char_width) + 24
    tile_height = len(lines) * line_height + 48
    canvas = Image.new('RGB', (columns * (tile_width + 12), math.ceil(len(variants) / columns) * (tile_height + 12)), '#111318')
    draw = ImageDraw.Draw(canvas)
    for index, variant in enumerate(variants):
        x, y = (index % columns) * (tile_width + 12), (index // columns) * (tile_height + 12)
        tile = Image.new('RGB', (tile_width, tile_height - 30), variant.colors['background'])
        painter = ImageDraw.Draw(tile)
        for row, line in enumerate(text_sample(code, lexer, variant.colors, console).split('\n')):
            for column, char in enumerate(line.plain):
                style = line.get_style_at_offset(console, column)
                fill = '#' + ''.join(f'{c:02x}' for c in style.color.get_truecolor()) if style.color else variant.colors['text']
                painter.text((12 + column * char_width, 8 + row * line_height), char, font=font, fill=fill)
        if variant.blur:
            tile = tile.filter(ImageFilter.GaussianBlur(variant.blur))
        draw.text((x + 8, y + 3), f'{index + 1:02} {variant.label}', font=font, fill='#cecece')
        canvas.paste(tile, (x, y + 30))
    output = args.output or Path('/tmp/syntax-lab-blur.png')
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output, format='PNG')
    console.print(f'Image: {output.resolve()} ({canvas.width}×{canvas.height}, {columns} columns)', soft_wrap=True, markup=False)
    display_iterm_image(output, columns=console.width, char_width=char_width, image_width=canvas.width, console=console)


def explore(args, code, lexer, colors, console):
    if args.steps < 1 or (args.columns is not None and args.columns < 1) or args.sample_lines < 0:
        raise ValueError('steps/columns must be positive; sample-lines must be nonnegative')
    if not 0 <= args.severity <= 100 or not math.isfinite(args.bg_span) or args.bg_span < 0 or (args.blur is not None and (not math.isfinite(args.blur) or args.blur < 0)) or args.font_size < 1:
        raise ValueError('severity must be 0..100; blur/span nonnegative; font-size positive')
    if args.background:
        if not re.fullmatch(r'#[0-9a-fA-F]{6}', args.background):
            raise ValueError('background must be #RRGGBB')
        colors = {**colors, 'background': args.background}
    if args.hue_shuffle:
        colors = hue_shuffle(colors, args.seed)
    variants = SWEEPS[args.sweep](colors, args) if args.sweep else [Variant('current', colors)]
    if args.vision:
        variants = [replace(v, colors=simulate_vision(v.colors, args.vision, args.severity), label=f'{v.label} {args.vision}') for v in variants]
    if args.blur is not None and args.sweep != 'blur':
        variants = [replace(v, blur=args.blur) for v in variants]
    if args.export_dir:
        import json
        args.export_dir.mkdir(parents=True, exist_ok=True)
        for index, variant in enumerate(variants, 1):
            (args.export_dir / f'{index:02}.json').write_text(json.dumps(variant.colors, indent=2) + '\n')
        (args.export_dir / 'manifest.json').write_text(json.dumps([{'file': f'{index:02}.json', 'label': v.label, 'blur': v.blur} for index, v in enumerate(variants, 1)], indent=2) + '\n')
    if args.sample_lines:
        code = '\n'.join(code.splitlines()[:args.sample_lines])
    code = code.expandtabs(4).rstrip('\n')
    if args.blur is not None or args.sweep == 'blur' or args.output:
        image_grid(code, lexer, variants, args, console)
    else:
        terminal_grid(code, lexer, variants, args, console)
