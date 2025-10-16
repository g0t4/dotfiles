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

    for bar in bar_regions:
        x, y = bar["x"], bar["y"]

        # Sample a small region around this point (5x5 pixels)
        region = image[max(0, y-2):min(height, y+3), max(0, x-2):min(width, x+3)]

        # Calculate average color in BGR
        avg_color = np.mean(region, axis=(0, 1))
        b, g, r = avg_color

        # Blue bars have very high B-G and B-R differences (90+, 200+)
        # Gray/light bars have lower differences (~34-45)
        # Check if this bar is blue based on the observed color differences
        is_blue = (b - g) > 80 and (b - r) > 180

        if is_blue:
            return bar["level"]

    # Default to level 1 if no blue detected
    return 1

def main(capture_file):
    # Load the image
    image = cv2.imread(capture_file)

    if image is None:
        return {"error": f"Could not load image: {capture_file}"}

    # Detect zoom level
    level = detect_zoom_level(image)

    return {"level": level}

if __name__ == "__main__":
    # time python3 zoom/zoom_level.py samples/zoom/zoom1.png
    results = main(sys.argv[1])
    print(json.dumps(results))  # output to STDOUT for hs to consume
