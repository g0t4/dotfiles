"""Shell scrollback for agent work, styled like the chat trace viewer."""

from typing import ClassVar

from rich.panel import Panel
from rich.pretty import Pretty
from rich.text import Text
from rich.tree import Tree
from wes_syntax import syntax


class ToolTree(Tree):
    # The viewer's TreeWrapper uses indentation without visible connector lines.
    TREE_GUIDES: ClassVar = [("    ", "    ", "    ", "    ")]


def message_panel(content, title, color, width):
    return Panel(
        content,
        title=Text(title, style=color),
        title_align="left",
        border_style=color,
        padding=(0, 1),
        width=max(1, round(width * 0.9)),
    )


def assistant_panel(answer, width):
    return message_panel(
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
    return message_panel(root, f"Tool call {index + 1}/{total}", "yellow", width)


def tool_result_panel(message, width):
    root = ToolTree(Text(message.name or "Tool result", style="bold"))
    # Tool output is literal data, never Rich markup or Markdown instructions.
    root.add(Text(str(message.content)))
    return message_panel(root, "🔧 Tool result", "red", width)


class TurnDisplay:
    """Only waiting is transient; execution boxes remain in shell history."""

    def __init__(self, console):
        self.console = console
        self.waiting = None

    def __enter__(self):
        return self

    def stop_waiting(self):
        if self.waiting is not None:
            self.waiting.stop()
            self.waiting = None

    def __exit__(self, *error):
        self.stop_waiting()

    def __call__(self, event, payload):
        if event == "thinking":
            if self.waiting is None:
                self.waiting = self.console.status(
                    Text("Clanker is thinking…", style="dim")
                )
                self.waiting.start()
            return
        self.stop_waiting()
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
