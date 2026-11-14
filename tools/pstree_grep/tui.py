"""Live process filtering, keeping the descendants of rootmost matches."""

from __future__ import annotations

import asyncio
import os
import re

from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import ScrollableContainer
from textual.widgets import Footer, Input, Static
from wes_syntax import load_style

from .cli import get_matching_pids, proc_snap, prune_to_rootmost_match

COLORS, _ = load_style()
MATCH = "#ff79c6"


def render_tree(procs, children, regex, *, full_cmd=False, ascii=False):
    """Return styled text and counts from a single consistent snapshot."""
    matches = get_matching_pids(procs, regex)
    roots = sorted(prune_to_rootmost_match(matches, procs))
    output = Text(no_wrap=True, overflow="ignore")
    seen = set()
    for root in roots:
        if output:
            output.append("\n")
        stack = [(root, "", "", True)]
        while stack:
            pid, prefix, connector, last = stack.pop()
            if pid in seen or pid not in procs:
                continue
            seen.add(pid)
            process = procs[pid]
            output.append(prefix + connector, style=COLORS["comment"])
            label = Text(
                process.cmd if full_cmd else process.name, style=COLORS["text"]
            )
            label.append(f"({pid})", style=COLORS["number"])
            if pid in matches and regex.pattern:
                label.stylize(f"bold {MATCH}")
                # Stronger emphasis for visible regex hits; asterisk also identifies
                # command-line matches hidden by compact process names.
                for hit in regex.finditer(label.plain):
                    if hit.start() != hit.end():
                        label.stylize("underline", hit.start(), hit.end())
                label.append("*", style=f"bold {MATCH}")
            output.append_text(label)
            if pid == os.getpid():
                output.append(" [self: pstree_grep]", style=COLORS["builtin"])
            output.append("\n")
            descendants = [child for child in children.get(pid, []) if child in procs]
            next_prefix = prefix + (
                ("   " if last else "|  " if ascii else "│  ") if connector else "   "
            )
            for index in reversed(range(len(descendants))):
                child_last = index == len(descendants) - 1
                branch = (
                    ("`-- " if child_last else "+-- ")
                    if ascii
                    else ("└─ " if child_last else "├─ ")
                )
                stack.append((descendants[index], next_prefix, branch, child_last))
    if not roots:
        output.append("No matches.", style=COLORS["comment"])
    return output, len(matches), len(roots)


class ProcessTreeApp(App):
    TITLE = "pstree_grep"
    ENABLE_COMMAND_PALETTE = False
    CSS = """
    Screen { background: $background; color: $text; }
    #filter { height: 3; border: tall $primary; margin: 0; }
    #status { height: 1; padding: 0 1; color: $text-muted; }
    #viewport { height: 1fr; padding: 0 1; }
    #tree { width: auto; min-width: 100%; height: auto; }
    Footer { background: $background; }
    """
    BINDINGS = [
        Binding("f9", "quit", "Quit", priority=True),
        Binding("ctrl+c", "quit", priority=True, show=False),
        Binding("q", "quit", "Quit", show=False),
        Binding("/", "filter", "Filter"),
        Binding("escape", "browse", "Browse", priority=True),
        Binding("f", "full_cmd", show=False),
        Binding("ctrl+l", "full_cmd", "Full cmd", priority=True),
        Binding("i", "ignore_case", show=False),
        Binding("ctrl+g", "ignore_case", "Case", priority=True),
        Binding("up", "scroll_tree('up')", show=False, priority=True),
        Binding("down", "scroll_tree('down')", show=False, priority=True),
        Binding("pageup", "scroll_tree('page_up')", show=False, priority=True),
        Binding("pagedown", "scroll_tree('page_down')", show=False, priority=True),
    ]

    def __init__(
        self,
        pattern="",
        *,
        ignore_case=False,
        full_cmd=False,
        ascii=False,
        snapshot=proc_snap,
        refresh_interval=1.0,
    ):
        super().__init__()
        from textual.theme import Theme

        self.register_theme(
            Theme(
                name="wes-processes",
                primary=COLORS["function"],
                secondary=COLORS["keyword"],
                accent=MATCH,
                foreground=COLORS["text"],
                background=COLORS["background"],
                surface=COLORS["background"],
                panel=COLORS["background"],
                success=COLORS["string"],
                warning=COLORS["type"],
                error=COLORS["error"],
                dark=True,
            )
        )
        self.theme = "wes-processes"
        self.pattern = pattern
        self.ignore_case = ignore_case
        self.full_cmd = full_cmd
        self.ascii = ascii
        self.snapshot = snapshot
        self.refresh_interval = refresh_interval
        self.procs, self.process_children = {}, {}
        self.regex = re.compile("")
        self.regex_error = ""
        self._sampling = False

    def compose(self) -> ComposeResult:
        yield Input(
            self.pattern,
            placeholder="Regex against names + full arguments…",
            id="filter",
        )
        yield Static(id="status", markup=False)
        with ScrollableContainer(id="viewport"):
            yield Static(id="tree", markup=False)
        yield Footer()

    async def on_mount(self):
        self.query_one(Input).focus()
        self.compile_filter()
        await self.sample()
        self.set_interval(self.refresh_interval, self.sample)

    async def sample(self):
        if self._sampling:
            return
        self._sampling = True
        try:
            self.procs, self.process_children = await asyncio.to_thread(self.snapshot)
            self.render_snapshot()
        finally:
            self._sampling = False

    def compile_filter(self):
        try:
            regex = re.compile(self.pattern, re.IGNORECASE if self.ignore_case else 0)
        except re.error as error:
            self.regex_error = f"Invalid regex: {error} — showing last valid filter"
        else:
            self.regex = regex
            self.regex_error = ""
        self.render_snapshot()

    def render_snapshot(self):
        output, matches, roots = render_tree(
            self.procs,
            self.process_children,
            self.regex,
            full_cmd=self.full_cmd,
            ascii=self.ascii,
        )
        self.query_one("#tree", Static).update(output)
        status = self.regex_error or (
            f"{matches} matches · {roots} roots · {self.refresh_interval:g}s · "
            f"{'ignore case' if self.ignore_case else 'case sensitive'} · "
            f"{'full commands' if self.full_cmd else 'compact'} · * match"
        )
        self.query_one("#status", Static).update(
            Text(
                status, style=COLORS["error"] if self.regex_error else COLORS["comment"]
            )
        )

    def on_input_changed(self, event: Input.Changed):
        self.pattern = event.value
        self.compile_filter()

    def on_input_submitted(self):
        self.action_browse()

    def action_filter(self):
        self.query_one(Input).focus()

    def action_browse(self):
        self.query_one("#viewport").focus()

    def action_full_cmd(self):
        self.full_cmd = not self.full_cmd
        self.render_snapshot()

    def action_ignore_case(self):
        self.ignore_case = not self.ignore_case
        self.compile_filter()

    def action_scroll_tree(self, direction):
        getattr(self.query_one("#viewport"), f"scroll_{direction}")(animate=False)
