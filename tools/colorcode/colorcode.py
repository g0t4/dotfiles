"""colorcode - a command-line color inspector mirroring imagecolorpicker.com.

Given a color (hex, rgb(), hsl(), or a name) it prints a terminal breakdown
of every representation the website shows: conversions, tints/shades,
harmonies, WCAG contrast, and color-blindness simulations. Output uses ANSI
true-color swatches so the actual colour is visible in a 256-color/truecolor
terminal.

Run directly, or register it as a Xonsh alias. This is a pure-stdlib module
(colorsys + math) except for Rich, used only for pretty terminal output.
"""

from __future__ import annotations

import colorsys
import math
import re
from dataclasses import dataclass
from typing import Iterable, List, Sequence, Tuple

from rich.console import Console
from rich.style import Style
from rich.table import Table
from rich.text import Text


# sRGB (D65) -> linear-ised RGB
def _srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _linear_to_srgb(c: float) -> float:
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def _clamp255(x: float) -> int:
    return int(round(max(0.0, min(255.0, x))))


@dataclass(frozen=True)
class Color:
    red: int
    green: int
    blue: int

    @classmethod
    def from_hex(cls, value: str) -> "Color":
        value = value.strip().lstrip("#")
        if len(value) == 3:
            value = "".join(c * 2 for c in value)
        if len(value) != 6 or not re.fullmatch(r"[0-9a-fA-F]{6}", value):
            raise ValueError(f"invalid hex color: {value!r}")
        return cls(*[int(value[i : i + 2], 16) for i in (0, 2, 4)])

    @classmethod
    def from_rgb(cls, red: int, green: int, blue: int) -> "Color":
        return cls(_clamp255(red), _clamp255(green), _clamp255(blue))

    @property
    def hex(self) -> str:
        return f"#{self.red:02X}{self.green:02X}{self.blue:02X}"

    @property
    def rgb01(self) -> Tuple[float, float, float]:
        return self.red / 255.0, self.green / 255.0, self.blue / 255.0

    @property
    def hsl(self) -> Tuple[int, int, int]:
        h, lightness, s = colorsys.rgb_to_hls(*self.rgb01)
        return int(round(h * 360)), int(round(s * 100)), int(round(lightness * 100))

    @property
    def hsv(self) -> Tuple[int, int, int]:
        h, s, v = colorsys.rgb_to_hsv(*self.rgb01)
        return int(round(h * 360)), int(round(s * 100)), int(round(v * 100))

    @property
    def hwb(self) -> Tuple[int, int, int]:
        r, g, b = self.rgb01
        h, _, _ = colorsys.rgb_to_hls(r, g, b)
        w = min(r, g, b)
        blackness = 1 - max(r, g, b)
        return int(round(h * 360)), int(round(w * 100)), int(round(blackness * 100))

    @property
    def cmyk(self) -> Tuple[int, int, int, int]:
        r, g, b = self.rgb01
        k = 1 - max(r, g, b)
        if k == 1:
            return 0, 0, 0, 100
        c = (1 - r - k) / (1 - k)
        m = (1 - g - k) / (1 - k)
        y = (1 - b - k) / (1 - k)
        return int(round(c * 100)), int(round(m * 100)), int(round(y * 100)), int(round(k * 100))

    @property
    def rgb_string(self) -> str:
        return f"rgb({self.red}, {self.green}, {self.blue})"

    # --- perceptual colour spaces (D65 reference white) ---
    def _xyz(self) -> Tuple[float, float, float]:
        r, g, b = (_srgb_to_linear(c) for c in self.rgb01)
        return (
            0.4124564 * r + 0.3575761 * g + 0.1804375 * b,
            0.2126729 * r + 0.7151522 * g + 0.0721750 * b,
            0.0193339 * r + 0.1191920 * g + 0.9503041 * b,
        )

    @property
    def xyz(self) -> Tuple[int, int, int]:
        x, y, z = self._xyz()
        return int(round(x * 100)), int(round(y * 100)), int(round(z * 100))

    @property
    def xyy(self) -> Tuple[float, float, float]:
        x, y, z = self._xyz()
        total = x + y + z
        if total == 0:
            return 0.0, 0.0, 0.0
        return x / total, y / total, y * 100

    def _lab_f(self, t: float) -> float:
        e = 216 / 24389
        k = 24389 / 27
        if t > e:
            return t ** (1 / 3)
        return (k * t + 16) / 116

    @property
    def lab(self) -> Tuple[float, float, float]:
        x, y, z = self._xyz()
        xn, yn, zn = 0.95047, 1.00000, 1.08883
        fx, fy, fz = self._lab_f(x / xn), self._lab_f(y / yn), self._lab_f(z / zn)
        return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)

    @property
    def lch(self) -> Tuple[float, float, float]:
        L, a, b = self.lab
        c = math.hypot(a, b)
        h = math.degrees(math.atan2(b, a)) % 360
        return L, c, h

    @property
    def luv(self) -> Tuple[float, float, float]:
        X, Y, Z = self._xyz()
        un, vn = 0.19783, 0.46832
        denom = X + 15 * Y + 3 * Z
        u_prime = 4 * X / denom if denom else 0.0
        v_prime = 9 * Y / denom if denom else 0.0
        yr = Y / 1.00000
        L = 116 * yr ** (1 / 3) - 16 if yr > (216 / 24389) else (24389 / 27) * yr
        return L, 13 * L * (u_prime - un), 13 * L * (v_prime - vn)

    def mixed_with(self, other: "Color", amount: float) -> "Color":
        """Blend this color towards `other` by `amount` (0..1)."""
        r = self.red + (other.red - self.red) * amount
        g = self.green + (other.green - self.green) * amount
        b = self.blue + (other.blue - self.blue) * amount
        return Color.from_rgb(r, g, b)

    @property
    def luminance(self) -> float:
        r, g, b = (_srgb_to_linear(c) for c in self.rgb01)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b

    def contrast_against(self, other: "Color") -> float:
        l1, l2 = self.luminance, other.luminance
        if l1 < l2:
            l1, l2 = l2, l1
        return (l1 + 0.05) / (l2 + 0.05)

    def with_hue(self, hue_deg: float, keep: str = "hsl") -> "Color":
        """Return a colour with `hue_deg`, preserving the current
        saturation/lightness (hsl) or saturation/value (hsv)."""
        hue = (hue_deg % 360) / 360.0
        if keep == "hsv":
            h, s, v = colorsys.rgb_to_hsv(*self.rgb01)
            r, g, b = colorsys.hsv_to_rgb(hue, s, v)
        else:
            h, lightness, s = colorsys.rgb_to_hls(*self.rgb01)
            r, g, b = colorsys.hls_to_rgb(hue, lightness, s)
        return Color.from_rgb(r * 255, g * 255, b * 255)

    def simulate_blindness(self, kind: str) -> "Color":
        """Apply a Machado 2009 colour-deficiency matrix at full severity.

        Matrices are designed for linear sRGB and then gamma-encoded back.
        """
        matrices = {
            "protan": ((0.152286, 1.052583, -0.204868),
                       (0.114503, 0.786281, 0.099216),
                       (-0.003882, -0.048116, 1.051998)),
            "deutan": ((0.367322, 0.860646, -0.227968),
                       (0.280085, 0.672501, 0.047413),
                       (-0.011820, 0.042940, 0.968881)),
            "tritan": ((1.255528, -0.076749, -0.178779),
                       (-0.078411, 0.930809, 0.147602),
                       (0.004733, 0.691367, 0.303900)),
        }
        if kind == "achromatopsia":
            y = self.luminance
            v = _linear_to_srgb(y)
            return Color.from_rgb(v * 255, v * 255, v * 255)
        M = matrices[kind]
        r, g, b = (_srgb_to_linear(c) for c in self.rgb01)
        nr = M[0][0] * r + M[0][1] * g + M[0][2] * b
        ng = M[1][0] * r + M[1][1] * g + M[1][2] * b
        nb = M[2][0] * r + M[2][1] * g + M[2][2] * b
        return Color.from_rgb(_linear_to_srgb(nr) * 255, _linear_to_srgb(ng) * 255, _linear_to_srgb(nb) * 255)


