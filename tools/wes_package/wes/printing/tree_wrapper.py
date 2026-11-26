import traceback
import os
import rich
from rich.console import RenderableType, Console
from rich.style import Style, StyleType
from rich.syntax import Syntax
from rich.padding import Padding
from rich.live import Live
from rich.text import Text
from rich.tree import Tree
from rich.pretty import Pretty
from rich.markup import escape
from rich.markdown import Markdown

import json
import sys
import asyncio
from typing import Any, List, Optional

class TreeWrapper(Tree):
    """ Thin wrapper around :class:`rich.tree.Tree` with additional helpers. """

    parent: "TreeWrapper | None" = None

    @staticmethod
    def hidden_root():
        return TreeWrapper("", hide_root=True)

    def __init__(
        self,
        label: RenderableType | None = None,
        parent: "TreeWrapper | None" = None,
        style: StyleType = "tree",
        guide_style: StyleType = "tree.line",
        expanded: bool = True,
        highlight: bool = False,
        hide_root: bool = False,
    ) -> None:
        # parent specific config:
        self.label = label or ""
        self.style = style
        self.guide_style = guide_style
        self.children: List[Tree] = []
        self.expanded = expanded
        self.highlight = highlight
        self.hide_root = hide_root
        #
        self.parent = parent
        self.TREE_GUIDES = [("    ", "    ", "    ", "    ")]

    def blank_line(self) -> None:
        BLANK_LINE = ""

        if not self.children:
            self.add_no_markup(BLANK_LINE)
            return

        last = self.children[-1]
        label = last.label
        if isinstance(label, Text):
            ends_newline = label.plain.endswith("\n")
        else:
            ends_newline = isinstance(label, str) and label.endswith("\n")
        if not ends_newline:
            self.add_no_markup(BLANK_LINE)

    def add(
        self,
        label: RenderableType | None = None,
        *,
        style: Optional[StyleType] = None,
        guide_style: Optional[StyleType] = None,
        expanded: bool = True,
        highlight: Optional[bool] = False,
    ) -> "TreeWrapper":
        """Add a child tree.

        Args:
            label (RenderableType): The renderable or str for the tree label.
            style (StyleType, optional): Style of this tree. Defaults to "tree".
            guide_style (StyleType, optional): Style of the guide lines. Defaults to "tree.line".
            expanded (bool, optional): Also display children. Defaults to True.
            highlight (Optional[bool], optional): Highlight renderable (if str). Defaults to False.

        Returns:
            Tree: A new child Tree, which may be further modified.
        """
        node = TreeWrapper(
            label,
            style=self.style if style is None else style,
            guide_style=self.guide_style if guide_style is None else guide_style,
            expanded=expanded,
            highlight=self.highlight if highlight is None else highlight,
        )
        self.children.append(node)
        return node

    def add_no_markup(self, text: str, **kwargs) -> "TreeWrapper":
        """ make explicit this content should not have markup rendered """
        # btw Text == plain unless you pass a style arg
        return self.add(Text(text), **kwargs)

    def add_with_markup(self, label: str, **kwargs) -> "TreeWrapper":
        """ this is purely for readability, to make it clear that the content should have markup rendered """
        return self.add(label, **kwargs)

    def add_pretty(self, obj: Any, **kwargs) -> "TreeWrapper":
        return self.add(Pretty(obj), **kwargs)

    def add_syntax(self, code: str, lexer: str, *, theme: str = "monokai", **kwargs) -> "TreeWrapper":
        return self.add(Syntax(code, lexer, theme=theme), **kwargs)

    def list_json_key_value_pairs(self, json_str: str, **kwargs) -> "TreeWrapper":
        try:
            obj = json.loads(json_str)
        except json.JSONDecodeError as error:
            # Show the error and raw content in the tree
            self.add_error("failed to load JSON result", error) \
                .add_no_markup(json_str)
            return self

        self.list_key_value_pairs(obj)
        return self

    def list_key_value_pairs(self, obj):
        # FYI basically I want a JSON like dump with leading and trailing { and } which waste space...
        for key, value in obj.items():

            if value is None or isinstance(value, (str, int, float, bool)):
                # single line => key: value
                display = Text.from_markup(f"[blue]{key}:[/] ") + Text(str(value))
                self.add(display)
                continue

            display = Text.from_markup(f"[blue]{key}:[/]")
            # * dict/list
            self.add(display).add_pretty(value)

        return self

    def show_truncated_string(self, text: str):
        lines = text.splitlines()
        max_lines = 5
        if len(lines) > max_lines:
            initial = "\n".join(lines[:max_lines])
            truncated_lines = len(lines) - max_lines
            truncated_chars = len(text) - len(initial)  # total chars - shown chars
            truncated_indicator = f"... ({truncated_lines} lines, {truncated_chars} chars)"
            # PRN truncate on char count too? really long lines of output can be a problem too (measure length of first X lines and if super long then take char_max too... else maybe allow more lines than I do now within reason)
            self.add_no_markup(initial)
            self.add_with_markup(f"[bold yellow]{truncated_indicator}[/]")
        else:
            self.add_no_markup(text)

    def add_section(self, title: str, value: Any):
        section = self.add_with_markup(f"[blue]{title}[/]:")
        if isinstance(value, str):
            section.show_truncated_string(value)
        else:
            section.add_no_markup(str(value))

    def remove_self(self):
        if self.parent:
            try:
                self.parent.children.remove(self)
            except ValueError as error:
                # ? do I want to see this failure, ever?
                self.add_error("unexpected, failed to remove self", error)
            self.parent = None
        return self

    def add_error(self, message: str, error: Exception, context: Any | None = None) -> "TreeWrapper":
        node = self.add_with_markup(f"[red bold]{message}[/]")
        node.add_pretty(error)
        node.add_no_markup(traceback.format_exc())
        return node
