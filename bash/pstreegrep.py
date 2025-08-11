#!/usr/bin/env python3
import argparse, subprocess, sys, shlex, collections, os

def run(cmd):
    p = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    if p.returncode != 0:
        sys.stderr.write(p.stderr or f"command failed: {cmd}\n"); sys.exit(1)
    return p.stdout

def get_match_pids(pattern):
    out = run(f"pgrep -f {shlex.quote(pattern)} || true")
    return {int(x) for x in out.split()} if out.strip() else set()

def build_proc_table():
    # comm: short executable name (pstree-like); command: full argv
    out = run("ps -Ao pid=,ppid=,pgid=,comm=,command=")
    procs, children = {}, collections.defaultdict(list)
    for line in out.splitlines():
        parts = line.strip().split(None, 4)
        if len(parts) < 5: continue
        pid, ppid, pgid = map(int, parts[:3])
        comm, command = parts[3], parts[4]
        procs[pid] = {"pid": pid, "ppid": ppid, "pgid": pgid, "comm": comm, "cmd": command}
        children[ppid].append(pid)
    # stable sort: by comm then pid
    for k in list(children.keys()):
        children[k].sort(key=lambda x: (procs.get(x, {}).get("comm",""), x))
    return procs, children

def has_ancestor_in_set(pid, procs, match):
    seen=set()
    while pid and pid not in seen:
        seen.add(pid)
        p = procs.get(pid); 
        if not p: return False
        pid = p["ppid"]
        if pid in match: return True
    return False

def prune_to_roots(match, procs):
    return sorted(pid for pid in match if not has_ancestor_in_set(pid, procs, match))

def dedupe_by_pgid(pids, procs):
    seen=set(); out=[]
    for pid in sorted(pids):
        pg=procs.get(pid,{}).get("pgid")
        if pg in seen: continue
        seen.add(pg); out.append(pid)
    return out

def is_tty():
    return sys.stdout.isatty()

def style_match(s):
    return f"\x1b[1m{s}\x1b[0m" if is_tty() else s  # bold if TTY

def node_label(p, show_full):
    base = f"{p['comm']}({p['pid']})"
    return f"{p['cmd']} [{base}]" if show_full else base

def draw_tree(root, procs, children, match, ascii_lines=False, show_full=False):
    # classic pstree connectors
    V, T, L, S = ("│","├─","└─","   ")
    if ascii_lines: V, T, L, S = ("|","+--","`--","   ")

    def rec(pid, prefix="", is_last=True):
        p = procs.get(pid); 
        if not p: return
        connector = "" if prefix == "" else (L if is_last else T)
        label = node_label(p, show_full)
        if pid in match: label = style_match(label) + " *"
        print(f"{prefix}{connector} {label}" if connector else f"{label}")
        kids = children.get(pid, [])
        if not kids: return
        next_prefix = prefix + (S if is_last else V + "  ")
        for i, k in enumerate(kids):
            rec(k, next_prefix, i == len(kids)-1)

    rec(root)

def main():
    ap = argparse.ArgumentParser(description="pgrep-driven pstree that keeps full nesting and dedupes descendants.")
    ap.add_argument("pattern", help="pgrep -f pattern")
    ap.add_argument("--pgid-dedupe", action="store_true", help="Keep one root per PGID among matches")
    ap.add_argument("--ascii", action="store_true", help="Use ASCII tree lines")
    ap.add_argument("--full-cmd", action="store_true", help="Show full command instead of comm(pid)")
    args = ap.parse_args()

    match = get_match_pids(args.pattern)
    procs, children = build_proc_table()

    if not match:
        print("No matches."); return

    roots = prune_to_roots(match, procs)
    if args.pgid_dedupe:
        roots = dedupe_by_pgid(roots, procs)

    print(f"# matches: {len(match)}  roots: {len(roots)}  (matched nodes are bold and marked with *)")
    first=True
    for r in roots:
        if not first: print("")
        first=False
        draw_tree(r, procs, children, match, ascii_lines=args.ascii, show_full=args.full_cmd)

if __name__ == "__main__":
    main()