def parse_color(value: str) -> Color:
    """Accept #hex, hex, rgb(...), hsl(...), or "r,g,b"."""
    v = value.strip()
    if v.startswith("#") or re.fullmatch(r"[0-9a-fA-F]{3}|[0-9a-fA-F]{6}", v):
        return Color.from_hex(v)
    rgb = re.fullmatch(r"rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", v, re.I)
    if rgb:
        return Color.from_rgb(*map(int, rgb.groups()))
    hsl = re.fullmatch(r"hsl\(\s*(\d+)\s*,\s*(\d+)%?\s*,\s*(\d+)%?\s*\)", v, re.I)
    if hsl:
        h, s, lightness = map(int, hsl.groups())
        r, g, b = colorsys.hls_to_rgb((h % 360) / 360.0, lightness / 100.0, s / 100.0)
        return Color.from_rgb(r * 255, g * 255, b * 255)
    tri = re.fullmatch(r"(\d+)[, ]+(\d+)[, ]+(\d+)", v)
    if tri:
        return Color.from_rgb(*map(int, tri.groups()))
    raise ValueError(f"could not parse color: {value!r}")


# ---------------------------------------------------------------------------
# Rendering helpers
# ---------------------------------------------------------------------------
console = Console()


def swatch(color: Color, label: str = "", text: str = None) -> Text:
    """A rendered color block, optionally with a label."""
    style = Style(bgcolor=color.hex)
    block = Text("  ", style=style)
    if text is None:
        text = color.hex
    t = Text()
    t.append(block)
    if label:
        t.append(f" {label:<14}")
    t.append(f" {text}")
    return t


