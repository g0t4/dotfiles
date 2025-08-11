import argparse, os, re
from dataclasses import dataclass
from collections import defaultdict
from typing import Dict, List, Tuple
import psutil
import rich

def getpgid(pid):
    try:
        return os.getpgid(pid)
    except Exception:
        # windows?
        return None

# prefer full cmdline; fall back to name only if cmdline unavailable

@dataclass(frozen=True)
class ProcessInfo:
    pid: int
    ppid: int
    pgid: int|None
    name: str
    cmd: str

def proc_snap() -> Tuple[Dict[int, ProcessInfo], Dict[int, List[int]]]:
    procs: Dict[int, ProcessInfo] = {}
    children_by_ppid: Dict[int, List[int]] = defaultdict(list)
    for process in psutil.process_iter(["pid", "ppid", "name", "cmdline"]):
        info = process.info
        pid = info["pid"]
        try:
            ppid = info["ppid"] or 0 # is 0 a good default?
            cmdline_full = info.get("cmdline") or [] # full argv if allowed
            name = (info.get("name") or "").strip()
            use_cmd = " ".join(cmdline_full).strip() or name or f"[pid:{pid}]"
            procs[pid] = ProcessInfo(
                pid=pid,
                ppid=ppid,
                pgid=getpgid(pid),
                name=name,
                cmd=use_cmd,
            )
            children_by_ppid[ppid].append(pid)
        except psutil.NoSuchProcess as e:
            rich.print(f"NoSuchProcess for process {pid}:", e)
            continue
        except psutil.AccessDenied as e:
            rich.print(f"AccessDenied for process {pid}:", e)
            continue

    # sort processes by name, within each PPID
    for ppid in list(children_by_ppid.keys()):
        # TODO what sort do I want? should it happen here or elsewhere?
        children_by_ppid[ppid].sort(key=lambda x: (procs[x].name, x))
    return procs, children_by_ppid

def match_set(procs, pattern, ignore_case):
    r = re.compile(pattern, re.IGNORECASE if ignore_case else 0)
    return {
        pid for pid, process in procs.items()
        if r.search(process.cmd) or r.search(process.name)
    }



def has_ancestor_in_matches(pid, all_processes, matches):
    seen = set()
    while pid and pid not in seen:
        seen.add(pid)
        process = all_processes.get(pid)
        if not process:
            return False
        parent_pid = process.ppid
        if parent_pid in matches:
            return True
        pid = parent_pid
    return False

def prune_to_rootmost_match(matches, all_processes):
    # that way we don't show nested matches in a separate, top-level branch too
    only_rootmost_matches = [pid for pid in matches if not has_ancestor_in_matches(pid, all_processes, matches)]
    return only_rootmost_matches

def highlight_match(text):
    GREP_COLOR = os.getenv("GREP_COLOR")
    # if not sys.stdout.isatty():
    #     return text
    if GREP_COLOR:
        return f"\x1b[{GREP_COLOR}m" + text + "\x1b[0m"
    else:
        # use bold by default if no GREP_COLOR
        return f"\x1b[1m" + text + "\x1b[0m"

def label(p, show_full_cmd):
    if show_full_cmd:
        return f"{p.cmd} [{f"{p.name}({p.pid} / pgid: {p.pgid})"}]"
    return f"{p.name}({p.pid} / pgid: {p.pgid})"

def draw_tree(rootmost_match, procs, children, match, ascii_lines=False, show_full_cmd=False):
    V, T, L, S = ("│", "├─", "└─", "   ")
    if ascii_lines:
        V, T, L, S = ("|", "+--", "`--", "   ")

    def rec(pid, prefix="", is_last=True):
        p = procs.get(pid)
        if not p:
            return
        connector = "" if prefix == "" else (L if is_last else T)
        text = label(p, show_full_cmd)
        if pid in match:
            text = highlight_match(text) + " *"
        print(f"{prefix}{connector} {text}" if connector else text)
        kids = [k for k in children.get(pid, []) if k in procs]
        if not kids:
            return
        next_prefix = prefix + (S if is_last else V + "  ")
        for i, k in enumerate(kids):
            rec(k, next_prefix, i == len(kids) - 1)

    rec(rootmost_match)

def main():
    ap = argparse.ArgumentParser(description="pstree-like grep using pure Python (psutil).")
    ap.add_argument("pattern", help="regex matched against process name and full cmdline")
    ap.add_argument("-i", "--ignore-case", action="store_true", help="case-insensitive matching")
    ap.add_argument("--ascii", action="store_true", help="use ASCII connectors")
    # ok -f rubs up against usage of -f in pgrep but I don't care... I don't think I care to ever not match on full command line so I wouldn't need both -f and -l which are not easy to remember anyways
    ap.add_argument("-f", "--show-full-cmd", action="store_true", help="show full command instead of name(pid)")
    args = ap.parse_args()

    procs, children = proc_snap()
    matches = match_set(procs, args.pattern, args.ignore_case)
    if not matches:
        print("No matches.")
        return

    rootmost_matches = prune_to_rootmost_match(matches, procs)

    print(f"# matches: {len(matches)}  roots: {len(rootmost_matches)}  (matched nodes are bold and marked with *)")
    first = True
    for rootmost_match in rootmost_matches:
        if not first:
            print()
        first = False
        draw_tree(rootmost_match, procs, children, matches, ascii_lines=args.ascii, show_full_cmd=args.show_full_cmd)

if __name__ == "__main__":
    main()
