import sys
from typing import NamedTuple
import cv2 as cv
import numpy as np
from numpy.typing import NDArray
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

file_arg = sys.argv[1] if len(sys.argv) > 1 else None
if not file_arg:
    raise ValueError("No image file provided, pass as first argument")

class TimelineSharedDetectionContext:

    def __init__(self, file):
        self.image = load_image(file)

        # Tiny tolerance may handle edge pixels
        tolerance = 4
        self.timeline_mask = color_mask(self.image, colors_bgr.timeline_bg, tolerance)
        self.playhead_mask = color_mask(self.image, colors_bgr.playhead, tolerance)

        # * waveform
        # TODO might need higher up samples too?
        # TODO test scaling down to 1080p to speed up color masks? IOTW convert in advance instead of at end! do this for everything if it works as well as 4k
        import time
        start = time.time()
        hsv = cv.cvtColor(self.image, cv.COLOR_BGR2HSV)  # type: ignore (FYI this is only 1ms!)
        ms = (time.time() - start) * 1000
        print(f"HSV conversion took {ms:.0f}ms")  # 1.7ms on 1080p image

        start = time.time()
        hue_center = 115
        tol = 3
        min_sat = 80
        # TODO! switch color_mask to use cv.inRange (way faster than my color_mask).. this is way, way sub-ms... shows as 0ms
        self.waveform_mask = cv.inRange( # * 186us FAST!!!
            hsv,
            (hue_center - 1, 100, 30),  # hue ±5°, moderate min S,V to avoid background
            (hue_center + 1, 130, 140),
        )

        ms = (time.time() - start) * 1_000_000
        print(f"hue waveform mask took {ms:.000f}us")

    def divider(self) -> NDArray[np.uint8]:
        return make_divider(self.image)

# RUN ONE TIME for all detection scripts
_shared_context = {}

def get_shared_context(file) -> TimelineSharedDetectionContext:
    # FYI I am not yet happy with how this works but it is sufficient to start on test cases for tools and then I can revisit this
    global _shared_context
    if file not in _shared_context:
        _shared_context[file] = TimelineSharedDetectionContext(file)
    return _shared_context[file]

def load_image(path) -> NDArray[np.uint8]:
    # / ".config/hammerspoon/config/macros/screenpal/py/timeline03a-2.png"
    image = cv.imread(str(path), cv.IMREAD_COLOR)  # BGR
    if image is None:
        raise ValueError(f"Could not load image from {path}")

    # PRN any assertions about size so if it changes I know that I might need to adjust some logic (i.e. top/bottom borders)?

    # * take off top and bottom borders (leave leading/trailing else have to adjust x values)
    return image[2:-2]  # type: ignore

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
def color_mask(img: NDArray[np.uint8], color: NDArray[np.uint8], tolerance: int) -> NDArray[np.uint8]:
    diff = np.abs(img.astype(np.int16) - color.astype(np.int16))
    return (diff <= tolerance).all(axis=2).astype(np.uint8) * 255  # type: ignore

def multi_color_mask(
    img: NDArray[np.uint8],
    colors: NDArray[np.uint8],  # shape (N, 3)
    tolerance: int,
) -> NDArray[np.uint8]:
    img_i16 = img.astype(np.int16)
    colors_i16 = colors.astype(np.int16)

    # compute absolute difference for each color
    diff = np.abs(img_i16[None, :, :, :] - colors_i16[:, None, None, :])
    within_tol = (diff <= tolerance).all(axis=3)  # (N, H, W)
    mask = within_tol.any(axis=0).astype(np.uint8) * 255  # (H, W)
    return mask  # type: ignore

def print_mask_evenly(name, mask, cols_per_line=10):
    """
    Print readable 2-D mask values with column offsets.
    """
    mask = np.asarray(mask).ravel()
    n = len(mask)

    print(f"\n{name} {mask.shape}:\n")
    for i in range(0, n, cols_per_line):
        chunk = mask[i:i + cols_per_line]
        print(f"{i:4d}: {chunk}")
    print()

def scan_mask(mask, cols_per_line=20):
    """
    best for masks with few pixels "turned on"
    i.e. to find playhead,
    or volume add tool shiny top border
    """

    for i in range(len(mask)):
        row = mask[i]
        if np.sum(row) == 0:
            # only print rows with a non-zero value
            continue
        print("row: i=", i)
        re = np.reshape(row, [-1, cols_per_line])
        for i, r in enumerate(re):
            if np.sum(r) == 0:
                # PRN skip all zeros
                continue
            start_col = cols_per_line * i
            print(f"  col: {start_col}:")
            print(f"    {r}")

def make_divider(image: NDArray[np.uint8]) -> NDArray[np.uint8]:
    # make a divider like the background color #2C313C
    divider = np.zeros_like(image)
    divider = divider[:image.shape[0] // 2, :image.shape[1]]  # first half of image
    divider[:] = [60, 49, 44]  # BGR for #2C313C
    return divider
