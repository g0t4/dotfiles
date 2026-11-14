#!/bin/sh
# Install a live-checkout app, like Pip Rot. Does not change default file handlers.
set -eu
cd "$(dirname "$0")"
app="$HOME/Applications/Slop Reel.app"
env -u VIRTUAL_ENV uv sync --group macos
.venv/bin/python build_icon.py
root="$PWD"
mkdir -p build/app
log="$root/build/install-macos.log"
if ! (cd build/app && "$root/.venv/bin/python" "$root/setup_macos.py" py2app -A) >"$log" 2>&1; then
    cat "$log" >&2
    exit 1
fi
mkdir -p "$HOME/Applications"
ditto 'build/app/dist/Slop Reel.app' "$app"
printf 'Installed %s\n' "$app"
if ! /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"; then
    printf '%s\n' 'App built and copied, but macOS registration failed. Run this installer again from your desktop terminal before using Finder/Open With.' >&2
    exit 1
fi
