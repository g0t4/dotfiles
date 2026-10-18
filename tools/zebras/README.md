# Screen zebras (macOS)

Shows moving red diagonal bars where **any displayed RGB channel is near clipping**, and blue diagonal bars where displayed luminance is near black. The small floating panel shows how much of the primary display meets each rule and lets you move both thresholds while a video plays full screen. The bars ignore mouse clicks. Close the panel to quit.

```sh
cd tools/zebras
uv sync
uv run python zebras.py
```

Defaults: red at **250/255** or above in any channel; blue at **16/255** or below in Rec. 709 luminance; three captures per second. Start with these and adjust the sliders or launch with `--over 245 --under 20 --fps 5`. A lower red value or higher blue value marks more of the image. The overlay uses ScreenCaptureKit to omit its own windows from capture.

On first run, allow Screen Recording for the terminal (or Python) in **System Settings → Privacy & Security → Screen & System Audio Recording**, then relaunch. ScreenCaptureKit can exclude protected video, so such frames may appear black or unavailable.

These are zebras for the **displayed SDR image**, after the video player, macOS display transform, and any tone mapping. They cannot recover detail lost in the source or measure the camera's RAW/log exposure. A pure white title or a black fade will also trigger the bars; judge the parts of the picture you care about. HDR mastering and clipping need a dedicated HDR waveform or source analysis.
