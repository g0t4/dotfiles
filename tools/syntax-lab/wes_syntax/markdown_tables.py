"""Align pipe tables for terminal source display."""

import re

from rich.cells import cell_len


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


def pad_tables(source):
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

                widths = [
                    max(3, max(map(cell_len, column))) for column in zip(*rows)
                ]
                for row_index, row in enumerate(rows):
                    line_index = index + row_index
                    original = lines[line_index]
                    ending = original[len(original.rstrip("\r\n")):]
                    indent = original[:len(original) - len(original.lstrip(" "))]
                    padded = []
                    for cell, width in zip(row, widths):
                        padding = width - cell_len(cell)
                        if row_index == 1:
                            cell = cell.replace("-", "-" * (padding + 1), 1)
                        else:
                            cell += " " * padding
                        padded.append(cell)
                    lines[line_index] = indent + "| " + " | ".join(padded) + " |" + ending
                index += len(rows)
                continue
        index += 1
    return "".join(lines)
