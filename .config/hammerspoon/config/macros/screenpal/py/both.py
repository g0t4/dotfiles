import json
from regular_silences import get_regular_silences
from short_silences import get_short_silences

# TODO! OPTIMIZE FOR ONE LOAD OF ANY SHARED ASSETS (i.e. image load)

if __name__ == "__main__":

    # time python3 both.py samples/playhead-darkblue1.png --debug
    # FYI just as fast to do both at the same time
    #  IIGC imports eat up most of the time

    combined = get_short_silences()
    regular = get_regular_silences()

    # merge into short object since it has multiple keys currently
    combined["regular_silences"] = regular["silences"]

    print(json.dumps(combined))  # output to STDOUT for hs to consume
