import argparse, os, re
from collections import defaultdict
import psutil
import rich

def getpgid(pid):
    try:
        return os.getpgid(pid)
    except Exception:
        # windows?
        return None

# prefer full cmdline; fall back to name only if cmdline unavailable
def proc_snap():
    procs, children_by_ppid = {}, defaultdict(list)
    # https://psutil.readthedocs.io/en/latest/index.html#psutil.process_iter
    # - possible issues with when it gets process info... and if IDs are reused (i.e. macOS PIDs)
    #   but IIUC pgrep would have the same problem, there's no atomic way to get process info for all or a subset of processes?
    for process in psutil.process_iter(["pid", "ppid", "name", "cmdline"]):
        info = process.info
        pid = info["pid"]
        try:
            ppid = info["ppid"] or 0  # is 0 a good default?
            cmdline_full = info.get("cmdline") or []  # full argv if allowed
            name = (info.get("name") or "").strip()
            use_cmd = " ".join(cmdline_full).strip() or name or f"[pid:{pid}]"
            procs[pid] = {
                "pid": pid,
                "ppid": ppid,
                # another opportunity for a race condition:
                "pgid": getpgid(pid),
                "name": name,
                "cmd": use_cmd,
            }
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
        children_by_ppid[ppid].sort(key=lambda x: (procs.get(x, {}).get("name", ""), x))

    return procs, children_by_ppid

def match_set(procs, pattern, ignore_case):
    r = re.compile(pattern, re.IGNORECASE if ignore_case else 0)
    return {pid for pid, p in procs.items() if r.search(p["cmd"]) or r.search(p["name"])}

def has_ancestor_in_set(pid, procs, match):
    seen = set()
    while pid and pid not in seen:
        seen.add(pid)
        p = procs.get(pid)
        if not p:
            return False
        parent = p["ppid"]
        if parent in match:
            return True
        pid = parent
    return False

def prune_to_roots(match, procs):
    return sorted(pid for pid in match if not has_ancestor_in_set(pid, procs, match))

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

def highlight_match(text):
    GREP_COLOR = os.getenv("GREP_COLOR")
    # if not sys.stdout.isatty():
    #     return text
    if GREP_COLOR:
        return f"\x1b[{GREP_COLOR}m" + text + "\x1b[0m"
    else:
        # use bold by default if no GREP_COLOR
        return f"\x1b[1m" + text + "\x1b[0m"

def label(p, full_cmd):
    return f"{p['cmd']} [{f"{p['name']}({p['pid']})"}]"  \
        if full_cmd \
        else f"{p['name']}({p['pid']})"

def draw_tree(root, procs, children, match, ascii_lines=False, full_cmd=False):
    V, T, L, S = ("│", "├─", "└─", "   ")
    if ascii_lines:
        V, T, L, S = ("|", "+--", "`--", "   ")

    def rec(pid, prefix="", is_last=True):
        p = procs.get(pid)
        if not p:
            return
        connector = "" if prefix == "" else (L if is_last else T)
        text = label(p, full_cmd)
        if pid in match:
            text = highlight_match(text) + " *"
        print(f"{prefix}{connector} {text}" if connector else text)
        kids = [k for k in children.get(pid, []) if k in procs]
        if not kids:
            return
        next_prefix = prefix + (S if is_last else V + "  ")
        for i, k in enumerate(kids):
            rec(k, next_prefix, i == len(kids) - 1)

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
