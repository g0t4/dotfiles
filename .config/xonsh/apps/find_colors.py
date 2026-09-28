# dark background: #1f2229
#
# Yep. I'd make palette selection **mechanical**.
#
# Use **OKLab** and compute perceptual distance (`ΔE`) between every pair. For your particular byte-coloring scheme, don't optimize only global pairwise distance: heavily weight distances at palette offsets **1–4**, because spaces can advance the palette and expose those combinations.
#
# ### Basic metric
#
# Given two colors converted to OKLab `(L, a, b)`:
#
# ```python
# import math
#
# def delta_e(c1, c2):
#     return math.sqrt(sum((a - b) ** 2 for a, b in zip(c1, c2)))
# ```
#
# OKLab values are typically around `0..1`, so you'll see distances like `.1`, `.25`, etc. **Higher = more visually distinct.**
#
# Then score your cyclic 16-color palette:
#
# ```python
# def palette_score(colors):
#     n = len(colors)
#
#     distances = [
#         delta_e(colors[i], colors[(i + offset) % n])
#         for i in range(n)
#         for offset in range(1, 5)
#     ]
#
#     return min(distances)
# ```
#
# That asks:
#
# > What's the **worst-case distinguishability** of any two colors that could end up close together?
#
# Which is almost exactly your problem.
#
# ### I'd improve it slightly
#
# You don't want one barely-bad pair completely dominating otherwise excellent palettes, so track several metrics:
#
# ```python
# def palette_score(colors):
#     n = len(colors)
#
#     distances = sorted(
#         delta_e(colors[i], colors[(i + offset) % n])
#         for i in range(n)
#         for offset in range(1, 5)
#     )
#
#     return (
#         distances[0],                 # worst pair
#         sum(distances[:8]) / 8,       # worst neighborhood
#         sum(distances) / len(distances),
#     )
# ```
#
# Python tuple comparison gives you exactly what you want: **maximize the worst pair first**, then use the other metrics as tie-breakers.
#
# ### Background contrast separately
#
# Also calculate WCAG contrast against your terminal background. That's a *different property* from color-to-color perceptual distance.
#
# Require something like:
#
# ```text
# contrast(color, background) >= 4.5
# ```
#
# before a color is even eligible.
#
# Then:
#
# ```text
# candidate RGB colors
#        │
#        ├── reject insufficient bg contrast
#        │
#        ↓
#      OKLab
#        │
#        ↓
# search for 16 colors
#        │
#        ↓
# maximize ΔE for offsets 1..4
# ```
#
# ### And here's where this gets fun
#
# You can have DeepSeek write a little optimizer that starts with, say, **thousands of candidate RGB colors**, filters them, and uses simulated annealing / random mutation to find increasingly better 16-color palettes.
#
# Then print:
#
# ```text
# #FF3830 █
# #FFB740 █
# #FFEA00 █
# ...
# ```
#
# and **Elephant itself can render candidate palettes**.
#
# You'd no longer be asking DS *“do these colors look different?”*
#
# You'd be telling it:
#
# > **Find the palette maximizing the minimum perceptual distance under the actual constraints of Elephant's renderer.**
#
# That's a *much* better problem for it.
