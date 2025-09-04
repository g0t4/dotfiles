# detect_silence_blocks.py
from PIL import Image
import numpy as np, json, sys

# capture_path = sys.argv[1]
capture_path = '/Users/wesdemos/Downloads/screenpal-caps/Position-m2-02.png'

S_MAX   = float(sys.argv[2]) if len(sys.argv)>2 else 30   # tweak
V_MIN   = int(sys.argv[3])  if len(sys.argv)>3 else 60
V_MAX   = int(sys.argv[4])  if len(sys.argv)>4 else 200
COL_FRAC= float(sys.argv[5]) if len(sys.argv)>5 else 0.20 # column coverage threshold
MIN_W   = int(sys.argv[6])  if len(sys.argv)>6 else 10    # min width in px

image  = Image.open(capture_path).convert("RGB")
hsv = np.array(image.convert("HSV"))
H,S,V = hsv[...,0], hsv[...,1], hsv[...,2]


top_offset = 10
top_line_H :np.ndarray = H[top_offset]
top_line_S = S[top_offset]
top_line_V = V[top_offset]

# %%

from typing import List, Tuple

def build_ranges(top_line_readings: np.ndarray) -> List[Tuple[int, int, int]]:
    """Build ranges where the value doesn't change in a 1D array."""
    if top_line_readings.size == 0:
        return []

    ranges = []
    start = 0
    current_value = top_line_readings[0]

    for i in range(1, top_line_readings.size):
        if top_line_readings[i] != current_value:
            ranges.append((start, i, current_value))
            start = i
            current_value = top_line_readings[i]

    # Add the final range
    ranges.append((start, top_line_readings.size, current_value))

    return ranges

# Example usage:
ranges = build_ranges(top_line_V)
ranges
# for start, end, value in ranges:
#     print(f"Range [{start}:{end}] = {value}")

# sample! it is working!!!
#   open image in preview
#   drag selection from left side to various points and compare to changes below:
#   RANGES manually detected:
#   - 692 => 845
#   - 2150 => 2304 (white dash line) 2306 => 2370
#   - 2978 => 3198
#   FYI when zoomed in, can see some borders/shadows between sections, almost all a few pixels wide max... can skip those based on width
#
# V: 57 looks like it works
#
# [(0, 2, np.uint8(255)),
#  (2, 688, np.uint8(41)),
#  (688, 690, np.uint8(37)),
#  (690, 692, np.uint8(28)),
#  (692, 846, np.uint8(57)),
#  (846, 848, np.uint8(20)),
#  (848, 850, np.uint8(37)),
#  (850, 2146, np.uint8(41)),
#  (2146, 2148, np.uint8(37)),
#  (2148, 2150, np.uint8(28)),
#  (2150, 2304, np.uint8(57)),
#  (2304, 2306, np.uint8(50)),
#  (2306, 2370, np.uint8(57)),
#  (2370, 2372, np.uint8(20)),
#  (2372, 2374, np.uint8(37)),
#  (2374, 2974, np.uint8(41)),
#  (2974, 2976, np.uint8(37)),
#  (2976, 2978, np.uint8(28)),
#  (2978, 3198, np.uint8(57)),
#  (3198, 3200, np.uint8(20)),
#  (3200, 3202, np.uint8(37)),
#  (3202, 3496, np.uint8(41)),
#  (3496, 3497, np.uint8(58)),
#  (3497, 3498, np.uint8(148)),
#  (3498, 3499, np.uint8(142)),
#  (3499, 3500, np.uint8(71))]
#

#
# S: (102 matches the sections)
# [(0, 2, np.uint8(218)),
#  (2, 688, np.uint8(155)),
#  (688, 690, np.uint8(158)),
#  (690, 692, np.uint8(100)),
#  (692, 846, np.uint8(102)),
#  (846, 848, np.uint8(153)),
#  (848, 850, np.uint8(158)),
#  (850, 2146, np.uint8(155)),
#  (2146, 2148, np.uint8(158)),
#  (2148, 2150, np.uint8(100)),
#  (2150, 2304, np.uint8(102)),
#  (2304, 2306, np.uint8(40)),
#  (2306, 2370, np.uint8(102)),
#  (2370, 2372, np.uint8(153)),
#  (2372, 2374, np.uint8(158)),
#  (2374, 2974, np.uint8(155)),
#  (2974, 2976, np.uint8(158)),
#  (2976, 2978, np.uint8(100)),
#  (2978, 3198, np.uint8(102)),
#  (3198, 3200, np.uint8(153)),
#  (3200, 3202, np.uint8(158)),
#  (3202, 3496, np.uint8(155)),
#  (3496, 3497, np.uint8(136)),
#  (3497, 3498, np.uint8(106)),
#  (3498, 3499, np.uint8(107)),
#  (3499, 3500, np.uint8(143))]

#
# H: 164 matches sections but also non-sections
# [(0, 2, np.uint8(146)),
#  (2, 690, np.uint8(164)),
#  (690, 692, np.uint8(166)),
#  (692, 846, np.uint8(164)),
#  (846, 848, np.uint8(166)),
#  (848, 2148, np.uint8(164)),
#  (2148, 2150, np.uint8(166)),
#  (2150, 2304, np.uint8(164)),
#  (2304, 2306, np.uint8(148)),
#  (2306, 2370, np.uint8(164)),
#  (2370, 2372, np.uint8(166)),
#  (2372, 2976, np.uint8(164)),
#  (2976, 2978, np.uint8(166)),
#  (2978, 3198, np.uint8(164)),
#  (3198, 3200, np.uint8(166)),
#  (3200, 3497, np.uint8(164)),
#  (3497, 3498, np.uint8(163)),
#  (3498, 3500, np.uint8(164))]

# %%






# gray = (S <= S_MAX) & (V >= V_MIN) & (V <= V_MAX)
# coverage = gray.sum(axis=0) / float(gray.shape[0])
# active = coverage > COL_FRAC

# merge contiguous columns
ranges, s = [], None
for x,a in enumerate(active):
    if a and s is None: s = x
    if (not a) and s is not None:
        ranges.append((s, x-1)); s = None
if s is not None: ranges.append((s, active.size-1))
ranges = [(x0,x1) for (x0,x1) in ranges if (x1-x0+1)>=MIN_W]

ranges

print(json.dumps({
  "width_px": image.width, "height_px": image.height,
  "blocks": [{"x_start":int(a), "x_end":int(b), "width":int(b-a+1)} for a,b in ranges]
}))

