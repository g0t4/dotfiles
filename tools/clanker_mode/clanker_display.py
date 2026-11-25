"""Shell scrollback for agent work, styled like the chat trace viewer."""

import os
import re
from dataclasses import dataclass
from typing import ClassVar

from rich.console import Console, ConsoleDimensions
from rich.live import Live
from rich.padding import Padding
from rich.panel import Panel
from rich.pretty import Pretty
from rich.text import Text
from rich.tree import Tree
from wes_syntax import syntax


class TerminalConsole(Console):
    @property
    def size(self):
        # COLUMNS and LINES may still describe the pane before a split.
        try:
            columns, rows = os.get_terminal_size(self.file.fileno())
        except (AttributeError, OSError, ValueError):
            return super().size
        if columns and rows:
            return ConsoleDimensions(columns, rows)
        return super().size


class ToolTree(Tree):
    # The viewer's TreeWrapper uses indentation without visible connector lines.
    TREE_GUIDES: ClassVar = [("    ", "    ", "    ", "    ")]


@dataclass
class MessagePanel:
    content: object
    title: str
    color: str
    width: int
    align: str = "left"

    def __rich_console__(self, console, options):
        width = min(self.width, options.max_width)
        lane = min(width, 160)
        left = (width - lane) // 2
        # Use every available cell in narrow splits. On wider terminals leave
        # room across from each bubble, as in the chat viewer.
        limit = min(lane, max(50, round(lane * 0.9)))
        natural = console.measure(self.content, options=options).maximum
        bubble_width = min(limit, max(50, natural + 4))
        panel = Panel(
            self.content,
            title=Text(self.title, style=self.color),
            title_align=self.align,
            border_style=self.color,
            padding=(0, 1),
            width=bubble_width,
        )
        if self.align == "right":
            left += lane - bubble_width
        yield Padding(panel, (0, 0, 0, left), expand=False)


def assistant_panel(answer, width):
    return MessagePanel(
        syntax(answer, "markdown", word_wrap=True), "✨ Clanker", "yellow", width
    )


def tool_panel(call, index, total, width):
    root = ToolTree(Text(f"🐚 {call['name']}", style="bold"), guide_style="dim")
    for name, value in call["args"].items():
        if name == "code" and isinstance(value, str):
            root.add(syntax(value, "xonsh", word_wrap=True))
        else:
            node = root.add(Text(f"{name}:", style="blue"))
            node.add(Pretty(value))
    return MessagePanel(root, f"Tool call {index + 1}/{total}", "yellow", width)


def tool_result_panel(message, width):
    root = ToolTree(Text(message.name or "Tool result", style="bold"))
    # Tool output is literal data, never Rich markup or Markdown instructions.
    root.add(Text.from_ansi(str(message.content)))
    return MessagePanel(root, "🔧 Tool result", "red", width, "right")


def partial_panel(message, console):
    width = console.width
    lane = min(width, 160)
    inner = max(1, min(lane, max(50, round(lane * 0.9))) - 4)
    rows = max(1, console.height - 7)
    limit = inner * rows
    body = Text()

    def append(value, style=""):
        if value:
            if body:
                body.append("\n")
            # Streamed bytes are untrusted literal text, including unfinished escapes.
            value = re.sub(r"[\x00-\x08\x0b-\x1f\x7f-\x9f]", "", value[-limit:])
            body.append(value, style=style)

    append(message.additional_kwargs.get("reasoning_content"), "italic dim")
    append(message.text)
    for call in message.tool_call_chunks:
        append(f"{call['name'] or 'Tool call'} {call['args'] or ''}", "cyan")
    lines = body.wrap(console, inner)
    tail = Text("\n").join(lines[-rows:])
    return MessagePanel(tail, "✨ Clanker · streaming", "yellow", width)


class TurnDisplay:
    """Render transient model output and permanent execution boxes."""

    def __init__(self, console):
        self.console = console
        self.steering = None
        self.preview = None
        self.waiting = None

    def __enter__(self):
        return self

    def stop_waiting(self):
        if self.waiting is not None:
            self.waiting.stop()
            self.waiting = None

    def stop_preview(self):
        if self.preview is not None:
            self.preview.stop()
            self.preview = None
        if self.steering is not None:
            self.steering.preview = ""

    def __exit__(self, *error):
        self.stop_waiting()
        self.stop_preview()

    def __call__(self, event, payload):
        if event == "thinking":
            if self.waiting is None:
                self.waiting = self.console.status(
                    Text("Clanker is thinking…", style="dim")
                )
                self.waiting.start()
            return
        self.stop_waiting()
        if event == "assistant_partial":
            panel = partial_panel(payload, self.console)
            if self.steering is not None and not self.steering.exit_requested:
                with self.console.capture() as capture:
                    self.console.print(panel)
                self.steering.update_preview(capture.get())
            elif self.preview is None:
                self.preview = Live(
                    panel,
                    console=self.console,
                    transient=True,
                    auto_refresh=False,
                    redirect_stdout=False,
                    redirect_stderr=False,
                )
                self.preview.start(refresh=True)
            else:
                self.preview.update(panel, refresh=True)
            return
        self.stop_preview()
        if event == "assistant":
            # The final answer is rendered once on stdout by the alias.
            if payload.tool_calls and payload.text:
                self.console.print(assistant_panel(payload.text, self.console.width))
        elif event == "tool_start":
            self.console.print(
                tool_panel(
                    payload["call"],
                    payload["index"],
                    payload["total"],
                    self.console.width,
                )
            )
        elif event == "tool_result":
            self.console.print(tool_result_panel(payload, self.console.width))
        elif event == "assistant_intermediate":
            self.console.print(assistant_panel(payload.text, self.console.width))
        elif event == "steering_queued":
            count = len(payload)
            self.console.print(
                Text(
                    f"Queued {count} steering message{'s' if count != 1 else ''}.",
                    style="dim cyan",
                )
            )
