# detect_silence_blocks.py
from PIL import Image
import numpy as np, json, sys

# capture_path = sys.argv[1]
capture_path = '/Users/wesdemos/Downloads/screenpal-caps/Position_Slider.png'

S_MAX   = float(sys.argv[2]) if len(sys.argv)>2 else 30   # tweak
V_MIN   = int(sys.argv[3])  if len(sys.argv)>3 else 60
V_MAX   = int(sys.argv[4])  if len(sys.argv)>4 else 200
COL_FRAC= float(sys.argv[5]) if len(sys.argv)>5 else 0.20 # column coverage threshold
MIN_W   = int(sys.argv[6])  if len(sys.argv)>6 else 10    # min width in px

image  = Image.open(capture_path).convert("RGB")
hsv = np.array(image.convert("HSV"))
H,S,V = hsv[...,0], hsv[...,1], hsv[...,2]

gray = (S <= S_MAX) & (V >= V_MIN) & (V <= V_MAX)
coverage = gray.sum(axis=0) / float(gray.shape[0])
active = coverage > COL_FRAC

# merge contiguous columns
ranges, s = [], None
for x,a in enumerate(active):
    if a and s is None: s = x
    if (not a) and s is not None:
        ranges.append((s, x-1)); s = None
if s is not None: ranges.append((s, active.size-1))
ranges = [(x0,x1) for (x0,x1) in ranges if (x1-x0+1)>=MIN_W]

print(json.dumps({
  "width_px": image.width, "height_px": image.height,
  "blocks": [{"x_start":int(a), "x_end":int(b), "width":int(b-a+1)} for a,b in ranges]
}))

