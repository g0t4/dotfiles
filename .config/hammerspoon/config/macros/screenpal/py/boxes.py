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

timeline_mask = color_mask(image, colors_bgr.timeline_bg, tolerance)

def show_mask(mask) -> None:

    # Create a colored overlay for better visualization
    overlay = np.zeros_like(image)
    # overlay[mask > 0] = [255, 255, 255]  # White overlay
    overlay[mask > 0] = [0, 0, 255]  # red overlay

    # Blend original image with overlay
    result = cv.addWeighted(image, 0.7, overlay, 0.3, 0)

    # Display the result
    cv.imshow('Timeline Mask', result)

show_mask(timeline_mask)
cv.waitKey(0)
cv.destroyAllWindows()

# %%

num_labels, labels, stats, _ = cv.connectedComponentsWithStats(timeline_mask, connectivity=8)
largest_label = 1 + np.argmax(stats[1:, cv.CC_STAT_AREA])
tx, ty, tw, th, _ = stats[largest_label]
print(f"tx={tx}, ty={ty}, tw={tw}, th={th}")
timeline_roi = image[ty:ty + th, tx:tx + tw]

gray_box_mask = color_mask(timeline_roi, colors_bgr.silence_gray, tolerance + 2)  # slightly looser for AA edges
show_mask(gray_box_mask)

# Clean tiny speckles just in case
gray_box_mask = cv.morphologyEx(gray_box_mask, cv.MORPH_OPEN, np.ones((3, 3), np.uint8))
# show_mask(gray_box_mask)
# cv.waitKey(0)
# cv.destroyAllWindows()

num_labels, labels, stats, _ = cv.connectedComponentsWithStats(gray_box_mask, connectivity=8)
box_label = 1 + np.argmax(stats[1:, cv.CC_STAT_AREA])
bx, by, bw, bh, _ = stats[box_label]

# Position of box center as fraction of the full timeline width
center_fraction = (bx + bw / 2.0) / float(tw)
print(f"center_fraction={center_fraction:.4f}")  # e.g., 0.3721
