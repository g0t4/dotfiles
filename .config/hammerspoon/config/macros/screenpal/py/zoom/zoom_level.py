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
    # 32high x 74wide
    height, width = image.shape[:2]

    # Bars are triangular (increase in height left to right), so sample near the bottom
    # where all bars are present to get the actual bar color, not the background
    bar_regions = [
        {"x": int(width * 0.22), "level": 1},
        {"x": int(width * 0.48), "level": 2},
        {"x": int(width * 0.72), "level": 3},
    ]

    y_sample = int(height * 0.95)  # Sample at 95% down from top
    for bar in bar_regions:
        x_sample = bar["x"]
        sample_region = image[max(0, y_sample-1):min(height, y_sample+1), max(0, x_sample-1):min(width, x_sample+1)]
        # cv2.imshow("region", sample_region)
        # cv2.waitKey()
        # print(f'{sample_region=}')
        average_bgr = np.mean(sample_region, axis=(0, 1))

        # exact color values
        # avg_color=array([225., 191., 180.]) # gray (inactive)
        # avg_color=array([255., 157.,  37.]) # blue (current zoom level)
        # print(f'{average_bgr=}')

        blue, green, red = average_bgr
        # this was claude's take on the algorithm and it works for now
        # Look for blue bar (B-G > 80, B-R > 180)
        # All active bars show the same bright blue color
        # Gray/inactive bars have B-G ≈ 34, B-R ≈ 45
        is_enabled_blue = (blue - green) > 80 and (blue - red) > 180
        if is_enabled_blue:
            return bar["level"]

    return None

def main(capture_file):
    image = cv2.imread(capture_file)

    if image is None:
        return {"error": f"Could not load image: {capture_file}"}

    level = detect_zoom_level(image)

    if level is None:
        return {"error": "Could not detect zoom level - no blue bar found"}

    return {"level": level}

if __name__ == "__main__":
    # time python3 zoom/zoom_level.py samples/zoom/zoom1.png
    results = main(sys.argv[1])
    print(json.dumps(results))  # output to STDOUT for hs to consume
