import json

import pytest
from rich.color import Color
from rich.theme import Theme

from wes.print.theme import PALETTE_ROLES, wes_theme
from wes_syntax import load_style


def test_theme_is_a_rich_theme():
    assert isinstance(wes_theme(), Theme)


def test_palette_roles_are_exposed_as_theme_names():
    colors, _ = load_style()
    theme = wes_theme()
    for role in PALETTE_ROLES:
        assert theme.styles[role].color == Color.parse(colors[role])


def test_repr_styles_map_to_palette_roles():
    colors, _ = load_style()
    theme = wes_theme()
    assert theme.styles["repr.str"].color == Color.parse(colors["string"])
    assert theme.styles["repr.number"].color == Color.parse(colors["number"])
    assert theme.styles["repr.number"].bold
    assert theme.styles["repr.bool_true"].color == Color.parse(colors["builtin"])
    assert theme.styles["repr.bool_true"].italic
    assert theme.styles["repr.none"].color == Color.parse(colors["keyword"])
    assert theme.styles["repr.none"].italic
    assert theme.styles["repr.brace"].color == Color.parse(colors["punctuation"])


def test_unmapped_rich_names_fall_back_to_defaults():
    theme = wes_theme()
    assert theme.styles["bold"].bold
    assert "repr.comma" in theme.styles


def test_custom_palette_path_is_respected(tmp_path):
    colors, _ = load_style()
    custom = {**colors, "string": "#ff0000"}
    palette = tmp_path / "palette.json"
    palette.write_text(json.dumps(custom))
    themed = wes_theme(palette)
    assert themed.styles["string"].color == Color.parse("#ff0000")
    assert themed.styles["repr.str"].color == Color.parse("#ff0000")


def test_invalid_palette_raises(tmp_path):
    palette = tmp_path / "palette.json"
    palette.write_text(json.dumps({"background": "#1f2229"}))
    with pytest.raises(ValueError):
        wes_theme(palette)
