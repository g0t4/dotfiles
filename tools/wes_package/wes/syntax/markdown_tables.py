"""Align pipe tables for terminal source display."""

from itertools import zip_longest
import re

from rich.cells import cell_len
from rich.console import Console
from rich.text import Text


FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
SEPARATOR = re.compile(r":?-+:?")


def _cells(line):
    if line.startswith(("    ", "\t")):
        return []
    pipes = [
        match.start() for match in re.finditer(r"\\.|\|", line) if match[0] == "|"
    ]
    if not pipes:
        return []
    bounds = [-1, *pipes, len(line)]
    cells = [line[left + 1:right].strip() for left, right in zip(bounds, bounds[1:])]
    start = 0 if cells[0] else 1
    end = len(cells) if cells[-1] else len(cells) - 1
    return cells[start:end]


def _render_table(lines, rows, max_width):
    widths = [max(3, max(map(cell_len, column))) for column in zip(*rows)]
    indents = [line[:len(line) - len(line.lstrip(" "))] for line in lines]
    if max_width is not None:
        available = max_width - max(map(len, indents)) - 3 * len(widths) - 1
        minimums = [min(width, 4) for width in widths]
        if available >= sum(minimums):
            while sum(widths) > available:
                column = max(
                    (i for i, width in enumerate(widths) if width > minimums[i]),
                    key=widths.__getitem__,
                )
                widths[column] -= 1

    console = Console()
    for index, (line, indent, row) in enumerate(zip(lines, indents, rows)):
        ending = line[len(line.rstrip("\r\n")):]
        if index == 1:
            rule = "┼".join("─" * (width + 2) for width in widths)
            yield f"{indent}├{rule}┤{ending}"
            continue

        columns = [
            [part.plain for part in Text(cell).wrap(console, width, overflow="fold")]
            if cell_len(cell) > width else [cell]
            for cell, width in zip(row, widths)
        ]
        rendered = []
        for parts in zip_longest(*columns, fillvalue=""):
            padded = [
                part + " " * (width - cell_len(part))
                for part, width in zip(parts, widths)
            ]
            rendered.append(indent + "│ " + " │ ".join(padded) + " │")
        yield (ending or "\n").join(rendered) + ending


def pad_tables(source, max_width=None):
    """Draw pipe tables, optionally wrapping their cells to a terminal width."""
    if max_width is not None and max_width < 1:
        raise ValueError("table width must be positive")
    lines = source.splitlines(keepends=True)
    fence = ""
    index = 0
    while index < len(lines):
        line = lines[index].rstrip("\r\n")
        marker = FENCE.fullmatch(line)
        if fence:
            if marker and marker[1].startswith(fence) and not marker[2].strip():
                fence = ""
        elif marker and (marker[1][0] == "~" or "`" not in marker[2]):
            fence = marker[1]
        elif index + 1 < len(lines):
            header = _cells(line)
            separator = _cells(lines[index + 1].rstrip("\r\n"))
            if header and len(header) == len(separator) and all(
                SEPARATOR.fullmatch(cell) for cell in separator
            ):
                rows = [header, separator]
                for body_index in range(index + 2, len(lines)):
                    body_line = lines[body_index].rstrip("\r\n")
                    row = _cells(body_line)
                    if FENCE.fullmatch(body_line) or len(row) != len(header):
                        break
                    rows.append(row)

                end = index + len(rows)
                rendered = list(_render_table(lines[index:end], rows, max_width))
                lines[index:end] = rendered
                index += len(rendered)
                continue
        index += 1
    return "".join(lines)
