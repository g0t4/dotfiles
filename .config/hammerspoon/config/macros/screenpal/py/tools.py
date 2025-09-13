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
    combined_pink_mask = np.logical_or(
        # only two at a time it seems?
        pink_mask_cursor_on_edge,
        pink_mask_corners,
    )
    # TODO look into how many can pass at a time and which operation should you be using?
    combined_pink_mask = np.logical_or(
        combined_pink_mask,
        pink_mask_top_edge,
    )

    # combine both
    # pink_mask = pink_mask_cursor_on_edge

    red_top_edge_row8 = np.array([9, 6, 145])
    red_mask_top_edge = color_mask(image, red_top_edge_row8, 4)
    #
    red_corners = np.array([1, 0, 162])
    red_mask_corners = color_mask(image, red_corners, 4)
    #
    red_cursor_on_edge = np.array([0, 32, 255])
    red_mask_cursor_on_edge = color_mask(image, red_cursor_on_edge, 1)
    #
    show_red_as = red_cursor_on_edge
    #
    combined_red_mask = np.logical_or(
        # FYI probably can do the range fully w just these two masks cuz they cover corners/ends
        red_mask_cursor_on_edge,
        red_mask_corners,
    )
    combined_red_mask = np.logical_or(
        combined_red_mask,
        red_mask_top_edge,
    )

    # FTR I am using the "O" other end tool I made and it works perfect at zoom2 w/ shape overlays so I don't need to do anything special then with the middle of the blue ball (not yet)
    blue_ball_color = np.array([255, 176, 105])  # BGR
    combined_blue_mask = color_mask(image, blue_ball_color, 4)

    # freeze frame tool
    green_top_edge_row8 = np.array([103, 101, 35])  # BGR
    green_mask_top_edge = color_mask(image, green_top_edge_row8, 4)
    #
    green_corners = np.array([113, 114, 37])  # BGR
    green_mask_corners = color_mask(image, green_corners, 4)
    #
    green_blue_cursor_on_edge = np.array([227, 134, 0])  # BGR
    green_mask_cursor_on_edge = color_mask(image, green_blue_cursor_on_edge, 1)
    #
    show_green_as = green_blue_cursor_on_edge
    #
    combined_green_mask = np.logical_or(
        green_mask_cursor_on_edge,
        green_mask_corners,
    )
    combined_green_mask = np.logical_or(
        combined_green_mask,
        green_mask_top_edge,
    )

    def detect_volume_add_tool(image):
        # color in row 8 works, however playhead interferes if overlapping:
        #  1. union playhead mask (but would find bogus range of just playhead, would need to remove)
        #     OR allow if playhead overlaps and is the only missing pixels in range
        #  2. take min/max column == range
        #     this worked in initial test case, lets see how well it does in reality

        # search for either row color
        row8_pink = combined_pink_mask[5]
        row8_red = combined_red_mask[5]
        row8_blue = combined_blue_mask[5]
        row8_green = combined_green_mask[5]

        row8 = np.logical_or(row8_pink, row8_red)  # only two at a time?
        row8 = np.logical_or(row8, row8_blue)  # only two at a time IIUC
        row8 = np.logical_or(row8, row8_green)  # add green to the mix

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
            #
            display_mask_only(image, combined_green_mask, show_green_as),
            #
            display_mask_only(image, combined_blue_mask, blue_ball_color),
            #
            # easier to line up since this matches on top (so put below the image to compare)
            display_mask_only(image, combined_pink_mask, show_pink_as),
            # display_mask_only(image, pink_mask_top_edge, show_pink_as),
            # display_mask_only(image, pink_mask_corners, show_pink_as),
            # display_mask_only(image, pink_mask_cursor_on_edge, show_pink_as),
            #
            display_mask_only(image, combined_red_mask, show_red_as),
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
