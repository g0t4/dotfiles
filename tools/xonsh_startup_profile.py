"""Repeatable wall-clock and attribution profiling for Xonsh startup."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import platform
import pstats
import shutil
import statistics
import subprocess
import sys
import tempfile
import time
from typing import Sequence


ROOT = Path(__file__).resolve().parents[1]
RC_DIRECTORY = ROOT / ".config/xonsh/rc.d"
STARTUP_CASES = {
    "current": ("Current configuration", ()),
    "no_rc": ("No rc files", ("--no-rc",)),
}


@dataclass(frozen=True)
class TimingSummary:
    median_ms: float
    min_ms: float
    p95_ms: float
    runs: int


def percentile(values: Sequence[float], fraction: float) -> float:
    """Return a linearly interpolated percentile for an already small sample."""
    ordered = sorted(values)
    if not ordered:
        raise ValueError("cannot calculate a percentile of an empty sample")
    if len(ordered) == 1:
        return ordered[0]
    position = (len(ordered) - 1) * fraction
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1 - weight) + ordered[upper] * weight


def summarize(values: Sequence[float]) -> TimingSummary:
    return TimingSummary(
        median_ms=statistics.median(values),
        min_ms=min(values),
        p95_ms=percentile(values, 0.95),
        runs=len(values),
    )


def run_quiet(
    command: Sequence[str], *, cwd: Path = ROOT, reject_stderr: bool = False
) -> None:
    completed = subprocess.run(
        command,
        cwd=cwd,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )
    if completed.returncode or (reject_stderr and completed.stderr.strip()):
        detail = completed.stderr.strip() or f"exit status {completed.returncode}"
        raise RuntimeError(f"{' '.join(command)}: {detail}")


def measure(
    command: Sequence[str],
    *,
    runs: int,
    warmups: int = 1,
    reject_stderr: bool = False,
) -> TimingSummary:
    for _ in range(warmups):
        run_quiet(command, reject_stderr=reject_stderr)
    values = []
    for _ in range(runs):
        started = time.perf_counter()
        run_quiet(command, reject_stderr=reject_stderr)
        values.append((time.perf_counter() - started) * 1000)
    return summarize(values)


def xonsh_command(xonsh: str, *arguments: str) -> list[str]:
    return [xonsh, *arguments, "-c", "exit"]


def startup_matrix(xonsh: str, runs: int) -> dict[str, TimingSummary]:
    cases = {
        name: xonsh_command(xonsh, *arguments)
        for name, (_label, arguments) in STARTUP_CASES.items()
    }
    return {name: measure(command, runs=runs) for name, command in cases.items()}


def version(command: Sequence[str]) -> str:
    completed = subprocess.run(
        command, cwd=ROOT, capture_output=True, text=True, check=False
    )
    return (completed.stdout or completed.stderr).strip().splitlines()[0]


def metadata(xonsh: str) -> dict[str, str]:
    return {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "commit": version(["git", "rev-parse", "HEAD"]),
        "platform": platform.platform(),
        "python": platform.python_version(),
        "xonsh": version([xonsh, "--version"]),
        "xonsh_executable": str(Path(xonsh).resolve()),
    }


def profile_files(xonsh: str, *, limit: int = 15) -> list[dict[str, object]]:
    """Return inclusive cProfile attribution for custom modules and rc files."""
    with tempfile.TemporaryDirectory(prefix="xonsh-startup-profile-") as directory:
        output = Path(directory) / "startup.prof"
        run_quiet(
            [sys.executable, "-m", "cProfile", "-o", str(output), xonsh, "-c", "exit"]
        )
        stats = pstats.Stats(str(output))

    attributed: dict[str, float] = {}
    for (filename, _line, function), (_cc, _nc, _self, cumulative, _callers) in stats.stats.items():
        path = Path(filename)
        try:
            resolved = path.resolve()
        except OSError:
            resolved = path
        try:
            relative = resolved.relative_to(ROOT)
        except ValueError:
            relative = None
        is_repo_file = relative is not None and (
            not relative.parts or relative.parts[0] != ".venv"
        )
        if function != "<module>" or not (is_repo_file or path.suffix == ".xsh"):
            continue
        key = str(resolved)
        attributed[key] = max(attributed.get(key, 0.0), cumulative * 1000)

    return [
        {"file": path, "inclusive_ms": elapsed}
        for path, elapsed in sorted(
            attributed.items(), key=lambda item: item[1], reverse=True
        )[:limit]
    ]


def deep_omissions(xonsh: str, *, runs: int) -> list[dict[str, object]]:
    """Estimate each rc file's overlapping cost by omitting it."""
    rc_files = sorted(RC_DIRECTORY.glob("*.xsh"))
    baseline = measure(
        xonsh_command(xonsh, "--rc", *map(str, rc_files)),
        runs=runs,
        warmups=0,
        reject_stderr=True,
    )
    results = []
    for index, omitted in enumerate(rc_files, 1):
        print(
            f"deep: {index:>2}/{len(rc_files)} omitting {omitted.name}",
            file=sys.stderr,
            flush=True,
        )
        included = [str(path) for path in rc_files if path != omitted]
        try:
            timing = measure(
                xonsh_command(xonsh, "--rc", *included),
                runs=runs,
                warmups=0,
                reject_stderr=True,
            )
        except RuntimeError as error:
            results.append({"file": omitted.name, "error": str(error)})
            continue
        results.append(
            {
                "file": omitted.name,
                "estimated_ms": baseline.median_ms - timing.median_ms,
                "without_file": asdict(timing),
            }
        )
    return sorted(
        results,
        key=lambda item: float(item.get("estimated_ms", float("-inf"))),
        reverse=True,
    )


