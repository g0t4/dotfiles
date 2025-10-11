import json
import os
import sys
import cv2 as cv
import numpy as np
from pathlib import Path
from functools import reduce
from shared import *
from visualize import *

DEBUG = __name__ == "__main__"

def detect_regular_silences(use_file):

    shared = get_shared_context(use_file)
    image = shared.image

    gray_box_mask = color_mask(image, colors_bgr.silence_gray, tolerance=6)  # slightly looser for AA edges
    #   it does detect the playhead and the white dashed vertical line from recording mark, but I could skip over those with a n algorithm of some sort to connect sections with tiny tiny gaps (<4 pixels wide) assuming both sides are silence
    gray_box_mask_smooth = cv.morphologyEx(gray_box_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))  # smooth out, skip freckled matches
    num_labels, labels, stats, _ = cv.connectedComponentsWithStats(gray_box_mask_smooth, connectivity=8)

    # * project to ranges
    # columns: left, top, width, height, area
    #   only take left (0) and width (2) columns
    #   skip first stat row (0) b/c it is the background (not a range)
    #     1: means take row 1+ (skip row 0)
    x_start_col = stats[1:, [0]]
    x_width_col = stats[1:, [2]]
    x_ranges = np.column_stack((
        x_start_col,  # x_start
        x_start_col + x_width_col,  # x_end
    ))

    def sort_ranges_by_x_start(ranges: np.ndarray) -> np.ndarray:
        """ assumed that each row starts with x_start """
        x_start_column = ranges[:, 0]
        sorted_row_indicies = np.argsort(x_start_column)
        return ranges[sorted_row_indicies]

    x_sorted_ranges = sort_ranges_by_x_start(x_ranges)

    def merge_if_one_pixel_apart(accum, current):
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

    # # * look back at falling edge of waveform
    # for x_start, x_end in merged_x_ranges:
    #     x_lookback_start = np.max(x_start - 30, 0)
    #     print(f'{x_start=} {x_end=} {x_lookback_start=}')
    #     lookback = shared.image[:, x_lookback_start:x_start]
    #     print(f'{lookback=}')
    #     # show_and_wait(lookback)

    # * serialize response to json in STDOUT
    detected = {
        "regular_silences": [
            {
                "x_start": int(x_start / 2),  # int() is serializable
                "x_end": int(x_end / 2),
            } for x_start, x_end in merged_x_ranges
        ]
    }

    if DEBUG:
        divider = shared.divider()

        labeled_mask = display_colorful_labeled_regions(labels)

        show_and_wait(
            # image, # include image but not really necessary
            display_mask_only(image, shared.waveform_mask),
            divider,
            display_mask_over_image(image, gray_box_mask),
            display_mask_only(image, gray_box_mask),
            display_mask_over_image(image, shared.timeline_mask),
            display_mask_only(image, shared.timeline_mask),
            display_mask_over_image(image, shared.playhead_mask, alpha=0.5, highlight_color=YELLOW),
            display_mask_only(image, shared.playhead_mask, highlight_color=YELLOW),
            divider,
            display_mask_only(image, gray_box_mask),
            display_mask_only(image, gray_box_mask_smooth),
            divider,
            labeled_mask,
        )

        # * final preview mask
        show_and_wait(image, build_range_mask(merged_x_ranges, image))

    return detected

if DEBUG:
    # z screenpal/py
    # time python3 regular_silences.py samples/timeline03a.png --debug
    from rich import print
    detected = detect_regular_silences(file_arg)

    print(json.dumps(detected))
