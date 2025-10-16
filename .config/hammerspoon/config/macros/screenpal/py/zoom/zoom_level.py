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
    # Bars are triangular (increase in height left to right), so sample near the bottom
    # where all bars are present to get the actual bar color, not the background
    y_sample = int(height * 0.80)  # Sample at 80% down from top

    bar_regions = [
        # Bar 1 (leftmost, shortest) - x position around 20-25% of width
        {"x": int(width * 0.22), "y": y_sample, "level": 1},
        # Bar 2 (middle) - x position around 45-50% of width
        {"x": int(width * 0.48), "y": y_sample, "level": 2},
        # Bar 3 (rightmost, tallest) - x position around 70-75% of width
        {"x": int(width * 0.72), "y": y_sample, "level": 3},
    ]

    # Look for blue bar (B-G > 80, B-R > 180)
    # All active bars show the same bright blue color
    # Gray/inactive bars have B-G ≈ 34, B-R ≈ 45
    for bar in bar_regions:
        x, y = bar["x"], bar["y"]
        region = image[max(0, y-2):min(height, y+3), max(0, x-2):min(width, x+3)]
        avg_color = np.mean(region, axis=(0, 1))
        b, g, r = avg_color

        is_blue = (b - g) > 80 and (b - r) > 180
        if is_blue:
            return bar["level"]

    # Could not detect a blue bar
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
