#!/bin/sh
set -eu

# macOS Tahoe: effectively square corners for standard windows and utility panels.
# AppKit ignores zero, so use 0.01. Apps must fully quit and reopen to pick this up.
# Custom window frames and rounded content inside windows may remain unchanged.
# These preferences are undocumented and may change in future macOS releases.
# Reference: https://github.com/mansarip/mac-window-corners#without-the-app
defaults write -g NSConvolutionOverride1 -float 0.01
defaults write -g NSConvolutionOverride2 -float 0.01

# Restore macOS defaults, then quit and reopen affected apps:
# defaults delete -g NSConvolutionOverride1
# defaults delete -g NSConvolutionOverride2
