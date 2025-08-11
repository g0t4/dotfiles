import argparse, os, re
from dataclasses import dataclass
from collections import defaultdict
from typing import Dict, List, Tuple
import psutil
import rich

# prefer full cmdline; fall back to name only if cmdline unavailable

@dataclass(frozen=True)
class ProcessInfo:
    pid: int
    ppid: int
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
    # TODO consider * on end if --no-color option added
    if GREP_COLOR:
        return f"\x1b[{GREP_COLOR}m" + text + "\x1b[0m"
    else:
        # use bold by default if no GREP_COLOR
        return f"\x1b[1m" + text + "\x1b[0m"

def label(p):
    assert args is not None # change args to never see it as None
    if args.show_full_cmd:
        return f"{p.cmd} [{f"{p.name}({p.pid})"}]"
    return f"{p.name}({p.pid})"

def part(text):
    assert args is not None
    if not args.ascii:
        return text

    match text:
        case "└─":
            return "`--"
        case "├─":
            return "+--"
        case "│":
            return "|"
        # case "   ":
        #     return text
        case _:
            # PRN warn?
            return text

def draw_tree(rootmost_match_pid, all_processes, children_by_ppid, matches):

    def _draw_tree(pid, prefix="", is_last=True):
        process = all_processes.get(pid)
        if not process:
            return

        if prefix == "":
            connector = ""
        elif is_last:
            connector = part("└─")
        else:
            connector = part("├─")

        text = label(process)
        if pid in matches:
            text = highlight_match(text)
        print(f"{prefix}{connector} {text}" if connector else text)
        children = [k for k in children_by_ppid.get(pid, []) if k in all_processes]
        if not children:
            return

        if is_last:
            next_prefix = prefix + "   "
        else:
            next_prefix = prefix + part("│") + "  "

        for index, child_pid in enumerate(children):
            _draw_tree(child_pid, next_prefix, index == len(children) - 1)

    _draw_tree(rootmost_match_pid)


args = None
def main():
    global args # so I don't have to pass to every function

    ap = argparse.ArgumentParser(description="pstree-like grep using pure Python (psutil).")
    ap.add_argument("pattern", help="regex matched against process name and full cmdline")
    ap.add_argument("-i", "--ignore-case", action="store_true", help="case-insensitive matching")
    ap.add_argument("--ascii", action="store_true", help="use ASCII connectors")
    # ok -f rubs up against usage of -f in pgrep but I don't care... I don't think I care to ever not match on full command line so I wouldn't need both -f and -l which are not easy to remember anyways
    ap.add_argument("-f", "--show-full-cmd", action="store_true", help="show full command instead of name(pid)")
    args = ap.parse_args()
    if args.pattern == "":
        print("Pattern CANNOT BE EMPTY")
        ap.print_help()
        return

    procs, children_by_ppid = proc_snap()
    matches = match_set(procs, args.pattern, args.ignore_case)
    if not matches:
        print("No matches.")
        return

    rootmost_matches = prune_to_rootmost_match(matches, procs)

    print(f"# matches: {len(matches)}  roots: {len(rootmost_matches)}  (matched nodes are bold and marked with *)")
    first = True
    for rootmost_match_pid in rootmost_matches:
        if not first:
            print()
        first = False
        draw_tree(rootmost_match_pid, procs, children_by_ppid, matches)

if __name__ == "__main__":
    main()