def _hex_grid(color: Color, count: int, direction: int) -> List[Color]:
    """Generate tints (direction=1, toward white) or shades (direction=-1,
    toward black) in 10% steps."""
    target = Color(255, 255, 255) if direction > 0 else Color(0, 0, 0)
    return [color.mixed_with(target, i / count) for i in range(1, count + 1)]


def _harmonies(color: Color) -> List[Tuple[str, str, List[Color]]]:
    h, _, _ = color.hsl
    complement = (h + 180) % 360
    split = [(complement + 30) % 360, (complement - 30) % 360]
    triadic = [(h + 120) % 360, (h + 240) % 360]
    analogous = [(h - 30) % 360, (h + 30) % 360]
    # Monochromatic: same hue, luminance +/- 50%. Build lighter and darker
    # variants by blending toward white/black.
    half = 0.5
    mono = [color.mixed_with(Color(255, 255, 255), half), color, color.mixed_with(Color(0, 0, 0), half)]
    tetradic = [(h + 60) % 360, (h + 180) % 360, (h + 240) % 360]

    def render(hues: Sequence[float]) -> List[Color]:
        return [color.with_hue(d) for d in hues]

    return [
        ("Complement", "opposite on the wheel (+180 deg); high contrast", render([complement])),
        ("Split-complementary", "complement +/-30 deg; bold but versatile", render(split)),
        ("Triadic", "120 deg apart; lively, balanced", render(triadic)),
        ("Analogous", "adjacent hues, 30 deg apart; calm", render(analogous)),
        ("Monochromatic", "same hue, varied lightness", mono),
        ("Tetradic", "two complementary pairs, 60 deg apart", render(tetradic)),
    ]


# ---------------------------------------------------------------------------
# Sub-reports
# ---------------------------------------------------------------------------
def report_conversions(color: Color) -> None:
    h, s, lightness = color.hsl
    hv, sv, vv = color.hsv
    hw, w, b = color.hwb
    table = Table(title="Color conversion", title_style="bold")
    table.add_column("Format", style="bold")
    table.add_column("Value", no_wrap=True)
    table.add_row("HEX", color.hex)
    table.add_row("RGB", color.rgb_string)
    table.add_row("HSL", f"hsl({h}, {s}%, {lightness}%)")
    table.add_row("HSV", f"hsv({hv}, {sv}%, {vv}%)")
    table.add_row("HWB", f"hwb({hw}, {w}%, {b}%)")
    cmyk = color.cmyk
    table.add_row("CMYK", f"cmyk({cmyk[0]}, {cmyk[1]}, {cmyk[2]}, {cmyk[3]})")
    xyz = color.xyz
    table.add_row("XYZ", f"xyz({xyz[0]}, {xyz[1]}, {xyz[2]})")
    lab = color.lab
    table.add_row("LAB", f"lab({lab[0]:.0f}, {lab[1]:.0f}, {lab[2]:.0f})")
    lch = color.lch
    table.add_row("LCH", f"lch({lch[0]:.0f}, {lch[1]:.0f}, {lch[2]:.0f})")
    luv = color.luv
    table.add_row("LUV", f"luv({luv[0]:.0f}, {luv[1]:.0f}, {luv[2]:.0f})")
    xy = color.xyy
    table.add_row("xyY", f"xyY({xy[0]:.3f}, {xy[1]:.3f}, {xy[2]:.1f})")
    console.print(table)


