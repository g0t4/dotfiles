import os, subprocess
import rich
from pathlib import Path
from xonsh.built_ins import XSH

from wes_abbreviations import abbr, reminder_abbr

if Path(__file__).name < "xonsh-only.xsh":
    raise RuntimeError("xonsh-only.xsh must be named so it loads later on to override with xonsh specific abbrs")

# * history overrides
# abbr hf 'history flush' # randomly this will not flush for 5+ minutes, not sure WTF is going on other than it is async and not guaranteed
#  so use at_exit=False to hopefully avoid this issue:
abbr('hf', '@.history.flush(at_exit=False)')
abbr('hp', 'history pull --show-commands')

# load Lexer by default so it is available, I suspect I'll use this alot
from xonsh.parsers.lexer import Lexer
# Lexer().split('echo "hello world" file.txt')
abbr('lexer_split', 'Lexer().split("%")', cursor_marker="%", reminder=True)


# * dotfiles python "cmdlets"
$_python3 = f"{$WES_DOTFILES}/.venv/bin/python3"
#
XSH.aliases["hexdump"] = [$_python3, f"{$WES_DOTFILES}/.config/xonsh/apps/hex.py"]
XSH.aliases["ascii_table"] = [$_python3, f"{$WES_DOTFILES}/.config/xonsh/apps/ascii_table.py"]
#
# * cleanup
del $_python3

# PRN use a function and wrap in @() if not in command position?
#  btw show the method to get to it as I want to learn/habituate using shutil (not just calculate and show the values)
reminder_abbr('$LINES', 'shutil.get_terminal_size().lines', position="anywhere")
reminder_abbr('$ROWS', 'shutil.get_terminal_size().lines', position="anywhere")
reminder_abbr('$COLUMNS', 'shutil.get_terminal_size().columns', position="anywhere")

def _human_size(num):
    for unit in ['B', 'K', 'M', 'G', 'T']:
        if num < 1024:
            return f"{num:.1f}{unit}"
        num /= 1024
    return f"{num:.1f}P"

# abbr("files_sorted_by_size", "gfind . -type f -printf '%s %p\\n' | grep -Ev 'dylib|.rag|.venv|node_modules|.git|.mp4|uv.lock|./tags|package-lock.json|.cpython' | sort -nr")
def _files_sorted_by_size():
    """List files sorted by size with human-readable sizes."""
    # use this to find biggest files in a repo, i.e. to help me think about limits on run_xonsh/run_process STDOUT/STDERR... although this will be useful otherwise
    cmd = ['fd', '-H', '-t', 'f']
    files = subprocess.check_output(cmd, text=True).splitlines()
    data = [(os.path.getsize(f), f) for f in files]
    data.sort()
    for size, path in data:
        print(f"{_human_size(size):>10} {path}")

aliases['files_sorted_by_size'] = _files_sorted_by_size


import glob
import os

abbr("shift_only","""
for i in glob.glob('*.mkv') + glob.glob('*.mov'):
    video_editing_just_shift_to_mp4_one_video(i)
""")

def video_editing_just_shift_to_mp4_one_video(video_file):
    # TODO ensure old definition doesn't trump this when generatig xonsh from other fish config files
    # TODO merge with stage_1 below which does the same thing
    # converts to mp4 + shifts by 100ms
    video_file = os.path.realpath(video_file)
    output_file = os.path.splitext(video_file)[0] + '.shifted100ms.mp4'
    if os.path.isfile(output_file):
        print(f"Skipping...file already exists: {output_file}")
    else:
        ffmpeg -i @(video_file) -itsoffset 0.1 -i @(video_file) -map 0:v -map 1:a -c copy -avoid_negative_ts make_zero @(output_file)


# * Apple decided to rename SPUSBDataType => SPUSBHostDataType w/ no failure if you use the old value... instead it just behaves as if there are no USB devices (empty STDOUT!)
# so, fail if old value passed so we get an explicit failure and reminder
def system_profiler(args, stdin=None, stdout=None, stderr=None):
    if "SPUSBDataType" in args:
        rich.print("[red] SPUSBDataType is obsolete; use SPUSBHostDataType")
        raise ValueError(
            "SPUSBDataType is obsolete; use SPUSBHostDataType"
        )

    subprocess.run(["/usr/sbin/system_profiler", *args], stdin=stdin, stdout=stdout, stderr=stderr)

aliases["system_profiler"] = system_profiler
abbr("SPUSBDataType", "SPUSBHostDataType", position = "anywhere")  # expand to corrected value when user types


from datetime import datetime
from pathlib import Path
import subprocess

def camlink_snapshot():
    # TODO turn this into a general purpose device enumeration troubleshooting tool if it works well for the camlink obs issue
    timestamp = datetime.now().astimezone().strftime("%Y%m%d-%H%M%S%z")
    output = Path.home() / f"camlink-{timestamp}.txt"

    commands = {
        "AVFoundation": [
            "swift", "-e", """
import AVFoundation
for device in AVCaptureDevice.devices(for: .video) {
    print("Name: \\(device.localizedName)")
    print("Unique ID: \\(device.uniqueID)")
    print("Model ID: \\(device.modelID)")
    print("Manufacturer: \\(device.manufacturer)")
    print("---")
}
""",
        ],
        "USB IORegistry": ["ioreg", "-p", "IOUSB", "-l", "-w", "0"],
        "USB System Profiler": ["system_profiler", "SPUSBHostDataType"],
    }

    with output.open("w") as file:
        file.write(f"Cam Link snapshot: {timestamp}\n")

        for section, command in commands.items():
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                errors="replace",
            )
            file.write(f"\n{'=' * 20} {section} {'=' * 20}\n")
            file.write(result.stdout)
            if result.stderr:
                file.write(f"\nSTDERR:\n{result.stderr}")
            file.write(f"\nExit code: {result.returncode}\n")

    print(output)
    return output
