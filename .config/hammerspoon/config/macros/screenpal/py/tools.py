import json
import os
import sys
import cv2 as cv
import numpy as np
from pathlib import Path
from functools import reduce
from shared import *
from visualize import *
from dataclasses import dataclass
from typing import Optional, Any

DEBUG = __name__ == "__main__"

@dataclass
class ToolResult:
    type: str
    x_start: int
    x_end: int

    def to_dict(self) -> dict[str, Any]:
        return {'type': self.type, 'x_start': self.x_start, 'x_end': self.x_end}

def detect_tools(use_file):
    shared_context = get_shared_context(use_file)
    image = shared_context.image
    timeline_mask = shared_context.timeline_mask
    playhead_mask = shared_context.playhead_mask

    # * pink masks
    pink_top_edge_row8 = np.array([198, 74, 218])  # BGR pink top shiny part (row 8, index 7th)
    pink_mask_top_edge = color_mask(image, pink_top_edge_row8, 4)
    #
    pink_corners = np.array([220, 79, 247])  # upper left and right corner each has two pixels ... off by one in B value (219 vs 220)
    pink_mask_corners = color_mask(image, pink_corners, 4)
    #
    pink_cursor_on_edge = np.array([226, 81, 255])
    pink_mask_cursor_on_edge = color_mask(image, pink_cursor_on_edge, 1)  # can be tight b/c its one color in my sampling
    # scan_mask(pink_mask_cursor_on_edge)
    #
    show_pink_as = pink_cursor_on_edge
    #
    pink_mask = np.logical_or(
        # only two at a time it seems?
        pink_mask_cursor_on_edge,
        pink_mask_corners,
    )
    # TODO look into how many can pass at a time and which operation should you be using?
    pink_mask = np.logical_or(
        pink_mask,
        pink_mask_top_edge,
    )

    # combine both
    # pink_mask = pink_mask_cursor_on_edge

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
        row8 = np.logical_or(row8_pink, row8_red)  # only two at a time?

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
            display_mask_only(image, timeline_mask),
            image,
            # easier to line up since this matches on top (so put below the image to compare)
            display_mask_only(image, pink_mask, show_pink_as),
            display_mask_only(image, pink_mask_top_edge, show_pink_as),
            display_mask_only(image, pink_mask_corners, show_pink_as),
            display_mask_only(image, pink_mask_cursor_on_edge, show_pink_as),
            #
            # display_mask_only(image, red_mask, red),
        )

    # * serialize response to json in STDOUT

    if min_index is None or max_index is None:
        return None

    return ToolResult(
        type="volume_add_tool",
        x_start=int(min_index / 2),
        x_end=int(max_index / 2),
    )

if DEBUG:
    # time python3 tools.py samples/pink-volume-add-open.png --debug
    from rich import print
    detected = detect_tools(file_arg)

    print(json.dumps(detected.to_dict() if detected else None))
