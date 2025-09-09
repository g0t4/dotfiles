import numpy as np
import cv2 as cv
from shared import *

def display_mask_only(image, mask, highlight_color=RED) -> np.ndarray:

    highlight_overlay = np.zeros_like(image)  # same shape as image
    highlight_overlay[mask > 0] = highlight_color

    return highlight_overlay

def display_mask_over_image(image, mask, alpha=0.7, highlight_color=RED) -> np.ndarray:
    beta = 1.0 - alpha

    highlight_overlay = display_mask_only(image, mask, highlight_color)

    # Blend image with overlay
    blended = cv.addWeighted(image, alpha, highlight_overlay, beta, 0)
    return blended

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

def display_colorful_labeled_regions(labels):
    h, w = labels.shape
    output = np.zeros((h, w, 3), dtype=np.uint8)

    # TODO rewrite to use modulus? to support more than 10 (rotate)
    # make sure none over 10
    if np.any(labels > len(label_colors) - 1):
        raise ValueError("Labels exceed 10, can only color up to 10 unless you expand list of label_colors")  # or handle appropriately for your use case

    for label, color in label_colors.items():
        output[labels == label] = color

    return output

def build_range_mask(x_ranges_1080p, image_4k):
    """ x-axis ranges over image
        NOTE: each range is [x_start, x_end]
        ALSO assumes 1080p ranges need scaled up to 4k
    """
    range_mask = np.zeros_like(image_4k)
    for start, end in x_ranges_1080p:
        # *2 for 1080p => 4k
        range_mask[:, start * 2:end * 2] = 255
    return range_mask
