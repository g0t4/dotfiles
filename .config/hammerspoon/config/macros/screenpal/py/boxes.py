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

timeline_mask = color_mask(image, colors_bgr.timeline_bg, tolerance)  # leave so you can come back to this later for additional detection (i.e. unmarked silences, < 1 second)
playhead_mask = color_mask(image, colors_bgr.playhead, tolerance)

gray_box_mask = color_mask(image, colors_bgr.silence_gray, tolerance + 2)  # slightly looser for AA edges
#   it does detect the playhead and the white dashed vertical line from recording mark, but I could skip over those with a n algorithm of some sort to connect sections with tiny tiny gaps (<4 pixels wide) assuming both sides are silence
gray_box_mask_smooth = cv.morphologyEx(gray_box_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))  # smooth out, skip freckled matches

if DEBUG:
    # make a divider like the background color #2C313C
    divider = np.zeros_like(image)
    divider = divider[:image.shape[0] // 2, :image.shape[1]]  # first half of image
    divider[:] = [60, 49, 44]  # BGR for #2C313C

    images = [
        # image, # include image but not really necessary
        display_mask_over_image(image, gray_box_mask),
        display_mask_only(image, gray_box_mask),
        display_mask_over_image(image, timeline_mask),
        display_mask_only(image, timeline_mask),
        display_mask_over_image(image, playhead_mask, alpha=0.5, highlight_color=YELLOW),
        display_mask_only(image, playhead_mask, highlight_color=YELLOW),
        divider,
        display_mask_only(image, gray_box_mask),
        display_mask_only(image, gray_box_mask_smooth),
    ]

    show_and_wait(*images)

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
x_ranges = stats_4k[1:, [0, 2]]

# * x_ranges[x_start, x_width] => x_ranges_with_end[x_start, x_end]
x_start_col = x_ranges[:, 0]
x_width_col = x_ranges[:, 1]
x_ranges_with_end = np.column_stack((
    x_start_col,
    x_start_col + x_width_col,
))
if DEBUG:
    print(f'{x_ranges=}')
    print(f'{x_ranges_with_end=}')

# * sort by x_start
#   no guarantee that ranges (stats) are sorted
def sort_ranges(ranges: np.ndarray) -> np.ndarray:
    """ assumed that each row (range) has [ x_start, ... ] """
    x_start_column = ranges[:, 0]
    sorted_row_indicies = np.argsort(x_start_column)
    return ranges[sorted_row_indicies]

x_sorted_ranges = sort_ranges(x_ranges_with_end)
if DEBUG:
    print(f'{x_sorted_ranges=}')

# PRN throw if any regions overlap?
# OR, throw if they aren't basically the full height of the image?
# see what happens with real usage and then add if I encounter issues

def merge_if_one_pixel_apart(accum, current):
    # TODO! I switched to 4k so make sure this still works!!
    # print(f'{accum=}   {current=}')
    accum = accum or []
    current = current.copy()
    if len(accum) == 0:
        accum.append(current)
        return accum
    last = accum[-1]
    last_start = last[0]
    last_end = last[1]
    current_start = current[0]
    # 4k => 2 pixels, 1080p => 1 pixel
    if current_start - last_end <= 2:
        current_end = current[1]
        last[1] = current_end
    else:
        accum.append(current)
    return accum

# ** join adjacent boxes that are 1 pixel apart x2_start = x1_end + 1
merged_x_ranges = reduce(merge_if_one_pixel_apart, x_sorted_ranges, [])

if DEBUG:
    # * final preview mask
    show_and_wait(image, build_range_mask(merged_x_ranges, image))

# * serialize response to json in STDOUT
results = {
    "silences": [
        {
            # FYI for now off by one won't matter much but I should resolve this
            # TODO! MAKE SURE you are using end inclusivity correctly
            # TODO!  IOTW figure out which you are using and rename your DTO here
            "x_start": int(x_start / 2),  # int() is serializable
            "x_end": int(x_end / 2),
        } for x_start, x_end in merged_x_ranges
    ]
}
print(json.dumps(results))  # output to STDOUT for hs to consume

if DEBUG and file == "samples/timeline03a.png":
    # time python3 boxes.py samples/timeline03a.png --debug
    # PRN use unit test assertions so we can see what differs
    expected = {"silences": [{"x_start": 754, "x_end": 891}, {"x_start": 1450, "x_end": 1653}]}
    assert results["silences"] == expected["silences"]
    print("\n[bold underline green]MATCHED REGULAR SILENCE TEST CASE!")
