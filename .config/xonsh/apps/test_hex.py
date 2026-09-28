import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).parent))

from hex import char_tokens, parse_ansi  # noqa: E402


def kinds(segments):
    return [s.kind for s in segments]


def test_splits_text_and_csi():
    segments = parse_ansi(b"Hello\x1b[?25lWorld")
    assert kinds(segments) == ["text", "escape", "text"]
    assert segments[0].data == b"Hello"
    assert segments[1].data == b"\x1b[?25l"
    assert segments[2].data == b"World"


def test_osc_bel_terminated():
    segments = parse_ansi(b"x\x1b]7;file:///home/wes\x07y")
    assert kinds(segments) == ["text", "escape", "text"]
    assert segments[1].data == b"\x1b]7;file:///home/wes\x07"


def test_osc_st_terminated():
    segments = parse_ansi(b"\x1b]133;A\x1b\\")
    assert kinds(segments) == ["escape"]
    assert segments[0].data == b"\x1b]133;A\x1b\\"


def test_simple_esc():
    segments = parse_ansi(b"\x1b7")
    assert kinds(segments) == ["escape"]
    assert segments[0].data == b"\x1b7"


def test_csi_8bit():
    segments = parse_ansi(b"\x9b?25l")
    assert kinds(segments) == ["escape"]


def test_explain_cursor_shape():
    segment = parse_ansi(b"\x1b[2 q")[0]
    assert "steady block" in segment.explanation


def test_explain_hide_cursor():
    segment = parse_ansi(b"\x1b[?25l")[0]
    assert "cursor visibility" in segment.explanation
    assert "disabled" in segment.explanation


def test_explain_sgr():
    segment = parse_ansi(b"\x1b[1;31m")[0]
    assert "bold" in segment.explanation
    assert "red" in segment.explanation


def test_explain_osc_workdir():
    segment = parse_ansi(b"\x1b]7;file:///home/wes\x07")[0]
    assert "working directory" in segment.explanation
    assert "file:///home/wes" in segment.explanation


def test_explain_osc_shell_integration():
    segment = parse_ansi(b"\x1b]133;A\x1b\\")[0]
    assert "prompt start" in segment.explanation


def test_explain_osc_iterm_uservar():
    segment = parse_ansi(b"\x1b]1337;SetUserVar=foo=bar\x07")[0]
    assert "user variable" in segment.explanation


def test_explain_osc_hyperlink_params():
    segment = parse_ansi(b"\x1b]8;id=42;https://example.com\x07")[0]
    assert "link to 'https://example.com'" in segment.explanation
    assert "id=42" in segment.explanation


def test_explain_osc_52_clipboard():
    segment = parse_ansi(b"\x1b]52;c;SGVsbG8=\x07")[0]
    assert "clipboard" in segment.explanation
    assert "Hello" in segment.explanation


def test_cup_math():
    segment = parse_ansi(b"\x1b[12;34H")[0]
    assert "row 12" in segment.explanation
    assert "column 34" in segment.explanation


def test_cursor_move_count():
    segment = parse_ansi(b"\x1b[5A")[0]
    assert "up 5" in segment.explanation


def test_utf8_char_tokens():
    tokens = char_tokens("héllo".encode("utf-8"))
    assert [text for text, _ in tokens] == ["h", "é", "l", "l", "o"]
