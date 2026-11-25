# color_shifter

An interactive terminal color shifter for a list of colors. Nudge lightness
and saturation with the arrow keys; each color is rendered in its own
foreground color so you see the change live.

Built-in defaults: `IN_HUE` (`#acadcf`) and `OUT_HUE` (`#cfacb4`). Pass hex
colors as CLI args to shift them too — they are listed first:

```sh
color_shifter                 # builtin colors only
color_shifter 61AFEF          # builtin + ARG_1 (#61afef)
color_shifter 61AFEF 458588   # builtin + ARG_1, ARG_2
```

## Controls

| Key     | Action                          |
| ------- | ------------------------------- |
| ↑ / ↓   | lightness ±step                 |
| ← / →   | saturation ±step                |
| Tab / t | cycle to next color             |
| 1-9     | select the Nth color            |
| s       | toggle step (10% ↔ 5%)          |
| [ / ]   | step -1 / +1 (1..100)           |
| r       | reset selected color to default |
| q       | quit (prints final hex values)  |

## Where it lives

Source: `tools/color_shifter/`. Stdlib only (`colorsys`, `termios`, `tty`).
Run it with the repo `.venv`:

```sh
.venv/bin/python3 tools/color_shifter/color_shifter.py 61AFEF
```

The Xonsh alias `color_shifter` is registered in
`.config/xonsh/rc.d/python-specific.xsh` and launches directly so the
interactive loop keeps the real TTY in raw mode.
