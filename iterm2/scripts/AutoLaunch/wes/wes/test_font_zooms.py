"""Run with .venv/bin/pytest -q iterm2/scripts/AutoLaunch/wes/wes/test_font_zooms.py."""
import asyncio
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest

import font_zooms as zoom
from common import get_font_details


def test_stops_minimize_remainder_within_each_band():
    heights = {size: size + 4 for size in range(8, 41)}
    stops = zoom.fitted_stops(1059, heights)
    for (low, high), (size, gap) in zip(zoom.FONT_BANDS, stops):
        assert low <= size <= high
        assert gap == min(1059 % heights[candidate] for candidate in range(low, high + 1))
    assert all(b[0] - a[0] >= 2 for a, b in zip(stops, stops[1:]))
    assert stops != zoom.fitted_stops(2539, heights)


def test_stops_skip_fonts_that_cannot_fit_a_row():
    heights = {size: size + 4 for size in range(8, 41)}
    assert zoom.fitted_stops(11, heights) == []
    with pytest.raises(ValueError):
        zoom.fitted_stops(0, heights)


def test_fractional_existing_font_size():
    session = SimpleNamespace(async_get_profile=AsyncMock(return_value=SimpleNamespace(normal_font="Some Font 13.5")))
    assert asyncio.run(get_font_details(session)) == ("Some Font", 13.5)


@pytest.mark.parametrize("bigger,current,expected", [(True, 12, 18), (False, 18, 12), (True, 42, None), (False, 7, None)])
def test_zoom_direction_and_boundaries(monkeypatch, bigger, current, expected):
    session = object()
    monkeypatch.setattr(zoom, 'get_current_session_throw_if_none', AsyncMock(return_value=session))
    monkeypatch.setattr(zoom.iterm2, 'async_get_app', AsyncMock(return_value=SimpleNamespace(async_refresh=AsyncMock())))
    monkeypatch.setattr(zoom, 'get_font_details', AsyncMock(return_value=('Font', current)))
    monkeypatch.setattr(zoom, 'pane_zoom_stops', AsyncMock(return_value=[9, 12, 18, 21, 25, 31, 36]))
    setter = AsyncMock()
    equalizer = AsyncMock()
    monkeypatch.setattr(zoom, 'set_font_size', setter)
    monkeypatch.setattr(zoom, 'nvim_equalize_windows', equalizer)
    asyncio.run(zoom.change_font(None, bigger))
    if expected is None:
        setter.assert_not_awaited()
        equalizer.assert_not_awaited()
    else:
        setter.assert_awaited_once_with(session, expected)
        equalizer.assert_awaited_once_with(session)
    assert not zoom._running_wes_stops


def test_failed_zoom_releases_guard_and_uses_fallback(monkeypatch):
    session = object()
    monkeypatch.setattr(zoom, 'get_current_session_throw_if_none', AsyncMock(return_value=session))
    monkeypatch.setattr(zoom.iterm2, 'async_get_app', AsyncMock(return_value=SimpleNamespace(async_refresh=AsyncMock())))
    monkeypatch.setattr(zoom, 'get_font_details', AsyncMock(return_value=('Font', 12)))
    monkeypatch.setattr(zoom, 'pane_zoom_stops', AsyncMock(side_effect=ValueError('unsupported chrome')))
    setter = AsyncMock(side_effect=RuntimeError('disconnected'))
    monkeypatch.setattr(zoom, 'set_font_size', setter)
    with pytest.raises(RuntimeError, match='disconnected'):
        asyncio.run(zoom.change_font(None, True))
    setter.assert_awaited_once_with(session, 16)
    assert not zoom._running_wes_stops


def test_overlap_does_not_start_a_second_request(monkeypatch):
    monkeypatch.setattr(zoom, '_running_wes_stops', True)
    getter = AsyncMock()
    monkeypatch.setattr(zoom, 'get_current_session_throw_if_none', getter)
    asyncio.run(zoom.change_font(None, True))
    getter.assert_not_awaited()


def test_layout_mismatch_rejects_optimization(monkeypatch):
    profile = SimpleNamespace(vertical_spacing=1)
    session = SimpleNamespace(
        async_get_profile=AsyncMock(return_value=profile),
        frame=SimpleNamespace(size=SimpleNamespace(height=1059)),
        grid_size=SimpleNamespace(height=60),  # Not floor(1059 / 16).
    )
    monkeypatch.setattr(zoom, 'get_font_details', AsyncMock(return_value=('Font', 12)))
    monkeypatch.setattr(zoom.iterm2.preferences, 'async_get_preference', AsyncMock(return_value=0))
    monkeypatch.setattr(zoom, 'font_row_heights', AsyncMock(return_value={12: 16}))
    with pytest.raises(ValueError, match='live row count'):
        asyncio.run(zoom.pane_zoom_stops(None, session))