def build_snapshot(args) -> dict[str, object]:
    requested_xonsh = (
        args.xonsh or os.environ.get("XONSH_PROFILE_EXECUTABLE") or "xonsh"
    )
    xonsh = shutil.which(requested_xonsh) or requested_xonsh
    matrix = startup_matrix(xonsh, args.runs)
    snapshot: dict[str, object] = {
        "schema_version": 3,
        "metadata": metadata(xonsh),
        "timings": {name: asdict(value) for name, value in matrix.items()},
        "estimates": {
            "rc_overhead_ms": (
                matrix["current"].median_ms - matrix["no_rc"].median_ms
            ),
            **{
                f"{name}_ms": (
                    matrix["current"].median_ms - timing.median_ms
                )
                for name, timing in matrix.items()
                if name not in {"current", "no_rc"}
            },
        },
    }
    if args.deep:
        snapshot["profile_attribution"] = profile_files(xonsh)
        snapshot["rc_omissions"] = deep_omissions(
            xonsh,
            runs=args.deep_runs,
        )
    return snapshot


def format_delta(value: float) -> str:
    return f"{value:+.1f}"


def render(snapshot: dict[str, object], previous: dict[str, object] | None) -> None:
    timings = snapshot["timings"]
    previous_timings = previous.get("timings", {}) if previous else {}
    print("Xonsh startup profile")
    print(f"commit: {snapshot['metadata']['commit']}")
    print()
    print(f"{'Case':29} {'Median':>10} {'Min':>10} {'p95':>10} {'Delta':>10}")
    print("-" * 73)
    for name, (label, _arguments) in STARTUP_CASES.items():
        timing = timings[name]
        delta = ""
        if name in previous_timings:
            delta = format_delta(
                timing["median_ms"] - previous_timings[name]["median_ms"]
            )
        print(
            f"{label:29} {timing['median_ms']:9.1f}ms"
            f" {timing['min_ms']:9.1f}ms {timing['p95_ms']:9.1f}ms {delta:>10}"
        )

    print()
    print("A/B estimates (overlapping, not additive)")
    for name, value in snapshot["estimates"].items():
        print(f"  {name:31} {value:8.1f} ms")

    attribution = snapshot.get("profile_attribution")
    if attribution:
        print()
        print("Inclusive cProfile attribution (distorted absolute time)")
        for item in attribution[:10]:
            try:
                label = str(Path(item["file"]).relative_to(ROOT))
            except ValueError:
                label = item["file"]
            print(f"  {item['inclusive_ms']:8.1f} ms  {label}")

    omissions = snapshot.get("rc_omissions")
    if omissions:
        print()
        print("Leave-one-rc-file-out estimates (overlapping, not additive)")
        shown = 0
        for item in omissions:
            if "estimated_ms" not in item or item["estimated_ms"] <= 0:
                continue
            print(f"  {item['estimated_ms']:8.1f} ms  {item['file']}")
            shown += 1
            if shown == 15:
                break


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(
        description="Repeat and compare Xonsh startup measurements."
    )
    result.add_argument("--runs", type=int, default=9, help="runs per default case")
    result.add_argument("--deep", action="store_true", help="profile and omit rc files")
    result.add_argument(
        "--deep-runs", type=int, default=3, help="runs per rc omission"
    )
    result.add_argument("--json", metavar="PATH", help="write the snapshot, or -")
    result.add_argument("--compare", metavar="PATH", help="compare with a prior JSON snapshot")
    result.add_argument("--xonsh", metavar="PATH", help="Xonsh executable to measure")
    return result


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    if args.runs < 1 or args.deep_runs < 1:
        raise SystemExit("--runs and --deep-runs must be positive")
    snapshot = build_snapshot(args)
    previous = None
    if args.compare:
        previous = json.loads(Path(args.compare).read_text())

    if args.json == "-":
        print(json.dumps(snapshot, indent=2, sort_keys=True))
    else:
        render(snapshot, previous)
        if args.json:
            destination = Path(args.json).expanduser()
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(json.dumps(snapshot, indent=2, sort_keys=True) + "\n")
            print(f"\nwrote {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
