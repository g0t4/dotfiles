import json
import os
import sys
import cv2 as cv
import numpy as np
from pathlib import Path
from functools import reduce
from shared import *
from visualize import *

# z screenpal/py
# time python3 boxes.py samples/timeline03a.png --debug

# Tiny tolerance may handle edge pixels
tolerance = 4

image = load_image()

gray_box_direct_mask = color_mask(image, colors_bgr.silence_gray, tolerance)  # skip ROI b/c the image is ONLY the timeline so there's no reason to spot the timeline!
timeline_mask = color_mask(image, colors_bgr.timeline_bg, tolerance)  # leave so you can come back to this later for additional detection (i.e. unmarked silences, < 1 second)
playhead_mask = color_mask(image, colors_bgr.playhead, tolerance)
if DEBUG:
    images = [
        # image, # include image but not really necessary
        display_mask_over_image(image, gray_box_direct_mask),
        display_mask_only(image, gray_box_direct_mask),
        display_mask_over_image(image, timeline_mask),
        display_mask_only(image, timeline_mask),
        display_mask_over_image(image, playhead_mask, alpha=0.5, highlight_color=YELLOW),
        display_mask_only(image, playhead_mask, highlight_color=YELLOW),
    ]
    # stacked = np.vstack(images)
    # cv.imshow("stacked", stacked)
    # cv.waitKey(0)
    # cv.destroyAllWindows()

# %%
# *** DIRECT ( THIS IS REALLY GOOD IN MY TESTING!!!) ...
#   it does detect the playhead and the white dashed vertical line from recording mark, but I could skip over those with a n algorithm of some sort to connect sections with tiny tiny gaps (<4 pixels wide) assuming both sides are silence
gray_box_mask = color_mask(image, colors_bgr.silence_gray, tolerance + 2)  # slightly looser for AA edges
gray_box_mask_smooth = cv.morphologyEx(gray_box_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))  # smooth out, skip freckled matches

if DEBUG:
    # make a divider like the background color #2C313C
    black_divider = np.zeros_like(image)
    black_divider[:] = [60, 49, 44]  # BGR for #2C313C

    # take half height divider:
    black_divider = black_divider[:image.shape[0] // 2, :image.shape[1]]  # first half of image
    images = images or []
    images.append(black_divider)
    images.append(display_mask_only(image, gray_box_mask))
    images.append(display_mask_only(image, gray_box_mask_smooth))
    stacked = np.vstack(images)
    # cv.imshow("stacked", stacked)
    # cv.waitKey(0)
    # cv.destroyAllWindows()

num_labels, labels, stats_4k, _ = cv.connectedComponentsWithStats(gray_box_mask_smooth, connectivity=8)
if DEBUG:
    pass
    labeled_mask = display_colorful_labeled_regions(labels)

    # *** idea - add playhead to gray_box_mask
    gray_box_with_playhead_mask = cv.bitwise_or(gray_box_mask, playhead_mask)
    gray_box_with_playhead_mask_smooth = cv.morphologyEx(gray_box_with_playhead_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))  # smooth out, skip freckled matches
    num_labels, labels, stats_4k, _ = cv.connectedComponentsWithStats(gray_box_with_playhead_mask_smooth, connectivity=8)
    labeled_mask_with_playhead_merged = display_colorful_labeled_regions(labels)
    cv.imshow("labels", np.vstack([labeled_mask, labeled_mask_with_playhead_merged]))
    cv.waitKey(0)
    cv.destroyAllWindows()

# skip first stat (0) b/c it is the background (not a range)
# columns: left, top, width, height, area
#   only take left (0) and width (2) columns
x_ranges_1080p = stats_4k[1:, [0, 2]] / 2
# / 2 b/c stats is 4k resolution (of captured image) but I need 1080p for hammerspoon
if DEBUG:
    print(f'{x_ranges_1080p=}')

# * sort by x_start
#   no guarantee that ranges (stats) are sorted
def sort_ranges(x_ranges: np.ndarray) -> np.ndarray:
    x_start_column = x_ranges[:, 0]
    sorted_row_indicies = np.argsort(x_start_column)
    return x_ranges[sorted_row_indicies]

x_sorted_ranges = sort_ranges(x_ranges_1080p)

if DEBUG:
    print(f'{x_sorted_ranges=}')
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

# ** join nearly adjacent boxes that are 1 pixel apart x2_start = x1_end + 1
final_x_regions = reduce(merge_if_one_pixel_apart, x_sorted_ranges, [])
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
results = {
    "silences": [{
        "x_start": int(x_start),
        "x_end": int(x_start + width),
    } for x_start, width in final_x_regions]
}
print(json.dumps(results))  # output to STDOUT for hs to consume
