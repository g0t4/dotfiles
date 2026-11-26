import subprocess
import sys


def rich_colors() -> int:
    # rich provides a top level `__name__ == "__main__"` conditional example of printing colors
    # * this is just a reminder command (if you will) to encapsulate that
    #
    # FYI in pyproject.toml you cannot add the module as a command directly b/c there's no callable entrypoint (i.e. function)
    #   so this won't work:
    #   `rich_colors = "rich.colors"` in `[project.scripts]`
    #
    #  must as a subprocess to ensure __name__ == "__main__"
    return subprocess.call([sys.executable, "-m", "rich.color"])


def rich_emoji():
    # also no main callable, just __name__ check
    return subprocess.call([sys.executable, "-m", "rich.emoji"])
