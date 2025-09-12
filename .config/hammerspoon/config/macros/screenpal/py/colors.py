import sys
from typing import NamedTuple
import numpy as np
import cv2 as cv
from pathlib import Path
import os

# this is just to sample colors for timeline detection, if SPAL updates you'll need to do this again, use this file as a guide
samples_dir = Path(os.getenv("WES_DOTFILES") or "") / ".config/hammerspoon/config/macros/screenpal/py/samples"
file = samples_dir / "timeline03a.png"

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

# FYI NOT USING dedicated insert_bg_mask for now
# # INSERT NEW (BASICALLY SAME COLOR AS TIMELINE BG! just added gradient and SLIGHTLY diff blue!!!
# #   in fact my timeline mask MATCHES the same as a new insert_mask... so I can probably skip the insert mask!
# cv_img_insert_new = cv.imread(str(samples_dir / "insert-new-recording01.png"))
# sample_timeline_bg = cv_img_insert_new[60, 300]
# print(sample_timeline_bg)
# # * ~60y down, 300x (in short silence section, no waveform)
# #0E1328 DCM (R=14, G=19, B=40) approximate
# # BGR = (40, 19, 14) DCM
# # [39 19 15] opencv * USE THIS VALUE
# #
# # * ~90y down, 300x
# # #0F132B (R=15 G=19 B=43)
# #   FYI THIS IS SAME EXACT READING as SOLID COLOR FOR regular TIMELINE BG! (see above)...
# #   TLDR I DO NOT NEED A SPECIAL NEW MASK FOR insert_bg unless I want to maybe match the gradient!!!
# #
# # * ~40y down, 300x
# # #10172F (R=16 G=23 B=47)
# #   FYI could use tight R tolerance of say 3, 6 for G and 10 for B ?

print()

# *** VOLUME TOOL (PINK)
# pink-volume-add-open.png (CURSOR IN middle, no real big effect)
cv_img_pink_volume_add = cv.imread(str(samples_dir / "pink-volume-add-open.png"))
# x=650, y=8 (index 7) (exactly 8th row (index 7th) from top is brightest and right above/below are much darker
#    can do tight tolerance by masking row 8 only!
#ED39CC DCM (R=237, G=57, B=204) # bigger discrepency vs other samples (DCM vs opencv)
print(f'{cv_img_pink_volume_add[7, 650]=}')  # BGR [198,  74, 218] row 8 == offset 7
print(f'{cv_img_pink_volume_add[8, 650]=}')  # BGR [142,  59, 146] row 9

# LEFT UPPER CORNER
# #FF3AE1 DCM RGB - row 8 on leftmost side at cross where it maximizes the pink color in corder (
#   cols 577 578 base1 - 2pixels wide leading edge to volume tool! maybe use this instead? try to find this corner?
# upper right corner is
print(f'# {cv_img_pink_volume_add[7, 576]=} # BGR opencv')
print(f'# {cv_img_pink_volume_add[7, 577]=} # BGR opencv')  # added comment on end of otuput to paste easier into this file:
# cv_img_pink_volume_add[7, 576]=array([219,  79, 247], dtype=uint8) # BGR opencv
# cv_img_pink_volume_add[7, 577]=array([219,  79, 247], dtype=uint8) # BGR opencv
#
# RIGHT UPPER CORNER
# #FF3AE2 DCM RGB - row 8
#  cols 809 and 810 base1 - also 2 pixels wide (right most edge of selection)
#  NOTE E1/E2 in B value... opencv picks up that diff too (219/220)
print(f'# {cv_img_pink_volume_add[7, 808]=} # BGR opencv')
print(f'# {cv_img_pink_volume_add[7, 809]=} # BGR opencv')
# cv_img_pink_volume_add[7, 808]=array([220,  79, 247], dtype=uint8) # BGR opencv
# cv_img_pink_volume_add[7, 809]=array([220,  79, 247], dtype=uint8) # BGR opencv
#
# CURSOR ON START (left)
cv_img_volume_cursor_start = cv.imread(str(samples_dir / "volume-tool/add-cursor-start.png"))
# #FF3BE8
# cols: 1553 to 1556 - 4 pixels wide
print(f'# {cv_img_volume_cursor_start[7, 1552]=} # BGR opencv')
print(f'# {cv_img_volume_cursor_start[7, 1553]=} # BGR opencv')
print(f'# {cv_img_volume_cursor_start[7, 1554]=} # BGR opencv')
print(f'# {cv_img_volume_cursor_start[7, 1555]=} # BGR opencv')
# cv_img_volume_cursor_start[7, 1552]=array([226,  81, 255], dtype=uint8) # BGR opencv
# cv_img_volume_cursor_start[7, 1553]=array([226,  81, 255], dtype=uint8) # BGR opencv
# cv_img_volume_cursor_start[7, 1554]=array([226,  81, 255], dtype=uint8) # BGR opencv
# cv_img_volume_cursor_start[7, 1555]=array([226,  81, 255], dtype=uint8) # BGR opencv

# CURSOR ON END (right)
cv_img_volume_cursor_end = cv.imread(str(samples_dir / "volume-tool/add-cursor-end.png"))
# #FF3BE8
# cols: 1661 to 1664 - 4 pixels wide
print(f'# {cv_img_volume_cursor_end[7, 1660]=} # BGR opencv')
print(f'# {cv_img_volume_cursor_end[7, 1661]=} # BGR opencv')
print(f'# {cv_img_volume_cursor_end[7, 1662]=} # BGR opencv')
print(f'# {cv_img_volume_cursor_end[7, 1663]=} # BGR opencv')
# cv_img_volume_cursor_end[7, 1660]=array([226,  81, 255], dtype=uint8) # BGR opencv
# cv_img_volume_cursor_end[7, 1661]=array([226,  81, 255], dtype=uint8) # BGR opencv
# cv_img_volume_cursor_end[7, 1662]=array([226,  81, 255], dtype=uint8) # BGR opencv
# cv_img_volume_cursor_end[7, 1663]=array([226,  81, 255], dtype=uint8) # BGR opencv
# TO BE SAFE check a ways down too so its not matching some other pink in row 8 on accident:
print(f'# {cv_img_volume_cursor_end[21, 1660]=} # BGR opencv') # GOOD TO GO!
# cv_img_volume_cursor_end[21, 1660]=array([226,  81, 255], dtype=uint8) # BGR opencv
#

#
print()

# *** CUT TOOL (RED)

cv_img_red_cut_add = cv.imread(str(samples_dir / "cut-tool/add-end-selected.png"))
# cols: 1711-1712 (2 pixels) is a border on the left side that could be used to find this too
# 1711 is left most side of selection
# 1817 is the right side's border that is 4 pixels wide b/c it is where cursor currently is at # * CURSOR DETECT in TOOL!
#    cursor position on end => #FF0000 and 4 pixels wide
#    PRN cursor position in middle? IIAC 2 pixels?
#    PRN cursor position on left side?
#    PRN add cursor position, I am not sure I really need to know that b/c I can click to change it too
# 1820 is right most side (however,
#
# also unique is a dashed white line in middle of cut.. not sure if that will affect match, we shall see
# top border: mostly  #9F0000 row8 DCM though right side fades a bit near end of range
#
print(f'{cv_img_red_cut_add[7, 1732]=}')  # BGR [  9,   6, 145]
