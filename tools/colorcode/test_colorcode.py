import pytest

from colorcode import Color, parse_color


def test_parse_hex():
    c = parse_color("c69676")
    assert c.hex == "#C69676"
    assert (c.red, c.green, c.blue) == (198, 150, 118)


def test_parse_full_hex_and_3digit():
    assert parse_color("#c69676").hex == "#C69676"
    assert parse_color("fff").hex == "#FFFFFF"


def test_parse_rgb_and_hsl_and_triple():
    assert parse_color("rgb(198, 150, 118)").hex == "#C69676"
    assert parse_color("198,150,118").hex == "#C69676"
    assert parse_color("hsl(24, 41%, 62%)").hex == "#C69676"


def test_invalid_hex_raises():
    with pytest.raises(ValueError):
        parse_color("zzzzzz")


def test_known_values_match_site():
    c = parse_color("c69676")
    assert c.hsl == (24, 41, 62)
    assert c.hwb == (24, 46, 22)
    assert c.xyz == (37, 35, 22)
    assert tuple(round(v) for v in c.lab) == (66, 14, 24)


def test_contrast_aaa():
    # black text on this color => ~8.03 (from the site's 8.02)
    ratio = parse_color("c69676").contrast_against(Color(0, 0, 0))
    assert 8.0 <= ratio <= 8.1


def test_sections_subset():
    assert parse_color("c69676").mixed_with(Color(255, 255, 255), 0.5).hex != "#000000"
