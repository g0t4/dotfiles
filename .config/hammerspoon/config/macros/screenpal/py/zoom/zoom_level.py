import json
import sys
import cv2
import numpy as np

def detect_zoom_level(image):
    """
    Detect zoom level by analyzing the color of three zoom bars.
    Bar 1 (leftmost, shortest): zoom level 1
    Bar 2 (middle): zoom level 2
    Bar 3 (rightmost, tallest): zoom level 3

    The active zoom level's bar is blue, others are gray.
    """
    height, width = image.shape[:2]

    # Define sampling regions for each bar (approximate positions)
    # These positions are based on the example images
    # Sample from the middle of each bar
    bar_regions = [
        # Bar 1 (leftmost, shortest) - x position around 20-25% of width
        {"x": int(width * 0.22), "y": int(height * 0.5), "level": 1},
        # Bar 2 (middle) - x position around 45-50% of width
        {"x": int(width * 0.48), "y": int(height * 0.5), "level": 2},
        # Bar 3 (rightmost, tallest) - x position around 70-75% of width
        {"x": int(width * 0.72), "y": int(height * 0.5), "level": 3},
    ]

    # First pass: look for bright blue (bars 2 or 3 when active)
    # Bright blue: B-G > 80, B-R > 180
    for bar in bar_regions:
        x, y = bar["x"], bar["y"]
        region = image[max(0, y-2):min(height, y+3), max(0, x-2):min(width, x+3)]
        avg_color = np.mean(region, axis=(0, 1))
        b, g, r = avg_color

        is_bright_blue = (b - g) > 80 and (b - r) > 180
        if is_bright_blue:
            return bar["level"]

    # If no bright blue found, assume bar 1 is active (it's always dark blue)
    # Verify by checking that bars 2 and 3 are gray (high brightness, low B dominance)
    bar2_region = image[max(0, bar_regions[1]["y"]-2):min(height, bar_regions[1]["y"]+3),
                        max(0, bar_regions[1]["x"]-2):min(width, bar_regions[1]["x"]+3)]
    bar2_color = np.mean(bar2_region, axis=(0, 1))
    bar2_is_gray = bar2_color.mean() > 180

    bar3_region = image[max(0, bar_regions[2]["y"]-2):min(height, bar_regions[2]["y"]+3),
                        max(0, bar_regions[2]["x"]-2):min(width, bar_regions[2]["x"]+3)]
    bar3_color = np.mean(bar3_region, axis=(0, 1))
    bar3_is_gray = bar3_color.mean() > 180

    if bar2_is_gray and bar3_is_gray:
        return 1

    # Could not determine zoom level
    return None

def main(capture_file):
    # Load the image
    image = cv2.imread(capture_file)

    if image is None:
        return {"error": f"Could not load image: {capture_file}"}

    # Detect zoom level
    level = detect_zoom_level(image)

    if level is None:
        return {"error": "Could not detect zoom level - no blue bar found"}

    return {"level": level}

if __name__ == "__main__":
    # time python3 zoom/zoom_level.py samples/zoom/zoom1.png
    results = main(sys.argv[1])
    print(json.dumps(results))  # output to STDOUT for hs to consume
