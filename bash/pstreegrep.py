#!/usr/bin/env python3
import argparse, subprocess, sys, shlex, collections

def run(cmd):
    p = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    if p.returncode != 0:
        sys.stderr.write(p.stderr or f"command failed: {cmd}\n")
        sys.exit(1)
    return p.stdout

def get_match_pids(pattern):
    out = run(f"pgrep -f {shlex.quote(pattern)}")
    return {int(x) for x in out.split()}

def build_proc_table():
    # Portable columns on Linux/macOS
    # (macOS may not have SID; we skip it)
    out = run("ps -Ao pid=,ppid=,pgid=,command=")
    procs = {}
    children = collections.defaultdict(list)
    for line in out.splitlines():
        parts = line.strip().split(None, 3)
        if len(parts) < 4:
            continue
        pid, ppid, pgid, cmd = int(parts[0]), int(parts[1]), int(parts[2]), parts[3]
        procs[pid] = {"pid": pid, "ppid": ppid, "pgid": pgid, "cmd": cmd}
        children[ppid].append(pid)
    return procs, children

def has_ancestor_in_set(pid, procs, match_set):
    seen = set()
    while True:
        if pid in seen:  # safety against cycles
            return False
        seen.add(pid)
        p = procs.get(pid)
        if not p:
            return False
        ppid = p["ppid"]
        if ppid == 0:
            return False
        if ppid in match_set:
            return True
        pid = ppid

def prune_to_roots(match_pids, procs):
    return sorted(pid for pid in match_pids if not has_ancestor_in_set(pid, procs, match_pids))

def dedupe_by_pgid(pids, procs):
    seen = set()
    out = []
    for pid in sorted(pids):
        pg = procs.get(pid, {}).get("pgid")
        if pg in seen:
            continue
        seen.add(pg)
        out.append(pid)
    return out

def print_tree(pid, procs, children, match_set, prefix=""):
    p = procs.get(pid)
    if not p:
        return
    mark = "*" if pid in match_set else " "
    line = f"{prefix}{mark} pid={p['pid']} pgid={p['pgid']}  {p['cmd']}"
    print(line)
    kids = sorted(children.get(pid, []))
    for i, k in enumerate(kids):
        last = (i == len(kids)-1)
        branch = "└─ " if last else "├─ "
        cont   = "   " if last else "│  "
        print_tree(k, procs, children, match_set, prefix + branch)
        prefix = prefix  # (prefix for siblings is handled by recursion path)
        # Adjust prefix for children-of-children:
        if kids:
            # update the prefix passed deeper down via recursion call above
            pass

def print_tree2(pid, procs, children, match_set, prefix="", is_last=True):
    p = procs.get(pid)
    if not p: return
    connector = "" if prefix == "" else ("└─ " if is_last else "├─ ")
    mark = "*" if pid in match_set else " "
    print(f"{prefix}{connector}{mark} pid={p['pid']} pgid={p['pgid']}  {p['cmd']}")
    kids = sorted(children.get(pid, []))
    for i, k in enumerate(kids):
        child_prefix = prefix + ("" if prefix=="" else ("   " if is_last else "│  "))
        print_tree2(k, procs, children, match_set, child_prefix, i == len(kids)-1)

def main():
    ap = argparse.ArgumentParser(description="pgrep-driven pstree that dedupes descendants.")
    ap.add_argument("pattern", help="pgrep -f pattern")
    ap.add_argument("--pgid-dedupe", action="store_true",
                    help="Keep only one root per PGID among matches.")
    ap.add_argument("--show-all", action="store_true",
                    help="Show the full tree under each root (default).")
    args = ap.parse_args()

    match = get_match_pids(args.pattern)
    if not match:
        print("No matches.")
        return

    procs, children = build_proc_table()

    roots = prune_to_roots(match, procs)
    if args.pgid_dedupe:
        roots = dedupe_by_pgid(roots, procs)

    # Header
    print(f"# matches: {len(match)}  roots: {len(roots)}  (matched nodes marked with *)")
    for idx, r in enumerate(roots):
        if idx: print("")  # blank line between trees
        # print tree rooted at r
        print_tree2(r, procs, children, match)

if __name__ == "__main__":
    main()
