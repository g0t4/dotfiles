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

def get_short_silences():

    hunt_mask = cv.bitwise_or(timeline_mask, playhead_mask)
    hunt_mask_CLOSED = cv.morphologyEx(hunt_mask, cv.MORPH_CLOSE, np.ones((3, 3), np.uint8))

    look_start = 0
    look_end = -1

    def detect_short_silences(mask: np.ndarray):
        mask = mask[48:, :]  # take 48+ (bottom 50% of mask) for Insert New to match too
        # verify assumption (just to be safe)
        # FYI ends have curved edges, wait until this is an issue... could make mask around curved corners and then pad with neighboring pixels or smth else and add if they are empty nearby or not
        assert np.all((mask == 0) | (mask == 255)), "FAILURE - Mask contains values other than 0 or 255"
        # mask = mask[:, 1400:1490]  # TODO remove/comment out, test on subset of columns near playhead that I know well
        mask = mask / 255  # scale to 0/1
        # print(f"{mask=}")
        col_sums = mask.sum(0)
        # print(f"{col_sums=}")
        short_silences = col_sums == (mask.shape[0])
        # print(f"{short_silences=}")
        # pad 1 column extra to start/end (num_start, num_end)
        #   uses value from start/end column (false/0 in my case so I get extra 0 on each end in padded)
        #   useful for diff to scan left to right for consecutive silence columns including through the start/end columns
        padded = np.pad(short_silences.astype(np.int8), (1, 1))
        # print(f"{padded=}")
        diff = np.diff(padded, 1, -1)  # diff[n] = padded[n+1] - padded[n]
        # print(f"{diff=}")
        # THUS 1 => start of silence range, -1 => end of silence range!
        edges = np.flatnonzero(diff)
        # print(f'{edges=}')
        # PRN why the !=0 in the ChatGPT example
        # print(f'{np.flatnonzero(np.diff(padded)!=0)=}')
        # print(f'{np.flatnonzero(diff != 0)=}')
        ranges = [(edges[i], edges[i + 1] - 1) for i in range(0, len(edges), 2)]
        return ranges

    ranges = detect_short_silences(hunt_mask_CLOSED)

    if DEBUG:
        built = build_range_mask(ranges, image)

        # color in row 8 works, however playhead interferes... need to union playhead mask
        #   OR allow playhead between to join sections more than 1 pixel?
        #   ALSO it is the triangle part of the playhead on top that intersects so not just 2 pixels
        #   OR, just know that you CANNOT ADD / EDIT two ranges at a time so this has to be one range!
        #   min(col) => max(col) ...  in row 8 or just overall?
        #   any constraint on how far apart?
        #   use morphology to avoid flecks interfering?
        #
        pink = np.array([198, 74, 218])  # BGR pink top shiny part (row 8, index 7th)
        pink_mask = color_mask(image, pink, 4)
        row8 = pink_mask[5]  # row 7 - 2 for border pixels removed when image loaded
        # 577 first 1-based => - 2 (border) - 1 (0-based) = 574
        print(f'{row8[578]=}')  # col # 578 had first pixel in mask
        print(f'{row8[577]=}')
        print(f'{row8[576]=}')
        print(f'{row8[575]=}')
        # 810 max estimate
        #  actual => 807 == col # 808!

        # Assuming row8 is your 1D numpy array with 3500 columns
        non_zero_indices = np.nonzero(row8)[0]
        if len(non_zero_indices) > 0:
            min_index = np.min(non_zero_indices)
            max_index = np.max(non_zero_indices)
            print(f'{min_index=}')
            print(f'{max_index=}')
        else:
            min_index = max_index = None

        scan_mask(pink_mask)

        full = [
            display_mask_only(image, pink_mask, pink),
            display_mask_only(image, timeline_mask),
            image,
            built,
        ]

        # around_playhead = [
        #     # can zoom in and compare edges
        #     image[:, 1300:1500],
        #     built[:, 1300:1500],
        # ]

        stacked = np.vstack(full)
        show_and_wait(stacked)

    # * serialize response to json in STDOUT
    results = {
        "short_silences": [
            {
                # divide by 2 for non-retina resolution
                "x_start": int(x_start / 2),
                "x_end": int(x_end / 2),
            } for x_start, x_end in ranges \
               if x_start < x_end
        ]
    }

    # PRN hardcode results for test case
    if DEBUG:
        print(json.dumps(results))
        if file == "samples/playhead-darkblue1.png":
            # PRN use unit test assertions so we can see what differs
            expected = {"short_silences": [{"x_start": 4, "x_end": 5}, {"x_start": 31, "x_end": 32}, {"x_start": 217, "x_end": 218}, {"x_start": 319, "x_end": 320}, {"x_start": 376, "x_end": 378}, {"x_start": 403,
            "x_end": 404}, {"x_start": 703, "x_end": 743}, {"x_start": 1024, "x_end": 1025}, {"x_start": 1228, "x_end": 1229}, {"x_start": 1423, "x_end": 1464}, {"x_start": 1561, "x_end": 1562}, {"x_start": 1741, "x_end":
            1744}]} # yapf: disable
            assert results["short_silences"] == expected["short_silences"]
            print("\n[bold underline green]MATCHED SHORT SILENCE TEST CASE!")

    return results

if DEBUG:
    # time python3 short_silences.py samples/playhead-darkblue1.png --debug
    from rich import print
    get_short_silences()
