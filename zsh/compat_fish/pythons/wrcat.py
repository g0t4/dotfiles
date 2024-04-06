import argparse
import subprocess
import sys


def wrcat():
    # stdin to stdout ... just in case I want my own formatting command (i.e. roll up bat, grcat, etc into one?)
    # issue is I want to know the command that was run too... in which case I might as well just do this in my wrc command for now?
    for line in sys.stdin:
        sys.stdout.write(line)


if __name__ == "__main__":
    wrcat()
