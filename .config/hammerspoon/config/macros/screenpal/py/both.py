import json
from regular_silences import detect_regular_silences
from short_silences import detect_short_silences
from tools import detect_tools

if __name__ == "__main__":

    # time python3 both.py samples/playhead-darkblue1.png --debug
    # FYI just as fast to do both at the same time
    #  IIGC imports eat up most of the time

    short = detect_short_silences()
    regular = detect_regular_silences()
    tools = detect_tools()

    # merge into short object since it has multiple keys currently
    combined = {}
    combined["short_silences"] = short["short_silences"]
    combined["regular_silences"] = regular["regular_silences"]
    combined["tool"] = tools["tool"]

    print(json.dumps(combined))  # output to STDOUT for hs to consume
