import os, re, subprocess
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

# FYI use \\\\ => looks like \\ before expansion => \ when expanded b/c we want \. in the literal expanded text
abbr("shift_only","""
for i in $(@lines fd '\\\\.(mkv|mov)$'):
    video_editing_just_shift_to_mp4_one_video(i, 133)
""")

def video_editing_just_shift_to_mp4_one_video(video_file, its_offset_ms):
    # TODO ensure old definition doesn't trump this when generatig xonsh from other fish config files
    # TODO merge with stage_1 below which does the same thing
    its_offset = its_offset_ms / 1000
    video_file = os.path.realpath(video_file)
    output_file = os.path.splitext(video_file)[0] + f'.shifted.{its_offset_ms}ms.mp4'
    if os.path.isfile(output_file):
        print(f"Skipping...file already exists: {output_file}")
    else:
        ffmpeg -i @(video_file) -itsoffset @(its_offset) -i @(video_file) -map 0:v -map 1:a -c copy -avoid_negative_ts make_zero @(output_file)


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

def camlink_snapshot():
    timestamp = datetime.now().astimezone().strftime("%Y%m%d-%H%M%S%z")
    output = Path(f"camlink-{timestamp}.txt")

    swift = subprocess.run(
        ["swift", "-e", r"""
import AVFoundation

for device in AVCaptureDevice.devices(for: .video) {
    print("Name: \(device.localizedName)")
    print("Unique ID: \(device.uniqueID)")
    print("Model ID: \(device.modelID)")
    print("Manufacturer: \(device.manufacturer)")
    print("---")
}
"""],
        capture_output=True,
        text=True,
        errors="replace",
    )

    ioreg = subprocess.run(
        ["ioreg", "-p", "IOUSB", "-l", "-w", "0"],
        capture_output=True,
        text=True,
        errors="replace",
    )

    profiler = subprocess.run(
        ["system_profiler", "SPUSBHostDataType"],
        capture_output=True,
        text=True,
        errors="replace",
    )

    with output.open("w") as file:
        file.write(f"Cam Link snapshot: {timestamp}\n")

        for section, result in [
            ("AVFoundation", swift),
            ("USB IORegistry", ioreg),
            ("USB System Profiler", profiler),
        ]:
            file.write(f"\n{'=' * 20} {section} {'=' * 20}\n")
            file.write(result.stdout)
            if result.stderr:
                file.write(f"\nSTDERR:\n{result.stderr}")
            file.write(f"\nExit code: {result.returncode}\n")

    print(output)
    return output

# zj for jellij "namespace"
abbr("zj", "zellij")
abbr("zjd", "zellij delete-all-sessions --yes")
abbr("zjdf", "zellij delete-all-sessions --yes --force") # kill sessions before deleting them
abbr("zjls", "zellij list-sessions")

# certificates

from wes_certificates import main as _cert_connect

def cert_connect(args, stdin=None, stdout=None, stderr=None):
    """cert_connect HOST[:PORT] [--connect ADDRESS] [--ca-file FILE]. Always color."""
    return _cert_connect(args, stdout=stdout, stderr=stderr)

aliases['cert_connect'] = cert_connect
# watch uses an external command, so invoke the same helper directly with Python.
abbr('watch_cert', f'watch -c -n 2 {$WES_DOTFILES}/.venv/bin/python {$WES_DOTFILES}/.config/xonsh/lib/wes_certificates.py')

# * git abbrs xonsh only
abbr('-c', '--create', commands=("git", "switch"))

# gstiv is a function (not an abbr) so fish can delegate to it via `xonsh -c "gstiv"`;
# the noise-filter pattern lives here in one place instead of being duplicated in the fish config
def _gstiv(args, stdin=None, stdout=None, stderr=None):
    """Show ignored/untracked files sans noise, optionally limited to a path."""
    path = args[0] if args else "."
    noise = r"node_modules|\.venv/|\.rag/|__pycache__|ruff_cache|DS_Store|pytest_cache/|/bin/|/obj/|/target/|iterm2env/|egg-info/|dist/"
    git status --ignored --untracked-files --short @(path) | rg_grep -i -v @(noise)

aliases['gstiv'] = _gstiv

# gstiv-style: show symlinks, optionally limited to a path.
# internal == resolve to this dir and under; external == resolve anywhere else
# each link is also annotated: self-loop, dangling, or fine
# links matching the noise pattern are forked into an "ignored" group;
# the default prints only the kept group, --all prints both
from rich.markup import escape as _escape
from rich.text import Text as _Text

_SYMLINK_IGNORE_RE = re.compile(
    r"node_modules|\.venv/|\.rag/|__pycache__|ruff_cache|DS_Store|pytest_cache/|/bin/|/obj/|/target/|iterm2env/|egg-info/|/dist/|/build/"
)

def _is_ignored(rel):
    # match against the link's position (rel) — same philosophy as gstiv,
    # which filters git-status paths, not targets
    return bool(_SYMLINK_IGNORE_RE.search(rel))

