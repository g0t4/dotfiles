import os
import sys
from typing import NamedTuple
import cv2 as cv
import numpy as np
from pathlib import Path

# TODO make into arg
file = Path(os.getenv("WES_DOTFILES") or "") \
    / ".config/hammerspoon/config/macros/screenpal/py/timeline03a.png"

image = cv.imread(str(file), cv.IMREAD_COLOR)  # BGR
if image is None:
    raise ValueError(f"Could not load image from {file}")

class TimelineColorsBGR(NamedTuple):
    timeline_bg: np.ndarray
    silence_gray: np.ndarray
    playhead: np.ndarray

# FYI use colors.py to deterine colors to use and then inline values here:

colors_bgr = TimelineColorsBGR(
    # opencv values!
    timeline_bg=np.array([41, 19, 16]),
    silence_gray=np.array([57, 37, 34]),
    playhead=np.array([255, 157, 37]),
)

# Tiny tolerance may handle edge pixels
tolerance = 4

def color_mask(img, color, tol):
    diff = np.abs(img.astype(np.int16) - color.astype(np.int16))
    return (diff <= tol).all(axis=2).astype(np.uint8) * 255

gray_box_direct_mask = color_mask(image, colors_bgr.silence_gray, tolerance)  # skip ROI b/c the image is ONLY the timeline so there's no reason to spot the timeline!
timeline_mask = color_mask(image, colors_bgr.timeline_bg, tolerance)  # leave so you can come back to this later for additional detection (i.e. unmarked silences, < 1 second)
playhead_mask = color_mask(image, colors_bgr.playhead, tolerance)

# Highlight colors (BGR order for OpenCV)
RED = (0, 0, 255)
GREEN = (0, 255, 0)
BLUE = (255, 0, 0)
YELLOW = (0, 255, 255)
CYAN = (255, 255, 0)
MAGENTA = (255, 0, 255)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
ORANGE = (0, 165, 255)
PURPLE = (128, 0, 128)

def mask_only(image, mask, highlight_color=RED) -> np.ndarray:

    highlight_overlay = np.zeros_like(image)  # same shape as image
    highlight_overlay[mask > 0] = highlight_color

    return highlight_overlay

def blend_mask_over_image(image, mask, alpha=0.7, highlight_color=RED) -> np.ndarray:
    beta = 1.0 - alpha

    highlight_overlay = mask_only(image, mask, highlight_color)

    # Blend image with overlay
    blended = cv.addWeighted(image, alpha, highlight_overlay, beta, 0)
    return blended

images = [
    # image, # include image but not really necessary
    blend_mask_over_image(image, gray_box_direct_mask),
    mask_only(image, gray_box_direct_mask),
    blend_mask_over_image(image, timeline_mask),
    mask_only(image, timeline_mask),
    blend_mask_over_image(image, playhead_mask, alpha=0.5, highlight_color=YELLOW),
    mask_only(image, playhead_mask, highlight_color=YELLOW),
]
# stacked = np.vstack(images)
# cv.imshow("stacked", stacked)
# cv.waitKey(0)
# cv.destroyAllWindows()

# %%

# Static label-to-color mapping (BGR format for OpenCV)
label_colors = {
    0: (0, 0, 0),  # background (black)
    1: (255, 0, 0),  # blue
    2: (0, 255, 0),  # green
    3: (0, 0, 255),  # red
    4: (255, 255, 0),  # cyan
    5: (255, 0, 255),  # magenta
    6: (0, 255, 255),  # yellow
    7: (128, 0, 128),  # purple
    8: (255, 165, 0),  # orange
    9: (128, 128, 0),  # olive
    10: (0, 128, 128),  # teal
}

def visualize_labeled_regions(labels):
    h, w = labels.shape
    output = np.zeros((h, w, 3), dtype=np.uint8)

    # make sure none over 10
    if np.any(labels > len(label_colors) - 1):
        raise ValueError("Labels exceed 10, can only color up to 10 unless you expand list of label_colors")  # or handle appropriately for your use case

    for label, color in label_colors.items():
        output[labels == label] = color

    return output

# make a divider like the background color #2C313C
black_divider = np.zeros_like(image)
black_divider[:] = [60, 49, 44]  # BGR for #2C313C
# take half height divider:
black_divider = black_divider[:image.shape[0] // 2, :image.shape[1]]  # first half of image

# *** DIRECT ( THIS IS REALLY GOOD IN MY TESTING!!!) ...
#   it does detect the playhead and the white dashed vertical line from recording mark, but I could skip over those with a n algorithm of some sort to connect sections with tiny tiny gaps (<4 pixels wide) assuming both sides are silence
gray_box_mask = color_mask(image, colors_bgr.silence_gray, tolerance + 2)  # slightly looser for AA edges
gray_box_mask_smooth = cv.morphologyEx(gray_box_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))  # smooth out, skip freckled matches
images.append(black_divider)
images.append(mask_only(image, gray_box_mask))
images.append(mask_only(image, gray_box_mask_smooth))
stacked = np.vstack(images)
# cv.imshow("stacked", stacked)
# cv.waitKey(0)
# cv.destroyAllWindows()

num_labels, labels, stats, _ = cv.connectedComponentsWithStats(gray_box_mask_smooth, connectivity=8)
labeled_mask = visualize_labeled_regions(labels)
cv.imshow("labeled_mask", labeled_mask)
cv.waitKey(0)
cv.destroyAllWindows()

# # *** add playhead to gray_box_mask (will be fine b/c I won't take any region like the playhead that is only 2 pixels wide anyways)
# gray_box_with_playhead_mask = cv.bitwise_or(gray_box_mask, playhead_mask)
# gray_box_with_playhead_mask_smooth = cv.morphologyEx(gray_box_with_playhead_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))  # smooth out, skip freckled matches
# num_labels, labels, stats, _ = cv.connectedComponentsWithStats(gray_box_with_playhead_mask_smooth, connectivity=8)
# labeled_mask = visualize_labeled_regions(labels)
# cv.imshow("labeled_mask_with_playhead", labeled_mask)
# cv.waitKey(0)
# cv.destroyAllWindows()

# *** scale down to 1080p for returning to hs

print("4k stats:")
print(stats)
print("1080p stats:")
# first four stats are: left, top, width, height
# fifth is area
# to get to 1080p I need to divide first four by 2
# then the fifth is area so I need to divide that by 4
# assume 1080p scaling is 2x (because 1920x1080 -> 960x540)
stats_1080p = stats.copy()
stats_1080p[:, :4] //= 2
stats_1080p[:, 4] //= 4
print("1080p stats:")
print(stats_1080p)

print(f'{labels=}')
# TODO left off here

box_label = 1 + np.argmax(stats[1:, cv.CC_STAT_AREA])
bx, by, bw, bh, _ = stats[box_label]

# TODO finalize regions! and return json object to lua code!
