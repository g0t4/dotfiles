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

def detect_tools(image_path=None):

    detect_file = image_path or file_arg

    shared_context = get_shared_context(detect_file)
    image = shared_context.image
    timeline_mask = shared_context.timeline_mask
    playhead_mask = shared_context.playhead_mask

    pink = np.array([198, 74, 218])  # BGR pink top shiny part (row 8, index 7th)
    pink_mask = color_mask(image, pink, 4)
    # TODO revisit how well pink mask is matching ends (notably when cursor is at end/start/middle)
    # TODO also revist and test perf with white dash under the tool
    #   PRN add some automated tests of these scenarios with expected values matched!

    red = np.array([9, 6, 145])
    red_mask = color_mask(image, red, 4)

    def detect_volume_add_tool(image):
        # color in row 8 works, however playhead interferes if overlapping:
        #  1. union playhead mask (but would find bogus range of just playhead, would need to remove)
        #     OR allow if playhead overlaps and is the only missing pixels in range
        #  2. take min/max column == range
        #     this worked in initial test case, lets see how well it does in reality

        # search for either row color
        row8_pink = pink_mask[5]
        row8_red = red_mask[5]
        row8 = np.logical_or(row8_pink, row8_red)

        # FYI if needed, scan_mask(pink_mask)

        non_zero_indices = np.nonzero(row8)[0]
        min_index = None
        max_index = None
        if len(non_zero_indices) > 0:
            min_index = np.min(non_zero_indices)
            max_index = np.max(non_zero_indices)

        return min_index, max_index

    min_index, max_index = detect_volume_add_tool(image)

    if DEBUG:

        show_and_wait(
            display_mask_only(image, pink_mask, pink),
            display_mask_only(image, red_mask, red),
            display_mask_only(image, timeline_mask),
            image,
        )

    # * serialize response to json in STDOUT
    detected = {"tool": {}}

    if min_index is not None and max_index is not None:
        # TODO test if volume edit tool range works on pink too
        # TODO parameterize the search for other colors that I bet use row 8 too!
        detected["tool"] = {
            "type": "volume_add_tool",
            "x_start": int(min_index / 2),
            "x_end": int(max_index / 2),
        }

    # PRN hardcode results for test case
    if DEBUG:

        print(json.dumps(detected))

        if detect_file == "samples/pink-volume-add-open.png":
            expected_tool = {"type": "volume_add_tool", "x_start": 289, "x_end": 403}
            assert detected["tool"] == expected_tool
            print("\n[bold underline green]MATCHED TOOL TEST CASE!")

    return detected

if DEBUG:
    # time python3 tools.py samples/pink-volume-add-open.png --debug
    from rich import print
    detect_tools()
