import pytest

from color_shifter import (
    COLORS,
    Color,
    clamp,
    hex_to_hsl,
    hsl_to_hex,
    parse_cli_colors,
)


def test_parse_cli_colors_empty():
    assert parse_cli_colors([]) == []


def test_parse_cli_colors_six_digit():
    assert parse_cli_colors(["61AFEF"]) == [("ARG_1", "#61afef")]


def test_parse_cli_colors_multiple_and_3digit():
    assert parse_cli_colors(["#abc", "ABC", "123456"]) == [
        ("ARG_1", "#aabbcc"),
        ("ARG_2", "#aabbcc"),
        ("ARG_3", "#123456"),
    ]


def test_parse_cli_colors_invalid_exits():
    with pytest.raises(SystemExit) as excinfo:
        parse_cli_colors(["zz"])
    assert excinfo.value.code == 1


def test_builtin_colors_have_valid_hex():
    for name, default in COLORS:
        assert default.startswith("#")
        assert len(default) == 7


def test_hsl_roundtrip():
    h, s, l = hex_to_hsl("#acadcf")
    assert hsl_to_hex(h, s, l) == "#acadcf"


def test_color_reset():
    color = Color("TEST", "#ffffff")
    color.l = 50
    color.reset()
    assert color.hex() == "#ffffff"


def test_clamp():
    assert clamp(-5) == 0
    assert clamp(105) == 100
    assert clamp(42.4) == 42
