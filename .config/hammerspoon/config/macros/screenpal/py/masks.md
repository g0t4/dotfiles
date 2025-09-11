## Insert New Recording is different bg blue and gradient

IIAC same for both Insert New and Insert Existing Recordings.

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
