"""Compatibility entry point for existing shell wrappers."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))
from tools.pstree_grep.cli import main

if __name__ == "__main__":
    main()
