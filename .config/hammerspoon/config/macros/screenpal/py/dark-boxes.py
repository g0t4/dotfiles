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

# take off top and bottom borders
image = image[2:-2]
print("removed top/botom borders:", image.shape)

# * take the bottom of the timeline
# that way audio waveform is most likely to partition dark blue silence periods entirely
# should make it easier to spot them with timeline bg alone
#
# 96 pixels high
#
# image = image[48:] # bottom half
# image = image[64:]  # bottom third 2/3*96=64
# image = image[72:] # bottom third 3/4*96=72
# print(image.shape)

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

def first_full_column(mask: np.ndarray) -> int | None:
    # mask is 2D, nonzero means "on"
    col_has_all = (mask != 0).all(axis=0)  # boolean per column
    cols = np.where(col_has_all)[0]
    return int(cols[0]) if cols.size > 0 else None

idx = first_full_column(playhead_mask)
print(f'playhead {idx=}')

hunt_mask = cv.bitwise_or(timeline_mask, playhead_mask)
hunt_mask_CLOSED = cv.morphologyEx(hunt_mask, cv.MORPH_CLOSE, np.ones((3, 3), np.uint8))
hunt_mask_DILATE_ONLY = cv.morphologyEx(hunt_mask, cv.MORPH_DILATE, np.ones((3, 3), np.uint8))

look_start = 0
look_end = -1

def full_column_span(mask: np.ndarray, start_idx: int, max_gap: int = 0) -> tuple[int, int]:
    """
    Expand left/right from start_idx to include adjacent columns where all values are non-zero.
    If max_gap>0, allow up to `max_gap` consecutive zero-columns while expanding.
    """
    mask = mask[look_start:look_end]  # subset that should have full, dark blue columns
    cv.imshow("mask", np.vstack([mask]))

    full = (mask != 0).all(axis=0)
    w = full.size
    if not full[start_idx]:
        raise ValueError("start_idx is not an all-nonzero column")

    left = start_idx
    gap = 0
    i = start_idx - 1
    while i >= 0 and gap <= max_gap:
        if full[i]:
            left = i
            gap = 0
        else:
            gap += 1
        i -= 1

    right = start_idx
    gap = 0
    i = start_idx + 1
    while i < w and gap <= max_gap:
        if full[i]:
            right = i
            gap = 0
        else:
            gap += 1
        i += 1

    return left, right

def scan_for_all_short_silences(mask: np.ndarray):
    # verify assumption (just to be safe)
    # FYI ends have curved edges, wait until this is an issue... could make mask around curved corners and then pad with neighboring pixels or smth else and add if they are empty nearby or not
    assert np.all((mask == 0) | (mask == 255)), "FAILURE - Mask contains values other than 0 or 255"
    # mask = mask[:, 1400:1490]  # TODO remove/comment out, test on subset of columns near playhead that I know well
    mask = mask / 255  # scale to 0/1
    print(f"{mask=}")
    col_sums = mask.sum(0)
    print(f"{col_sums=}")
    short_silences = col_sums == (mask.shape[0])
    print(f"{short_silences=}")
    # pad 1 column extra to start/end (num_start, num_end)
    #   uses value from start/end column (false/0 in my case so I get extra 0 on each end in padded)
    #   useful for diff to scan left to right for consecutive silence columns including through the start/end columns
    padded = np.pad(short_silences.astype(np.int8), (1, 1))
    print(f"{padded=}")
    diff = np.diff(padded, 1, -1)  # diff[n] = padded[n+1] - padded[n]
    print(f"{diff=}")
    # THUS 1 => start of silence range, -1 => end of silence range!
    edges = np.flatnonzero(diff)
    print(f'{edges=}')
    # PRN why the !=0 in the ChatGPT example
    # print(f'{np.flatnonzero(np.diff(padded)!=0)=}')
    # print(f'{np.flatnonzero(diff != 0)=}')
    runs = [(edges[i], edges[i + 1] - 1) for i in range(0, len(edges), 2)]
    print("## runs:")
    for r in runs:
        print(r)

    return runs

