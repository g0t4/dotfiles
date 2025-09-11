import sys
from typing import NamedTuple
import numpy as np
import cv2 as cv
from pathlib import Path
import os

# this is just to sample colors for timeline detection, if SPAL updates you'll need to do this again, use this file as a guide
parent_dir = Path(os.getenv("WES_DOTFILES") or "") / ".config/hammerspoon/config/macros/screenpal/py"
file = parent_dir / "timeline03a.png"


cv_image = cv.imread(str(file), cv.IMREAD_COLOR)  # BGR
if cv_image is None:
    raise ValueError(f"Could not load image from {file}")

print(f"{cv_image.shape=}")  # image.shape=(96, 3500, 3)

# I manually determined this adjustment, based on sampling below:
cv_adjust = np.array([-2, 0, 1])

# #0F132B => R=0x0F (15) G=0x13 (19) B=0x2B (43)  -- DIGITAL COLOR METER
timeline_bg_color_digital_color_meter = np.array([43, 19, 15])
timeline_bg_calculated_opencv = timeline_bg_color_digital_color_meter + cv_adjust
print(f'{timeline_bg_calculated_opencv=}')

# #21253B => R=0x21 (33) G=0x25 (37) B=0x3B (59)  -- DIGITAL COLOR METER
silence_gray_box_color_digital_color_meter = np.array([59, 37, 33])
silence_gray_calculated_opencv = silence_gray_box_color_digital_color_meter + cv_adjust
print(f'{silence_gray_calculated_opencv=}')

# y=50, x=40 (4k original resolution) => timeline background (dark blue)
sample_timeline_bg = cv_image[50, 40]
print(f'{sample_timeline_bg=}')
if np.array_equal(sample_timeline_bg, timeline_bg_calculated_opencv) is False:
    raise ValueError(f"expected {timeline_bg_calculated_opencv=} but got {sample_timeline_bg=}")

# y=50, x=1650 (4k original resolution) => silence gray box
sample_gray_box = cv_image[50, 1650]
print(f'{sample_gray_box=}')
if np.array_equal(sample_gray_box, silence_gray_calculated_opencv) is False:
    raise ValueError(f"expected {silence_gray_calculated_opencv=} but got {sample_gray_box=}")

# #00A0FF => R=0x00 G=0xA0 B=0xFF
# playhead_color_digital_color_meter = np.array([255, 160, 0])  # BGR
# y=3 x=1531   (take top of playhead where there is a triangular shape and blue is consistent in the middle)
sample_playhead = cv_image[3, 1531]
print(f'{sample_playhead=}')
# sample_playhead=array([255, 157,  37], dtype=uint8)
