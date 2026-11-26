import io

from rich.color import Color
from rich.console import Console

from wes.printing import print as print_module
from wes.printing.theme import wes_theme
from wes.syntax import load_style

def color_spec(hex_color: str) -> str:
    """The SGR truecolor spec for a #RRGGBB color, e.g. '38;2;172;208;149'."""
    channels = (int(hex_color[index : index + 2], 16) for index in (1, 3, 5))
    return "38;2;" + ";".join(str(channel) for channel in channels)


def themed_console(file) -> Console:
    """Like print_module's console, but forced to emit truecolor ANSI."""
    return Console(
        file=file,
        force_terminal=True,
        color_system="truecolor",
        theme=wes_theme(),
    )


def test_module_console_carries_wes_theme():
    colors, _ = load_style()
    style = print_module.console.get_style("repr.str")
    assert style.color == Color.parse(colors["string"])


def test_print_writes_to_stdout(capfd):
    print_module.print("hello from wes")
    assert "hello from wes" in capfd.readouterr().out


def test_print_dict_uses_wes_theme(monkeypatch):
    colors, _ = load_style()
    buffer = io.StringIO()
    monkeypatch.setattr(print_module, "console", themed_console(buffer))
    print_module.print({"key": 42, "flag": True, "nothing": None})
    output = buffer.getvalue()
    assert color_spec(colors["string"]) in output  # 'key', 'flag', 'nothing'
    assert color_spec(colors["number"]) in output  # 42
    assert color_spec(colors["builtin"]) in output  # True
    assert color_spec(colors["keyword"]) in output  # None


def test_markup_uses_palette_role_names(monkeypatch):
    colors, _ = load_style()
    buffer = io.StringIO()
    monkeypatch.setattr(print_module, "console", themed_console(buffer))
    print_module.print("[keyword]def[/keyword] [string]x[/string]")
    output = buffer.getvalue()
    assert color_spec(colors["keyword"]) in output
    assert color_spec(colors["string"]) in output


def test_print_supports_file_sep_end():
    buffer = io.StringIO()
    print_module.print("a", "b", file=buffer, sep="-", end="!")
    assert buffer.getvalue() == "a-b!"


def test_print_passes_through_console_kwargs(monkeypatch):
    buffer = io.StringIO()
    monkeypatch.setattr(print_module, "console", themed_console(buffer))
    print_module.print("styled", style="bold")
    assert "\x1b[1m" in buffer.getvalue()
