"""Find a 16-color palette that is perceptually distinct on a dark background.

The hex viewer (``hex.py``) colors each byte by its position within a 16-byte
line, so no color repeats on a line. Two colors that are only a few positions
apart can end up adjacent (a space in the hex column, or a line boundary, can
shift which colors line up), so the palette must be maximally distinct not just
globally but especially for neighbors at offsets 1..4.

This script makes that selection mechanical:

1. Build a large pool of candidate RGB colors.
2. Reject any color whose WCAG contrast against the terminal background is
   below a threshold (a dark background makes dark colors invisible).
3. Convert survivors to OKLab and score a candidate 16-color cyclic palette by
   the minimum perceptual distance (ΔE) between colors at offsets 1..4, with
   the worst few pairs and the overall mean as tie-breakers.
4. Hill-climb with random mutations (and restarts) from the existing palette to
   find a better one.

Run it and paste the resulting ``BYTE_COLORS`` tuple back into ``hex.py``.
"""

from __future__ import annotations

import argparse
import math
import random
from dataclasses import dataclass


# The terminal background the palette must be readable against.
BACKGROUND: tuple[int, int, int] = (0x1F, 0x22, 0x29)  # #1f2229

# Minimum WCAG contrast a color must have against the background to be usable.
MIN_CONTRAST: float = 4.5

PALETTE_SIZE: int = 16

# Which cyclic offsets to maximize perceptual distance for. Offsets 1..4 cover
# the neighbor combinations that spaces / line boundaries can actually expose.
OFFSETS: tuple[int, ...] = (1, 2, 3, 4)

# The existing hand-picked palette: a good starting point for the search.
SEED_PALETTE: tuple[str, ...] = (
    "#FF3B30",
    "#FFA726",
    "#FFEA00",
    "#D4E157",
    "#00E676",
    "#A5D6A7",
    "#1DE9B6",
    "#4DB6AC",
    "#00E5FF",
    "#4DD0E1",
    "#2979FF",
    "#64B5F6",
    "#B026FF",
    "#9575CD",
    "#8D6E63",
    "#9E9E9E",
)


# ---- Color math -------------------------------------------------------------


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    """Convert ``#RRGGBB`` to an (r, g, b) tuple of 0..255 ints."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return (r, g, b)


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    """Convert an (r, g, b) tuple of 0..255 ints to ``#RRGGBB``."""
    return f"#{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}"


def srgb_to_linear(channel: float) -> float:
    """Convert a single sRGB channel (0..1) to linear light."""
    if channel <= 0.04045:
        return channel / 12.92
    return ((channel + 0.055) / 1.055) ** 2.4


def relative_luminance(rgb: tuple[int, int, int]) -> float:
    """WCAG relative luminance for an (r, g, b) tuple of 0..255 ints."""
    r, g, b = (channel / 255 for channel in rgb)
    return (
        0.2126 * srgb_to_linear(r)
        + 0.7152 * srgb_to_linear(g)
        + 0.0722 * srgb_to_linear(b)
    )


def contrast_ratio(c1: tuple[int, int, int], c2: tuple[int, int, int]) -> float:
    """WCAG contrast ratio between two colors."""
    l1 = relative_luminance(c1)
    l2 = relative_luminance(c2)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def rgb_to_oklab(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    """Convert an (r, g, b) tuple of 0..255 ints to OKLab (L, a, b)."""
    r, g, b = (srgb_to_linear(channel / 255) for channel in rgb)

    # Linear sRGB -> LMS.
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    # LMS -> OKLab.
    l_cbrt, m_cbrt, s_cbrt = math.copysign(abs(l) ** (1 / 3), l), math.copysign(
        abs(m) ** (1 / 3), m
    ), math.copysign(abs(s) ** (1 / 3), s)
    L = 0.2104542553 * l_cbrt + 0.7936177850 * m_cbrt - 0.0040720468 * s_cbrt
    a = 1.9779984951 * l_cbrt - 2.4285922050 * m_cbrt + 0.4505937099 * s_cbrt
    b = 0.0259040371 * l_cbrt + 0.7827717662 * m_cbrt - 0.8086757660 * s_cbrt
    return (L, a, b)


def delta_e(c1: tuple[float, float, float], c2: tuple[float, float, float]) -> float:
    """Perceptual distance (ΔE) between two OKLab colors."""
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(c1, c2)))


# ---- Palette scoring ---------------------------------------------------------


@dataclass(frozen=True)
class PaletteScore:
    """A palette's distinguishability metrics, compared lexicographically."""

    worst_pair: float  # min ΔE across every unordered pair (no lookalikes)
    worst_background: float  # min ΔE from the background (every color must pop)
    worst_offset: float  # min ΔE at the exposed offsets 1..4
    mean_offset: float  # average ΔE across offsets 1..4

    def better_than(self, other: "PaletteScore") -> bool:
        """True if this palette is strictly better (higher is better)."""
        return (
            self.worst_pair,
            self.worst_background,
            self.worst_offset,
            self.mean_offset,
        ) > (
            other.worst_pair,
            other.worst_background,
            other.worst_offset,
            other.mean_offset,
        )