def _resolve_link(p):
    """Walk the link chain stage by stage so loops/dangling aren't hidden.

    Returns (resolved, kind, raw) where:
      kind == 'ok'       -> resolved is the existing path reached at the end of the chain
      kind == 'loop'     -> a stage in the chain was seen before (self-loop or cycle)
      kind == 'dangling' -> the chain ends at a path that does not exist
    """
    raw = os.readlink(p)
    seen = set()
    cur = os.path.abspath(p)
    while os.path.lexists(cur) and os.path.islink(cur):
        if cur in seen:
            return None, "loop", raw
        seen.add(cur)
        nxt = os.path.realpath(cur)
        if nxt == cur:
            return None, "loop", raw
        cur = nxt
    if not os.path.lexists(cur):
        return None, "dangling", raw
    return cur, "ok", raw

def _render_rows(rows):
    for rel, raw, target in rows:
        rich.print(f"[bold]{_escape(rel)}[/]")
        print(f"  ->  {raw}")
        rich.print(_Text(f"    = {target}", style="dim"))

def _symlinks_for(subpath, outside, show_all=False):
    path = subpath if subpath else "."
    if Path(path).is_symlink():
        raise ValueError(f"scan root is a symlink: {path}")
    if not os.path.exists(path):
        raise ValueError(f"not a valid path: {path}")
    if not os.path.isdir(path):
        raise ValueError(f"not a valid directory: {path}")
    root = os.path.realpath(path)
    ok_kept = []
    ok_ignored = []
    flagged = []
    for dirpath, dirnames, filenames in os.walk(root):
        for name in filenames + dirnames:
            p = os.path.join(dirpath, name)
            if not os.path.islink(p):
                continue
            rel = os.path.relpath(p, path)
            target, kind, raw = _resolve_link(p)
            if kind != "ok":
                flagged.append((rel, raw, kind))
                continue
            try:
                rel_target = os.path.relpath(target, root)
                inside = rel_target != ".." and not rel_target.startswith(".." + os.sep)
            except ValueError:
                inside = False
            if inside != (not outside):
                continue
            if _is_ignored(rel):
                ok_ignored.append((rel, raw, target))
            else:
                ok_kept.append((rel, raw, target))
    ok_kept.sort(key=lambda r: r[0])
    ok_ignored.sort(key=lambda r: r[0])
    flagged.sort(key=lambda r: r[0])
    _render_rows(ok_kept)
    if show_all and ok_ignored:
        print("ignored:")
        _render_rows(ok_ignored)
    if flagged:
        print("flagged:")
        for rel, raw, kind in flagged:
            if kind == "loop":
                rich.print(f"  [bold red]{_escape(rel)}[/]  [bold red]loop[/]")
            else:
                rich.print(f"  [bold yellow]{_escape(rel)}[/]  [bold yellow]dangling[/]")
            print(f"    ->  {raw}")
    n_loop = sum(1 for _, _, k in flagged if k == "loop")
    n_dangling = sum(1 for _, _, k in flagged if k == "dangling")
    print(f"{'external' if outside else 'internal'} symlinks ({path}): {len(ok_kept)} kept, {len(ok_ignored)} ignored, {len(flagged)} flagged ({n_loop} loop, {n_dangling} dangling)")

def _parse_args(args, fn_name):
    show_all = False
    path = None
    for a in args:
        if a == "--all":
            show_all = True
        elif a.startswith("--"):
            raise ValueError(f"usage: {fn_name} [--all] [path]\nunknown option: {a}")
        elif path is None:
            path = a
        else:
            raise ValueError(f"usage: {fn_name} [--all] [path]\ngot extra argument: {a}")
    return path, show_all

def _list_internal_symlinks(args, stdin=None, stdout=None, stderr=None):
    """List symlinks (limited to a path) whose real target is this dir and under."""
    path, show_all = _parse_args(args, "list_internal_symlinks")
    _symlinks_for(path, outside=False, show_all=show_all)

def _list_external_symlinks(args, stdin=None, stdout=None, stderr=None):
    """List symlinks (limited to a path) whose real target is outside this dir."""
    path, show_all = _parse_args(args, "list_external_symlinks")
    _symlinks_for(path, outside=True, show_all=show_all)

aliases['list_internal_symlinks'] = _list_internal_symlinks
aliases['list_external_symlinks'] = _list_external_symlinks

#
# * git bisect
abbr('gbs', 'git bisect')
abbr('gbsg', 'git bisect good')
abbr('gbsb', 'git bisect bad')
abbr('gbsr', 'git bisect run')
abbr('gbs_visualize', 'git bisect visualize')
abbr('gbs_next', 'git bisect next')
abbr('gbs_skip', 'git bisect skip')
abbr('gbs_reset', 'git bisect reset')
abbr('gbs_start', 'git bisect start')

abbr('lsof_stdio', 'sudo lsof -p % -a -d 0,1,2', cursor_marker="%")
abbr('lsof_stdio_xonsh', 'sudo lsof -p @(os.getpid()) -a -d 0,1,2')  # -a == and (FML b/c you can't have --and)
abbr('lsof_numeric_fds', 'sudo lsof -p % -a -d 0-1000000', cursor_marker="%")  # AFAICT there isn't a filter for only numeric fds so I just provide a huge range :) .. or awk it
if $WATCH_COMMAND:
    abbr('lsof_numeric_fds_watch', $WATCH_COMMAND + ' sudo lsof -p % -a -d 0-1000000', cursor_marker="%")  # AFAICT there isn't a filter for only numeric fds so I just provide a huge range :) .. or awk it
else:
    raise RuntimeError("WATCH_COMMAND environment variable not set")
