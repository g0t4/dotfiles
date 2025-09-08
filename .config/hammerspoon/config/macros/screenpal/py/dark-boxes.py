import json
import os
import sys
from typing import NamedTuple
import cv2 as cv
import numpy as np
from pathlib import Path
from functools import reduce

DEBUG = "--debug" in sys.argv

if DEBUG:
    print(f'{sys.argv=}')
    from rich import print

# z screenpal/py
# time python3 dark-boxes.py samples/playhead-darkblue1.png --debug

file = sys.argv[1] if len(sys.argv) > 1 else None

image = cv.imread(str(file), cv.IMREAD_COLOR)  # BGR
if image is None:
    raise ValueError(f"Could not load image from {file}")

# * take the bottom of the timeline
# that way audio waveform is most likely to partition dark blue silence periods entirely
# should make it easier to spot them with timeline bg alone
#
# 96 pixels high
#
# image = image[48:] # bottom half
image = image[64:]  # bottom third 2/3*96=64
# image = image[72:] # bottom third 3/4*96=72
print(image.shape)

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

# gray_box_direct_mask = color_mask(image, colors_bgr.silence_gray, tolerance)  # skip ROI b/c the image is ONLY the timeline so there's no reason to spot the timeline!
# gray_box_direct_mask = color_mask(image, colors_bgr.silence_gray, tolerance)  # skip ROI b/c the image is ONLY the timeline so there's no reason to spot the timeline!
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

if DEBUG:
    images = [
        # image, # include image but not really necessary
        blend_mask_over_image(image, timeline_mask),
        mask_only(image, timeline_mask),
        blend_mask_over_image(image, playhead_mask, alpha=0.5, highlight_color=YELLOW),
        mask_only(image, playhead_mask, highlight_color=YELLOW),
    ]
    stacked = np.vstack(images)
    # cv.imshow("stacked", stacked)
    # cv.waitKey(0)
    # cv.destroyAllWindows()

# %%

# Static label-to-color mapping (BGR format for OpenCV)
label_colors = {
    0: (0, 128, 128),  # teal
    1: (0, 255, 0),  # green
    2: (255, 0, 0),  # blue
    3: (0, 0, 255),  # red
    4: (255, 255, 0),  # cyan
    5: (255, 0, 255),  # magenta
    6: (0, 255, 255),  # yellow
    7: (128, 0, 128),  # purple
    8: (255, 165, 0),  # orange
    9: (128, 128, 0),  # olive
}

def visualize_labeled_regions(labels):
    h, w = labels.shape
    output = np.zeros((h, w, 3), dtype=np.uint8)

    for label, color in label_colors.items():
        output[labels % 10 == label] = color

    return output

# *** DIRECT ( THIS IS REALLY GOOD IN MY TESTING!!!) ...
#   it does detect the playhead and the white dashed vertical line from recording mark, but I could skip over those with a n algorithm of some sort to connect sections with tiny tiny gaps (<4 pixels wide) assuming both sides are silence
timeline_bg_box_mask = color_mask(image, colors_bgr.timeline_bg, tolerance + 2)  # slightly looser for AA edges
timeline_bg_box_mask_smooth = cv.morphologyEx(timeline_bg_box_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))  # smooth out, skip freckled matches

if DEBUG:
    # make a divider like the background color #2C313C
    black_divider = np.zeros_like(image)
    black_divider[:] = [60, 49, 44]  # BGR for #2C313C

    # take half height divider:
    black_divider = black_divider[:image.shape[0] // 2, :image.shape[1]]  # first half of image
    print(images)
    images.append(black_divider)
    images.append(mask_only(image, timeline_bg_box_mask))
    images.append(mask_only(image, timeline_bg_box_mask_smooth))
    stacked = np.vstack(images)
    # cv.imshow("stacked", stacked)
    # cv.waitKey(0)
    # cv.destroyAllWindows()

num_labels, labels, stats, _ = cv.connectedComponentsWithStats(timeline_bg_box_mask_smooth, connectivity=8)
if DEBUG:
    pass
    labeled_mask = visualize_labeled_regions(labels)
    images.append(labeled_mask)
    cv.imshow("labeled_mask", np.vstack(images))
    cv.waitKey(0)
    cv.destroyAllWindows()

exit()

# *** scale down to 1080p for returning to hs

# first four stats are: left, top, width, height
# fifth is area
# to get to 1080p I need to divide first four by 2
# then the fifth is area so I need to divide that by 4
# assume 1080p scaling is 2x (because 1920x1080 -> 960x540)
stats_1080p = stats.copy()
stats_1080p[:, :4] //= 2
stats_1080p[:, 4] //= 4
if DEBUG:
    print("4k stats:")
    print(stats)
    print("1080p stats:")
    print(stats_1080p)

# ** lets join consecutive boxes that are 1 pixel apart x2_start = x1_end + 1
x_regions = stats_1080p[1:, [0, 2]]
if DEBUG:
    print(f'{x_regions=}')

# ensure sorted by x_started
sorted_indicies = np.argsort(x_regions[:, 0])
x_sorted_regions = x_regions[sorted_indicies]

if DEBUG:
    print(f'{x_sorted_regions=}')
# PRN throw if any regions overlap...
# AND throw if they aren't basically the full height of the image?
#   or filter these out?
#   see what happens with real usage and then add if I encounter issues

def merge_if_one_pixel_apart(accum, current):
    # print(f'{accum=}   {current=}')
    accum = accum or []
    current = current.copy()
    if len(accum) == 0:
        accum.append(current)
        return accum
    last = accum[-1]
    last_x_start = last[0]
    last_width = last[1]
    last_x_end = last_x_start + last_width
    current_x_start = current[0]
    if current_x_start == last_x_end + 1:
        current_width = current[1]
        last[1] += 1 + current_width
    else:
        accum.append(current)
    return accum

final_x_regions = reduce(merge_if_one_pixel_apart, x_sorted_regions, [])
# print(f'{final_x_regions=}')

# * final preview mask
if DEBUG:
    final_preview_mask = np.zeros_like(image)
    for x_start, width in final_x_regions:
        x_end = x_start + width
        final_preview_mask[:, x_start * 2:x_end * 2] = 255
    stack = np.vstack([image, final_preview_mask])
    cv.imshow("final_preview_mask", stack)
    cv.waitKey(0)
    cv.destroyAllWindows()

# * serialize response to json in STDOUT
ranges = [{
    "x_start": int(x_start),
    "x_end": int(x_start + width),
} for x_start, width in final_x_regions]
print(json.dumps(ranges))  # output to STDOUT for hs to consume
