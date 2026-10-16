import os
import subprocess
from collections import defaultdict
from rich.console import Console
from rich.table import Table

def _foreach_git_repo(action):
    for root, dirs, files in os.walk("."):
        if ".git" in files or ".git" in dirs:
            action(os.path.relpath(root))
            dirs[:] = []

def _list_git_repos():
    _foreach_git_repo(print)

def _git_churn_repos():
    _foreach_git_repo(lambda repo: _git_churn("2 days ago", repo))

def _git_churn(since = "2 days ago", repo = "."):
    """Summarize git churn per author using --since git log argumnet."""

    since = " ".join(since) or "2 days ago"
    result = subprocess.run(
        ["git", "-C", repo, "log", f"--since={since}", "--numstat", "--format=author:%an"],
        capture_output=True,
        text=True,
    )
    console = Console()
    if result.returncode:
        console.print(result.stderr.strip(), style="red", markup=False)
        return result.returncode

    if not result.stdout.strip():
        return

    counts = defaultdict(lambda: [0, 0, 0])
    author = None
    for line in result.stdout.splitlines():
        if line.startswith("author:"):
            author = line.removeprefix("author:")
            counts[author][0] += 1
        elif author and "\t" in line:
            added, deleted, _ = line.split("\t", 2)
            if added.isdigit() and deleted.isdigit():
                counts[author][1] += int(added)
                counts[author][2] += int(deleted)

    table = Table(title=f"Git churn {repo}· since {since}")
    table.add_column("Author")
    for name, style in [
        ("Commits", ""),
        ("Added", "green"),
        ("Deleted", "red"),
        ("Net", "cyan"),
    ]:
        table.add_column(name, justify="right", style=style)

    for author, (commits, added, deleted) in sorted(
        counts.items(), key=lambda item: item[1][1], reverse=True
    ):
        table.add_row(
            author, str(commits), f"{added:,}", f"{deleted:,}",
            f"{added - deleted:+,}",
        )

    console.print(table)
