import sys
from typing import NamedTuple
import cv2 as cv
import numpy as np
from pathlib import Path

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

WINDOW_BG_COLOR = (40, 40, 40)  # default background color which when used makes it appear transparent / unset

def show_and_wait(*images):
    cv.imshow("images", np.vstack(images))
    cv.moveWindow("images", 0, 0)
    cv.waitKey(0)
    cv.destroyAllWindows()

def create_separator_for(image):
    separator = np.zeros((5, image.shape[1], 3), dtype=np.uint8)
    separator[:, :] = WINDOW_BG_COLOR
    return separator

file = sys.argv[1] if len(sys.argv) > 1 else None
if not file:
    raise ValueError("No image file provided, pass as first argument")

def load_image() -> np.ndarray:

    # / ".config/hammerspoon/config/macros/screenpal/py/timeline03a-2.png"

    image = cv.imread(str(file), cv.IMREAD_COLOR)  # BGR
    if image is None:
        raise ValueError(f"Could not load image from {file}")

    # PRN any assertions about size so if it changes I know that I might need to adjust some logic (i.e. top/bottom borders)?

    # * take off top and bottom borders (leave leading/trailing else have to adjust x values)
    return image[2:-2]

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

# returns 2D array, where each pixel is either 0 or 255
# 0 = NOT A MATCH (1+ components does not match w/in tolerance)
# 255 = MATCH (all components BGR match w/in tolerance)
def color_mask(img, color, tol):
    diff = np.abs(img.astype(np.int16) - color.astype(np.int16))
    return (diff <= tol).all(axis=2).astype(np.uint8) * 255

image = load_image()

# Tiny tolerance may handle edge pixels
tolerance = 4
timeline_mask = color_mask(image, colors_bgr.timeline_bg, tolerance)  # leave so you can come back to this later for additional detection (i.e. unmarked silences, < 1 second)
playhead_mask = color_mask(image, colors_bgr.playhead, tolerance)
