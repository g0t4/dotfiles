import os
import sys
from typing import NamedTuple
import cv2 as cv
import numpy as np
from pathlib import Path

# TODO make into arg
file = Path(os.getenv("WES_DOTFILES") or "") \
    / ".config/hammerspoon/config/macros/screenpal/py/timeline03a.png"

image = cv.imread(str(file), cv.IMREAD_COLOR)  # BGR
if image is None:
    raise ValueError(f"Could not load image from {file}")

class TimelineColorsBGR(NamedTuple):
    timeline_bg: np.ndarray
    silence_gray: np.ndarray

# FYI use colors.py to deterine colors to use and then inline values here:

colors_bgr = TimelineColorsBGR(
    # opencv values!
    # timeline_bg_opencv=array([41, 19, 16])
    # silence_gray_opencv=array([57, 37, 34])
    timeline_bg=np.array([41, 19, 16]),
    silence_gray=np.array([57, 37, 34]))

# Tiny tolerance may handle edge pixels
tolerance = 4

def color_mask(img, color, tol):
    diff = np.abs(img.astype(np.int16) - color.astype(np.int16))
    return (diff <= tol).all(axis=2).astype(np.uint8) * 255

gray_box_direct_mask = color_mask(image, colors_bgr.silence_gray, tolerance)  # skip ROI b/c the image is ONLY the timeline so there's no reason to spot the timeline!
timeline_mask = color_mask(image, colors_bgr.timeline_bg, tolerance)

def blend_highlights_on_mask(image, mask) -> None:

    highlight_overlay = np.zeros_like(image)
    # overlay[mask > 0] = [255, 255, 255]  # White overlay
    highlight_overlay[mask > 0] = [0, 0, 255]  # red overlay

    # Blend image with overlay
    blended = cv.addWeighted(image, 0.7, highlight_overlay, 0.3, 0)
    return blended

gray_box_direct_highlighted = blend_highlights_on_mask(image, gray_box_direct_mask)
timeline_highlighted = blend_highlights_on_mask(image, timeline_mask)
stacked = np.vstack([timeline_highlighted, gray_box_direct_highlighted])  # type: ignore
cv.imshow("stacked", stacked)
cv.waitKey(0)
cv.destroyAllWindows()

# %%

num_labels, labels, stats, _ = cv.connectedComponentsWithStats(timeline_mask, connectivity=8)
print(f'{num_labels=}')
print(f'{labels=}')
print(f'{stats=}')

# Static label-to-color mapping (BGR format for OpenCV)
label_colors = {
    0: (0, 0, 0),  # background (black)
    1: (255, 0, 0),  # blue
    2: (0, 255, 0),  # green
    3: (0, 0, 255),  # red
    4: (255, 255, 0),  # cyan
    5: (255, 0, 255),  # magenta
    6: (0, 255, 255),  # yellow
    7: (128, 0, 128),  # purple
    8: (255, 165, 0),  # orange
    9: (128, 128, 0),  # olive
    10: (0, 128, 128),  # teal
}

def visualize_labeled_regions(labels):
    h, w = labels.shape
    output = np.zeros((h, w, 3), dtype=np.uint8)

    # make sure none over 10
    if np.any(labels > len(label_colors) - 1):
        raise ValueError("Labels exceed 10, can only color up to 10 unless you expand list of label_colors")  # or handle appropriately for your use case

    for label, color in label_colors.items():
        output[labels == label] = color

    return output

# static_labels = visualize_labeled_regions(labels)
# cv.imshow("static_labels", static_labels)
# cv.waitKey(0)
# cv.destroyAllWindows()

# %%

largest_label = 1 + np.argmax(stats[1:, cv.CC_STAT_AREA])
tx, ty, tw, th, _ = stats[largest_label]
print(f"tx={tx}, ty={ty}, tw={tw}, th={th}")
timeline_roi = image[ty:ty + th, tx:tx + tw]
stacked = np.vstack([timeline_roi])  # type: ignore

# %%

# cv.imshow("stacked", stacked)
# cv.waitKey(0)
# cv.destroyAllWindows()

# ROI
# gray_box_mask = color_mask(timeline_roi, colors_bgr.silence_gray, tolerance + 2)  # slightly looser for AA edges
# gray_box_mask_smooth = cv.morphologyEx(gray_box_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8)) # smooth out, skip freckled matches

# *** DIRECT ( THIS IS REALLY GOOD IN MY TESTING!!!) ...
#   it does detect the playhead and the white dashed vertical line from recording mark, but I could skip over those with a n algorithm of some sort to connect sections with tiny tiny gaps (<4 pixels wide) assuming both sides are silence
gray_box_mask = color_mask(image, colors_bgr.silence_gray, tolerance + 2)  # slightly looser for AA edges
gray_box_mask_smooth = cv.morphologyEx(gray_box_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))  # smooth out, skip freckled matches

stacked = np.vstack([gray_box_mask, gray_box_mask_smooth])  # type: ignore
cv.imshow("stacked", stacked)

num_labels, labels, stats, _ = cv.connectedComponentsWithStats(gray_box_mask_smooth, connectivity=8)
labeled_mask = visualize_labeled_regions(labels)
cv.imshow("labeled_mask", labeled_mask)
cv.waitKey(0)
cv.destroyAllWindows()

box_label = 1 + np.argmax(stats[1:, cv.CC_STAT_AREA])
bx, by, bw, bh, _ = stats[box_label]

# Position of box center as fraction of the full timeline width
center_fraction = (bx + bw / 2.0) / float(tw)
print(f"center_fraction={center_fraction:.4f}")  # e.g., 0.3721
