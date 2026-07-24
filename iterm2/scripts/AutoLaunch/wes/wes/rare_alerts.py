from datetime import datetime
from pathlib import Path
import subprocess


def slap_human(title: str, details: str) -> None:

    # * maybe add log file dedicated to rare events across my tools
    #
    # Path("~/.local/state/iterm-rare-events.log").expanduser().parent.mkdir(
    #     parents=True,
    #     exist_ok=True,
    # )
    #
    # timestamp = datetime.now().astimezone().isoformat(timespec="seconds")
    # with Path("~/.local/state/iterm-rare-events.log").expanduser().open("a") as f:
    #     f.write(f"{timestamp} {details}\n")

    # * I HATE macOS notifications, worst UX ever... and most apps I have setup to hide as a result
    #  even when I allow them they don't fucking show most of the time
    #  or don't show the fucking body of the message
    #  GOD fucking knows why Apple fucked them up so fucking hardcore
    #  ... and stupid FUCKING "SHOW" BUTTON DOES JACK FUCKING SHIT WHEN CLICKED
    # subprocess.run([
    #     "osascript",
    #     "-e",
    #     f'display notification {details!r} with title "Rare iTerm Event" sound name "Sosumi"',
    # ])

    subprocess.run([
        "osascript",
        "-e",
        'on run argv\n'
        '    display alert (item 2 of argv) message (item 1 of argv) as critical \n'
        'end run',
        # use argv to avoid escaping/quoting and other injection bugs / attacks
        title,
        details,
    ])
