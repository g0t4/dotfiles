import json
import sys

def main(capture_file):

    return {"capture_file": capture_file}

if __name__ == "__main__":
    # time python3 zoom/zoom_level.py samples/zoom/zoom1.png
    results = main(sys.argv[1])
    print(json.dumps(results))  # output to STDOUT for hs to consume
