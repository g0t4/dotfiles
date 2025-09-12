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

def detect_short_silences(use_file):

    shared = get_shared_context(use_file)
    image = shared.image
    timeline_mask = shared.timeline_mask
    playhead_mask = shared.playhead_mask

    hunt_mask = cv.bitwise_or(timeline_mask, playhead_mask)
    hunt_mask_CLOSED = cv.morphologyEx(hunt_mask, cv.MORPH_CLOSE, np.ones((3, 3), np.uint8))

    def find_ranges(mask: np.ndarray):
        # mask = mask[:, 1400:1490]  # uncomment to test a subset
        mask_roi = mask[48:, :]  # take 48+ (bottom 50% of mask) for Insert New to match too

        assert np.all((mask_roi == 0) | (mask_roi == 255)), "FAILURE - Mask contains values other than 0 or 255"

        mask_roi = mask_roi / 255  # scale to 0/1

        col_sums = mask_roi.sum(0)
        # print_mask_evenly("col_sums", col_sums)

        # 1 == timeline background
        # when all columns have the timeline background == silence period
        short_silences = col_sums == (mask_roi.shape[0])
        # print_mask_evenly("short_silences", short_silences)

        # pad 1 extra column to start/end (num_start, num_end)
        #   uses value from start/end column
        #   [ X x...y Y ]
        #      where x...y is the original array
        #   purpose: shift columns right by one for the column diff (next)
        #   trailing padding is irrelevant (will always come out 0, and be dropped by the flatnonzero stage)
        padded = np.pad(short_silences.astype(np.int8), (1, 1))
        # print_mask_evenly("padded", padded)

        column_diff = np.diff(padded, 1, -1)  # diff[n] = padded[n+1] - padded[n]
        # print_mask_evenly("column_diff", column_diff)

        # THUS 1 => start of silence range (0 => 1 == 1 - 0 == 1)
        #     -1 => end of silence range! (1 => 0 == 0 - 1 == -1)
        change_indices = np.flatnonzero(column_diff)
        # print_mask_evenly("change_indices", change_indices)

        # pair-wise grouping of (start,end) short silence ranges
        ranges = [
            (change_indices[i], change_indices[i + 1] - 1)  \
            for i in range(0, len(change_indices), 2)]

        # print_mask_evenly("ranges", ranges)

        return ranges

    ranges = find_ranges(hunt_mask_CLOSED)

    if DEBUG:
        range_preview_mask = build_range_mask(ranges, image)

        show_and_wait(
            display_mask_only(image, timeline_mask),
            image,
            range_preview_mask,
        )

    # * serialize response to json in STDOUT
    detected = {
        "short_silences": [
            {
                # divide by 2 for non-retina resolution
                "x_start": int(x_start / 2),
                "x_end": int(x_end / 2),
            } for x_start, x_end in ranges \
               if x_start < x_end
        ],
    }

    return detected

if DEBUG:
    # time python3 short_silences.py samples/playhead-darkblue1.png --debug
    from rich import print
    detected = detect_short_silences(file_arg)

    print(json.dumps(detected))
