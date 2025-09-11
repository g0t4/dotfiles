## Insert New/Existing => use timeline_bg too!!

- SUMMARY:
    - TLDR => just scan bottom half of timeline for short silences (not full 100%) and existing timeline_bg works
    - WHY? b/c bottom of gradient is SAME as timeline bg color!
    - AND, timline_bg + current tolerance matches nearly bottom 60% of Insert New Regions! (during short silences)

```sh
# examples:
python3 short_silences.py samples/insert-new-recording01.png
```

- insert-new-recording01 => 300x is perfect sampling of Insert New bg in a silence
    - y=4-6 => same bg border as regular timeline bg
    - y=6-8 => lightest gradient part
    - y=~30 => gradient brightness begins (after this its mostly solid)
    - y=60 => maybe sample here?
    - y=80+ => darkest part towards bottom
- likely can scan bottom half with timeline_mask and insert_mask
    - and keep fidelity of short silence matches

## Finding playhead => vestigial code

```py
# this was used when searching AROUND playhead only...
# now I scan full timeline for short silences
#   and then skip 2px (retina) gaps thus skipping over playhead if in middle of short silence
# keeping this here so I can use in a future mask which might need it

    def find_playhead_x(mask: np.ndarray) -> int | None:
        # returns LEFTMOST edge of playhead, PRN could find centermost column
        # mask is 2D, nonzero (255) means "on"
        col_has_all = (mask != 0).all(axis=0)  # boolean per column
        cols = np.where(col_has_all)[0]
        # confirmed returns None if not on screen
        return int(cols[0]) if cols.size > 0 else None

    playhead_leftmost_index = find_playhead_x(playhead_mask)
```