def palette_score(colors: list[tuple[int, int, int]]) -> PaletteScore:
    """Score a cyclic palette by OKLab ΔE.

    All 16 colors appear on the same line at once, so no two may look alike:
    the global minimum pair distance is the primary metric. The background is
    factored in next, so the search also maximizes how much each color pops off
    the dark background (not just how far apart colors are from each other).
    The offsets 1..4 are the neighbors that spaces / line boundaries can force
    together, so they get extra margin as a tie-breaker. Maximizing the tuple
    in ``better_than`` does all of this.
    """
    oklab_colors = [rgb_to_oklab(color) for color in colors]
    n = len(oklab_colors)
    background_oklab = rgb_to_oklab(BACKGROUND)

    all_pairs = [
        delta_e(oklab_colors[i], oklab_colors[j])
        for i in range(n)
        for j in range(i + 1, n)
    ]
    background_distances = [
        delta_e(color_oklab, background_oklab) for color_oklab in oklab_colors
    ]
    offsets = [
        delta_e(oklab_colors[i], oklab_colors[(i + offset) % n])
        for i in range(n)
        for offset in OFFSETS
    ]

    return PaletteScore(
        worst_pair=min(all_pairs),
        worst_background=min(background_distances),
        worst_offset=min(offsets),
        mean_offset=sum(offsets) / len(offsets),
    )


# ---- Candidate generation -----------------------------------------------------


def build_candidate_pool(
    step: int = 8, min_contrast: float = MIN_CONTRAST
) -> list[tuple[int, int, int]]:
    """Build every RGB color on a grid that clears the background contrast.

    Set ``min_contrast`` to 0 to allow any color (including dark ones that would
    be invisible on the dark background) and let pure ΔE drive the search.
    """
    candidates: list[tuple[int, int, int]] = []
    for r in range(0, 256, step):
        for g in range(0, 256, step):
            for b in range(0, 256, step):
                color = (r, g, b)
                if contrast_ratio(color, BACKGROUND) >= min_contrast:
                    candidates.append(color)
    return candidates


# ---- Search -------------------------------------------------------------------


def random_color(pool: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    """Pick a random color from the candidate pool."""
    return pool[random.randrange(len(pool))]


def mutate(
    colors: list[tuple[int, int, int]],
    pool: list[tuple[int, int, int]],
) -> list[tuple[int, int, int]]:
    """Replace one random position with a random candidate color."""
    candidate = colors.copy()
    candidate[random.randrange(PALETTE_SIZE)] = random_color(pool)
    return candidate


def hill_climb(
    start: list[tuple[int, int, int]],
    pool: list[tuple[int, int, int]],
    iterations: int,
) -> tuple[list[tuple[int, int, int]], PaletteScore]:
    """Improve a palette by greedy random mutation."""
    current = start.copy()
    current_score = palette_score(current)
    for _ in range(iterations):
        neighbor = mutate(current, pool)
        neighbor_score = palette_score(neighbor)
        if neighbor_score.better_than(current_score):
            current, current_score = neighbor, neighbor_score
    return current, current_score


def optimize(
    pool: list[tuple[int, int, int]],
    restarts: int,
    iterations_per_restart: int,
    seed: list[tuple[int, int, int]],
) -> tuple[list[tuple[int, int, int]], PaletteScore]:
    """Run several hill climbs from random perturbations of the seed."""
    best = seed.copy()
    best_score = palette_score(best)
    for _ in range(restarts):
        start = seed.copy()
        # Perturb a few positions to explore beyond the seed's basin.
        for _ in range(random.randrange(1, 4)):
            start[random.randrange(PALETTE_SIZE)] = random_color(pool)
        candidate, candidate_score = hill_climb(start, pool, iterations_per_restart)
        if candidate_score.better_than(best_score):
            best, best_score = candidate, candidate_score
    return best, best_score


def main() -> None:
    """Search for a 16-color palette and print it as ``#HEX █`` rows."""
    parser = argparse.ArgumentParser(
        description="Pick a 16-color palette maximizing perceptual distance."
    )
    parser.add_argument(
        "--min-contrast",
        type=float,
        default=MIN_CONTRAST,
        help=f"minimum WCAG contrast against the background (default {MIN_CONTRAST}; "
        "0 = allow any color, even ones invisible on a dark background)",
    )
    args = parser.parse_args()

    random.seed(0)
    pool = build_candidate_pool(min_contrast=args.min_contrast)
    seed = [hex_to_rgb(color) for color in SEED_PALETTE]

    print(f"Background: {rgb_to_hex(BACKGROUND)}")
    print(f"Candidate pool (contrast >= {args.min_contrast}): {len(pool)} colors")
    print("Searching...")

    best, best_score = optimize(pool, restarts=40, iterations_per_restart=4000, seed=seed)

    print()
    print(f"Best score: worst_pair={best_score.worst_pair:.4f}, "
          f"worst_background={best_score.worst_background:.4f}, "
          f"worst_offset={best_score.worst_offset:.4f}, "
          f"mean_offset={best_score.mean_offset:.4f}")
    print()
    for color in best:
        print(f"{rgb_to_hex(color)} \u2588")


if __name__ == "__main__":
    main()
