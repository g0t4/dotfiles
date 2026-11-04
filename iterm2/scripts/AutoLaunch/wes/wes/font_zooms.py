"""Fit coarse font zoom stops to the current pane's height.

Run this file with a Python environment containing iterm2 to print the current
pane's choices without changing its font. Gaps are in macOS points, not physical
pixels. This minimizes partial rows, not Neovim's command area or iTerm padding.
Restart the wes script from iTerm's Script Console after editing these modules.
"""

import asyncio
import json
import math
from enum import Enum

import iterm2

from common import get_current_session_throw_if_none, get_font_details, set_font_size
from logs import log
from timing import Timer

# Choose one size per band, favoring the smallest partial row for this pane.
# Bands preserve useful zoom steps without hardcoding sizes for one display/window.
FONT_BANDS = ((8, 10), (12, 14), (16, 18), (20, 22), (24, 26), (29, 32), (35, 38))
FALLBACK_STOPS = (8, 12, 16, 20, 24, 30, 36)
_running_wes_stops = False
_metrics_cache = {}


class MetricPreference(Enum):
    MARGIN = "TerminalVMargin"
    EXPERIMENTAL = "UseExperimentalFontMetrics"
    GENEROUS = "FontsForGenerousRounding"


# Mirrors PTYTextView.charSizeForFont / FontSizeEstimator in iTerm2:
# https://github.com/gnachman/iTerm2/blob/master/sources/TerminalView/PTYTextView.m
# Use AppKit's actual font metrics, not point size as a substitute for row height.
_FONT_METRICS_SCRIPT = r'''ObjC.import("AppKit");
function run(argv) {
    var args = JSON.parse(argv[0]), result = {};
    for (var size = 8; size <= 40; size++) {
        var font = $.NSFont.fontWithNameSize(args.name, size);
        if (!font) throw new Error("Unknown font: " + args.name);
        var family = ObjC.unwrap(font.familyName).toLowerCase();
        var generous = args.generous.toLowerCase().split(",").some(function (part) {
            return part.length > 0 && family.indexOf(part) >= 0;
        });
        var asc = Number(font.ascender), desc = Number(font.descender);
        var height = generous ? Math.ceil(asc) - Math.floor(desc) : asc - desc;
        result[size] = Math.ceil(Math.ceil(Math.max(1, height) + Number(font.leading)) * args.spacing);
    }
    return JSON.stringify(result);
}'''


async def font_row_heights(name, spacing, generous):
    key = (name, spacing, generous)
    if key not in _metrics_cache:
        process = await asyncio.create_subprocess_exec(
            "/usr/bin/osascript", "-l", "JavaScript", "-e", _FONT_METRICS_SCRIPT,
            json.dumps(dict(name=name, spacing=spacing, generous=generous)),
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        )
        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=5)
        except BaseException:
            process.kill()
            await process.wait()
            raise
        if process.returncode:
            raise RuntimeError(stderr.decode().strip())
        _metrics_cache[key] = {int(size): height for size, height in json.loads(stdout).items()}
    return _metrics_cache[key]


def fitted_stops(usable_height, heights):
    """Return (font size, leftover points) for each distinct zoom band."""
    if usable_height <= 0 or any(h <= 0 for h in heights.values()):
        raise ValueError("Invalid pane or row height")
    result = []
    for low, high in FONT_BANDS:
        center = (low + high) / 2
        candidates = [size for size in range(low, high + 1) if heights[size] <= usable_height]
        if candidates:
            size = min(candidates, key=lambda size: (usable_height % heights[size], abs(size - center), size))
            result.append((size, usable_height % heights[size]))
    return result


async def pane_zoom_stops(connection, session):
    profile = await session.async_get_profile()
    name, current_size = await get_font_details(session)
    margin, experimental, generous = await asyncio.gather(*(
        iterm2.preferences.async_get_preference(connection, key) for key in MetricPreference
    ))
    # Pane titles, status bars, composers, etc. can reduce the usable area.
    # Refuse a guessed layout if its predicted row count doesn't match live iTerm.
    if experimental:
        raise ValueError("Experimental iTerm font metrics are enabled")
    heights = await font_row_heights(name, profile.vertical_spacing or 1, generous if generous is not None else "consolas")
    height = session.frame.size.height - 2 * (margin if margin is not None else 2)
    if current_size not in heights or math.floor(height / heights[current_size]) != session.grid_size.height:
        raise ValueError("Pane chrome or font metrics don't match the live row count")
    stops = fitted_stops(height, heights)
    log(f"Zoom fit: pane={session.frame.size.width:g}x{session.frame.size.height:g} pt, "
        f"usable height={height:g} pt; " + ", ".join(f"{size}pt: {gap:g}pt remainder" for size, gap in stops))
    return [size for size, _ in stops]


async def change_font(connection, bigger):
    global _running_wes_stops
    if _running_wes_stops:
        log("Skipping overlapping font zoom request")
        return
    _running_wes_stops = True
    try:
        with Timer("bigger_font_wes_stops" if bigger else "smaller_font_wes_stops"):
            session = await get_current_session_throw_if_none(connection)
            app = await iterm2.async_get_app(connection)
            await app.async_refresh()
            _, current_size = await get_font_details(session)
            try:
                stops = await pane_zoom_stops(connection, session)
            except Exception as error:
                log(f"Zoom fit unavailable; using fallback stops: {error}")
                stops = FALLBACK_STOPS
            candidates = [size for size in stops if size > current_size] if bigger else [size for size in stops if size < current_size]
            # Never reverse direction at the ends, including manually selected sizes.
            if not candidates:
                return
            await set_font_size(session, min(candidates) if bigger else max(candidates))
        await nvim_equalize_windows(session)
    finally:
        _running_wes_stops = False


async def smaller_font_wes_stops(connection: iterm2.Connection):
    await change_font(connection, bigger=False)


async def bigger_font_wes_stops(connection: iterm2.Connection):
    await change_font(connection, bigger=True)


async def nvim_equalize_windows(session: iterm2.Session):
    if await session.async_get_variable("jobName") != "nvim":
        return
    await asyncio.sleep(0.2)
    await session.async_send_text('\x17=')  # CTRL-W_=


async def report_zoom_stops(connection):
    session = await get_current_session_throw_if_none(connection)
    await pane_zoom_stops(connection, session)


if __name__ == "__main__":
    iterm2.run_until_complete(report_zoom_stops)