runs = []
if idx is not None:
    runs = scan_for_all_short_silences(hunt_mask_CLOSED)

# FYI disabled this section so I can scan full timeline for all of these short silences (dark blue bg), not just around playhead
if idx is not None and False:
    # actual hunting w/ best mask:
    L, R = full_column_span(hunt_mask_CLOSED, idx, max_gap=0)  # set >0 to tolerate small holes
    print(f'{L=} {R=}')

    # # tmp fix the range so I can find the right hunting mask (get rid of triangle edges on playhead)
    # # uncomment this to fix range for reviewing regardless what matches above
    # # then comment this out to look at matched range
    # L = 1405
    # R = 1493

    # my inspection estimates:
    # L (base1) = 1407 (literally first column of dark blue pixels)
    #      column 1406 is the last part of the waveform (albeit the blurry edge of lowest part of visible waveform)
    # R (base1) = 1488 (last column of dark blue pixels)
    # results:
    #   CLOSED: L(base0)=1406, R(base0)=1487

    if DEBUG:
        band = image[look_start:look_end, L:R + 1]
        hunt_mask_matched = hunt_mask[look_start:look_end, L:R + 1]
        hunt_mask_CLOSED_matched = hunt_mask_CLOSED[look_start:look_end, L:R + 1]
        hunt_mask_DILATE_ONLY_matched = hunt_mask_DILATE_ONLY[look_start:look_end, L:R + 1]
        print(f'{band.shape=}')
        print(f'{hunt_mask_matched.shape=}')
        print(f'{hunt_mask_matched[:,:,None].shape=}')
        print(f'{hunt_mask_matched[:,:,None]=}')
        hunt_mask_matched_color = np.repeat(hunt_mask_matched[:, :, None], 3, 2)
        hmmc2 = np.stack([hunt_mask_matched[:, :, None]] * 3, 2)
        hmmc3 = np.tile(hunt_mask_matched[:, :, None], 3)
        print(f'{hmmc2=}')
        print(f'{hmmc3=}')
        print(f'{np.array_equal(hmmc2, hunt_mask_matched_color)=}')
        print(f'{np.array_equal(hmmc3, hunt_mask_matched_color)=}')
        print(f'{hunt_mask_matched_color=}')
        hmCLOSED_matched_color = np.repeat(hunt_mask_CLOSED_matched[:, :, None], 3, 2)  # None adds new dimension, then repeat 2nd axis (innermost) 3 times => single 8bit => RGB 8:8:8 value
        hmDILATE_ONLY_matched_color = np.repeat(hunt_mask_DILATE_ONLY_matched[:, :, None], 3, 2)  # None adds new dimension, then repeat 2nd axis (innermost) 3 times => single 8bit => RGB 8:8:8 value
        separator = np.full([5, band.shape[1], 3], [60, 49, 44], np.uint8)
        cv.imshow("hunt_mask", np.vstack([
            hunt_mask_matched_color,
            separator,
            hmCLOSED_matched_color,
            separator,
            hmDILATE_ONLY_matched_color,
            separator,
            band,
        ]))

        # zoom_factor = 4
        # zoomed = cv.resize(hunt_mask_matched_color, None, fx=zoom_factor, fy=zoom_factor, interpolation=cv.INTER_LINEAR)
        # cv.imshow("hunt_mask_zoomed", zoomed)

        cv.waitKey(0)

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
    final_mask = np.zeros_like(image)
    print(f'{final_mask=}')
    for r in runs:
        start = r[0]
        end = r[1]
        final_mask[:, start:end + 1] = RED
    print(f'{final_mask[0,0:20]=}')

    images = [
        image,
        final_mask,
    ]
    stacked = np.vstack(images)
    cv.imshow("stacked", stacked)
    cv.waitKey(0)
    cv.destroyAllWindows()

# * serialize response to json in STDOUT
ranges = [{
    "x_start": int(x_start),
    "x_end": int(x_start + width),
} for x_start, width in final_x_regions]
print(json.dumps(ranges))  # output to STDOUT for hs to consume
