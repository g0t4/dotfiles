# Clanker Code

A separately named fork of the installed SauceCodePro Nerd Font family. The
original font files remain untouched. All 14 weights/styles retain their existing
characters and advances; the fork adds two private-use glyphs, U+F8E0 and U+F8E1.
Together they display `assets/clanker-mode.png` across two terminal columns.

The glyphs embed PNG tiles in an OpenType `sbix` table at nine sizes, from 16 to
256 pixels per em. Native macOS rendering supports the color images. Other
terminal renderers may differ. Each character occupies one column; keep the pair
together when copying the prompt. The image background is part of the avatar.

Build and install from the dotfiles root:

```sh
uv run tools/clanker_mode/build_font.py --install
```

The script reads `~/Library/Fonts/SauceCodeProNerdFont-*.ttf`, writes generated
fonts to the ignored `font-build/` directory, and installs copies into
`~/Library/Fonts/`. Use `--source` and `--output` to override those paths. Source
font copyright and SIL Open Font License metadata are retained in the fork;
family and PostScript names are changed to Clanker Code.

Select **Clanker Code Regular** in iTerm's profile Text settings, keeping your
preferred size. It uses PostScript name `ClankerCode-Regular`. The initial setup
updated the default profile and sessions using `SauceCodeProNF`, preserving each
size. Their old values are saved locally in `font-build/iterm-font-before.json`.

Restart Xonsh to load the new Clanker prompt. Later Markdown instruction changes
still reload each turn without restarting.

To roll back, select **SauceCodePro Nerd Font** again (PostScript name
`SauceCodeProNF`), and replace `\uf8e0\uf8e1` in the Clanker prompt with `🐷🖕`.
Installed fork files are named `~/Library/Fonts/ClankerCode-*.ttf`.
