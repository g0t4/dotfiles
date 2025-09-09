import sys
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

DEBUG = "--debug" in sys.argv

if DEBUG:
    print(f'{sys.argv=}')
    from rich import print

def create_separator_for(image):
    separator = np.zeros((5, image.shape[1], 3), dtype=np.uint8)
    separator[:, :] = WINDOW_BG_COLOR
    return separator

def load_image() -> np.ndarray:

    file = sys.argv[1] if len(sys.argv) > 1 else None
    if not file:
        raise ValueError("No image file provided, pass as first argument")

    # / ".config/hammerspoon/config/macros/screenpal/py/timeline03a-2.png"

    image = cv.imread(str(file), cv.IMREAD_COLOR)  # BGR
    if image is None:
        raise ValueError(f"Could not load image from {file}")

    # * take off top and bottom borders (leave leading/trailing else have to adjust x values)
    # image = image[2:-2]
    #0x282828 (40,40,40)

    show_and_wait(
        create_separator_for(image)[:, 1400:1500],
        image[2:, 1400:1500],
        create_separator_for(image)[:, 1400:1500],
        image[2:-1, 1400:1500],
        create_separator_for(image)[:, 1400:1500],
        image[2:-2, 1400:1500],
        create_separator_for(image)[:, 1400:1500],
    )
    exit()

    return image
