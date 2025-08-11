#!/usr/bin/env python3
# pip install psutil
import argparse, os, re, sys
from collections import defaultdict
import psutil

def getpgid(pid):
    try:
        return os.getpgid(pid)
    except Exception:
        return None

# prefer full cmdline; fall back to name only if cmdline unavailable
def proc_snap():
    procs, children = {}, defaultdict(list)
    # https://psutil.readthedocs.io/en/latest/index.html#psutil.process_iter
    # - possible issues with when it gets process info... and if IDs are reused (i.e. macOS PIDs)
    #   but IIUC pgrep would have the same problem, there's no atomic way to get process info for all or a subset of processes?
    for p in psutil.process_iter(["pid","ppid","name","cmdline"]):
        try:
            info = p.info
            pid, ppid = info["pid"], info["ppid"] or 0
            cmdl = info.get("cmdline") or []   # full argv if allowed
            name = (info.get("name") or "").strip()
            cmd  = " ".join(cmdl).strip() or name or f"[pid:{pid}]"
            procs[pid] = {
                "pid": pid,
                "ppid": ppid,
                "pgid": getpgid(pid),
                "name": name,
                "cmd": cmd,
            }
            children[ppid].append(pid)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    for k in list(children.keys()):
        children[k].sort(key=lambda x: (procs.get(x,{}).get("name",""), x))
    return procs, children

def match_set(procs, pattern, ignore_case):
    r = re.compile(pattern, re.IGNORECASE if ignore_case else 0)
    return {pid for pid, p in procs.items() if r.search(p["cmd"]) or (p["cmd"] == p["name"] and r.search(p["name"]))}

def has_ancestor_in_set(pid, procs, match):
    seen=set()
    while pid and pid not in seen:
        seen.add(pid)
        p = procs.get(pid)
        if not p: return False
        parent = p["ppid"]
        if parent in match: return True
        pid = parent
    return False

def prune_to_roots(match, procs):
    return sorted(pid for pid in match if not has_ancestor_in_set(pid, procs, match))

def dedupe_by_pgid(pids, procs):
    seen=set(); out=[]
    for pid in sorted(pids):
        pg = procs.get(pid,{}).get("pgid")
        if pg in seen: continue
        seen.add(pg); out.append(pid)
    return out

def is_tty(): return sys.stdout.isatty()
def bold(s): return f"\x1b[1m{s}\x1b[0m" if is_tty() else s

def label(p, full_cmd):
    base = f"{p['name']}({p['pid']})"
    return f"{p['cmd']} [{base}]" if full_cmd else base

def draw_tree(root, procs, children, match, ascii_lines=False, full_cmd=False):
    V,T,L,S = ("│","├─","└─","   ")
    if ascii_lines: V,T,L,S = ("|","+--","`--","   ")

    def rec(pid, prefix="", is_last=True):
        p = procs.get(pid);
        if not p: return
        connector = "" if prefix=="" else (L if is_last else T)
        text = label(p, full_cmd)
        if pid in match: text = bold(text) + " *"
        print(f"{prefix}{connector} {text}" if connector else text)
        kids = [k for k in children.get(pid, []) if k in procs]
        if not kids: return
        next_prefix = prefix + (S if is_last else V + "  ")
        for i,k in enumerate(kids):
            rec(k, next_prefix, i == len(kids)-1)

    rec(root)

def main():
    ap = argparse.ArgumentParser(description="pstree-like grep using pure Python (psutil).")
    ap.add_argument("pattern", help="regex matched against process name and full cmdline")
    ap.add_argument("-i", "--ignore-case", action="store_true", help="case-insensitive matching")
    ap.add_argument("--pgid-dedupe", action="store_true", help="keep one root per PGID among matches")
    ap.add_argument("--ascii", action="store_true", help="use ASCII connectors")
    ap.add_argument("--full-cmd", action="store_true", help="show full command instead of name(pid)")
    args = ap.parse_args()

    procs, children = proc_snap()
    matches = match_set(procs, args.pattern, args.ignore_case)
    if not matches:
        print("No matches.")
        return

    roots = prune_to_roots(matches, procs)
    if args.pgid_dedupe:
        roots = dedupe_by_pgid(roots, procs)

    print(f"# matches: {len(matches)}  roots: {len(roots)}  (matched nodes are bold and marked with *)")
    first = True
    for r in roots:
        if not first:
            print()
        first = False
        draw_tree(r, procs, children, matches, ascii_lines=args.ascii, full_cmd=args.full_cmd)

if __name__ == "__main__":
    main()
