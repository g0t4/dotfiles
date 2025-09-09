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
# time python3 dark-boxes.py samples/playhead-darkblue1.png # regular output (non-debug)
# time python3 dark-boxes.py samples/playhead-darkblue1.png --debug

# Tiny tolerance may handle edge pixels
tolerance = 4

image = load_image()

timeline_mask = color_mask(image, colors_bgr.timeline_bg, tolerance)  # leave so you can come back to this later for additional detection (i.e. unmarked silences, < 1 second)
playhead_mask = color_mask(image, colors_bgr.playhead, tolerance)

def find_playhead_x(mask: np.ndarray) -> int | None:
    # returns LEFTMOST edge of playhead, PRN could find centermost column
    # mask is 2D, nonzero (255) means "on"
    col_has_all = (mask != 0).all(axis=0)  # boolean per column
    cols = np.where(col_has_all)[0]
    return int(cols[0]) if cols.size > 0 else None

playhead_leftmost_index = find_playhead_x(playhead_mask)

hunt_mask = cv.bitwise_or(timeline_mask, playhead_mask)
hunt_mask_CLOSED = cv.morphologyEx(hunt_mask, cv.MORPH_CLOSE, np.ones((3, 3), np.uint8))

look_start = 0
look_end = -1

def scan_for_all_short_silences(mask: np.ndarray):
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
    runs = [(edges[i], edges[i + 1] - 1) for i in range(0, len(edges), 2)]
    # print("## runs:")
    # for r in runs:
    #     print(r)

    return runs

runs = []
if playhead_leftmost_index is not None:
    runs = scan_for_all_short_silences(hunt_mask_CLOSED)

if DEBUG:
    built = build_range_mask(runs, image)

    full = [
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
    # PRN find playhead_center_index if this needs to be accurate
    # PRN for now I may use this in lua to compare captured vs actual as canary
    "playhead_x": playhead_leftmost_index,
    "short_silences": [
        {
            # FYI for now off by one won't matter much but I should resolve this
            # TODO! MAKE SURE you are using end inclusivity correctly
            # TODO!  IOTW figure out which you are using and rename your DTO here
            # divide by 2 for non-retina resolution
            "x_start": int(x_start / 2),
            "x_end": int(x_end / 2),
        } for x_start, x_end in runs \
           if x_start < x_end # skip 0 width silences (TODO find a unit test case)
    ]
}
print(json.dumps(results))  # output to STDOUT for hs to consume

# PRN hardcode results for test case
if DEBUG and file == "samples/playhead-darkblue1.png":
    # time python3 dark-boxes.py samples/playhead-darkblue1.png --debug
    # PRN use unit test assertions so we can see what differs
    # TODO verify these are correct values (I just captured these off of the last test run I did by inspecting the image overlays)
    expected = {"playhead_x": 1452, "short_silences": [{"x_start": 4, "x_end": 5}, {"x_start": 31, "x_end": 32}, {"x_start": 217, "x_end": 218}, {"x_start": 319, "x_end": 320}, {"x_start": 376, "x_end": 378}, {"x_start": 403,
    "x_end": 404}, {"x_start": 703, "x_end": 743}, {"x_start": 1024, "x_end": 1025}, {"x_start": 1228, "x_end": 1229}, {"x_start": 1423, "x_end": 1464}, {"x_start": 1561, "x_end": 1562}, {"x_start": 1741, "x_end":
    1744}]} # yapf: disable
    # TODO verify that the x_end is what I want... zoom in on a few
    # TODO also verify start is lined up by zooming in and checking a few
    assert results["playhead_x"] == expected["playhead_x"]
    assert results["short_silences"] == expected["short_silences"]
    print("\n[bold underline green]MATCHED SHORT SILENCE TEST CASE!")
