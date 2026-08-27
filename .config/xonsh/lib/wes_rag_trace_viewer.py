"""Human-friendly rendering for semantic grep retrieval traces."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text


JQ_PROJECTION = r"""
{
  source,
  duration_ms,
  query: .request_body.query,
  instruct: .request_body.instruct,
  current_file: .request_body.currentFileAbsolutePath,
  matches: [
    .response.result.matches[]? |
    {
      file,
      start_line: (.start_line_base0 + 1),
      end_line: (.end_line_base0 + 1),
      signature,
      text,
      embed_score,
      embed_rank,
      rerank_score,
      rerank_rank,
      type
    }
  ]
}
"""


def newest_trace(state_dir: Path, source: str | None = None) -> Path | None:
    pattern = f"{source}/*-trace.json" if source else "*/*-trace.json"
    traces = list((state_dir / "ask-openai/rag").glob(pattern))
    return max(traces, key=lambda path: path.stat().st_mtime, default=None)


def project_trace(path: Path) -> dict:
    completed = subprocess.run(
        ["jq", JQ_PROJECTION, str(path)],
        capture_output=True,
        check=False,
        text=True,
    )
    if completed.returncode:
        raise RuntimeError(completed.stderr.strip() or "jq could not read trace")
    return json.loads(completed.stdout)


def _percent(value: float | None) -> str:
    return "—" if value is None else f"{value * 100:.1f}%"


def render_trace(trace: dict, path: Path, *, limit: int, show_text: bool, console: Console) -> None:
    matches = trace.get("matches", [])
    query = Text(trace.get("query") or "", style="bold bright_white")
    details = Text.assemble(
        (trace.get("source") or "unknown", "bold magenta"),
        "  •  ",
        (f"{trace.get('duration_ms', '?')} ms", "cyan"),
        "  •  ",
        (f"{len(matches)} matches", "green"),
        "\n",
        (str(path), "dim"),
    )
    console.print(Panel.fit(Text.assemble(query, "\n", details), title="󰕡 RAG trace", border_style="magenta"))

    table = Table(show_header=True, header_style="bold", row_styles=("", "dim"))
    table.add_column("#", justify="right", style="bold magenta")
    table.add_column("rerank", justify="right")
    table.add_column("embed", justify="right")
    table.add_column("location", overflow="fold")
    table.add_column("match", overflow="fold")

    for match in matches[:limit]:
        rerank_rank = match.get("rerank_rank")
        embed_rank = match.get("embed_rank")
        location = f"{match.get('file')}:{match.get('start_line')}-{match.get('end_line')}"
        label = match.get("signature") or (match.get("text") or "").splitlines()[0]
        table.add_row(
            str((rerank_rank if rerank_rank is not None else len(table.rows)) + 1),
            f"{_percent(match.get('rerank_score'))}  #{(rerank_rank or 0) + 1}",
            f"{_percent(match.get('embed_score'))}  #{(embed_rank or 0) + 1}",
            Text(location, style="cyan"),
            label,
        )
    console.print(table)

    if show_text:
        for match in matches[:limit]:
            rank = (match.get("rerank_rank") or 0) + 1
            title = f"#{rank} {match.get('file')}:{match.get('start_line')}-{match.get('end_line')}"
            console.print(Panel(match.get("text") or "", title=title, border_style="dim magenta"))


def main(args: list[str], *, state_dir: Path | None = None, console: Console | None = None) -> int:
    parser = argparse.ArgumentParser(prog="ragtrace", description="Render a semantic grep trace")
    parser.add_argument("path", nargs="?", type=Path, help="trace path; defaults to newest")
    parser.add_argument("--source", help="limit newest trace to a source such as telescope or fim")
    parser.add_argument("--limit", type=int, default=10, help="number of matches to show")
    parser.add_argument("--text", action="store_true", help="show full matched chunks")
    parsed = parser.parse_args(args)

    state_dir = state_dir or Path.home() / ".local/state/nvim"
    path = parsed.path or newest_trace(state_dir, parsed.source)
    if path is None:
        parser.error("no RAG traces found")
    if not path.is_file():
        parser.error(f"trace does not exist: {path}")

    render_trace(project_trace(path), path, limit=max(1, parsed.limit), show_text=parsed.text, console=console or Console())
    return 0
