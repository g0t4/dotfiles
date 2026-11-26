#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pygments>=2.19,<3", "rich>=13.9,<15", "pillow>=11,<13", "colorspacious>=1.1.2,<2", "xonsh>=0.24,<0.25"]
# ///
"""Compatibility launcher for the first-class ``highlight`` command."""

from tools.highlight.__main__ import contrast, main
from wes.syntax import load_style

__all__ = ["contrast", "load_style", "main"]


if __name__ == "__main__":
    main()