def report_variations(color: Color) -> None:
    console.print("\n[bold]Variations[/bold] (10% steps)")
    console.print("[dim]Shades add black; tints add white.[/dim]")
    console.print("\n[bold]Shades[/bold]")
    for c in _hex_grid(color, 10, -1):
        console.print(swatch(c, label=f"{c.red:3d},{c.green:3d},{c.blue:3d}"))
    console.print("\n[bold]Tints[/bold]")
    for c in _hex_grid(color, 10, 1):
        console.print(swatch(c, label=f"{c.red:3d},{c.green:3d},{c.blue:3d}"))


def report_harmonies(color: Color) -> None:
    console.print("\n[bold]Color combinations[/bold]")
    for name, desc, colors in _harmonies(color):
        console.print(f"\n[bold]{name}[/bold] - [dim]{desc}[/dim]")
        console.print(swatch(color, label="base"))
        for c in colors:
            console.print(swatch(c, label=name))


def report_contrast(color: Color, background: Color | None) -> None:
    console.print("\n[bold]Color contrast checker[/bold]")
    bg = background or Color(255, 255, 255)
    ratio = color.contrast_against(bg)
    label = "AAA" if ratio >= 7 else ("AA" if ratio >= 4.5 else ("AA (large)" if ratio >= 3 else "Fail"))
    console.print(swatch(color, label="text"))
    console.print(swatch(bg, label="background"))
    console.print(f"\nContrast ratio: [bold]{ratio:.2f}[/bold]  [green]{label}[/green]")
    console.print("[dim]AA >= 4.5, AA (large) >= 3, AAA >= 7[/dim]")


def report_blindness(color: Color) -> None:
    console.print("\n[bold]Blindness simulator[/bold]")
    console.print(swatch(color, label="normal"))
    for kind in ("protan", "deutan", "tritan", "achromatopsia"):
        sim = color.simulate_blindness(kind)
        console.print(swatch(sim, label=kind.title()))


def report_color(color: Color, background: Color | None, sections: Iterable[str]) -> None:
    console.print(swatch(color, label="color"), style="bold")
    chosen = set(sections)
    if not chosen or "all" in chosen:
        chosen = {"conversion", "variations", "harmonies", "contrast", "blindness"}
    if "conversion" in chosen:
        report_conversions(color)
    if "variations" in chosen:
        report_variations(color)
    if "harmonies" in chosen:
        report_harmonies(color)
    if "contrast" in chosen:
        report_contrast(color, background)
    if "blindness" in chosen:
        report_blindness(color)


def main(argv: Sequence[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        prog="colorcode",
        description="Inspect a color like imagecolorpicker.com, in your terminal.",
        epilog="Examples: colorcode c69676 | colorcode '#c69676' --bg 000000 | colorcode 198,150,118 --sections conversion,harmonies",
    )
    parser.add_argument("color", help="hex (#c69676 / c69676), rgb(198,150,118), or 198,150,118")
    parser.add_argument("--bg", help="background color for the contrast check (default #ffffff)")
    parser.add_argument(
        "--sections",
        default="all",
        help="comma list: conversion,variations,harmonies,contrast,blindness (default all)",
    )
    args = parser.parse_args(argv)

    try:
        color = parse_color(args.color)
    except ValueError as exc:
        parser.error(str(exc))
    background = None
    if args.bg:
        background = parse_color(args.bg)
    sections = [s.strip().lower() for s in args.sections.split(",") if s.strip()]
    report_color(color, background, sections)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
