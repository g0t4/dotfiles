#!/bin/sh
set -eu

# macOS Tahoe: effectively square corners for standard windows and utility panels.
# AppKit ignores zero, so use 0.01. Apps must fully quit and reopen to pick this up.
# Concerns:
# - These preferences are undocumented and may change or stop working after an OS update.
# - Apps with custom window frames (including some browsers/Electron apps) may ignore them.
# - Rounded content inside windows, such as sidebars, has its own radius and may stay rounded.
# - Some apps may show mismatched corners where their content meets the outer window frame.
# - This applies globally; it does not change the physical display's rounded corners.
# - No SIP changes, code injection, or background helper are needed.
# Reference: https://github.com/mansarip/mac-window-corners#without-the-app
defaults write -g NSConvolutionOverride1 -float 0.01
defaults write -g NSConvolutionOverride2 -float 0.01

# Restore macOS defaults, then quit and reopen affected apps:
# Neither key was set before trying this on this Mac. If reusing this elsewhere,
# save any existing values first: deleting a key restores Apple's default, not a prior override.
# defaults delete -g NSConvolutionOverride1
# defaults delete -g NSConvolutionOverride2
