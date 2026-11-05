#!/bin/sh
set -eu
cd "$(dirname "$0")"
app="$HOME/Applications/Pip Rot.app"
state="$HOME/.local/state/pip-rot/previous-folder-handler"
if [ "${1:-}" = --restore-default ] || [ "${1:-}" = --uninstall ]; then
    if [ "$(duti -d public.folder)" = com.g0t4.pip-rot ]; then
        duti -s "$(cat "$state")" public.folder all
    fi
    if [ "$1" = --uninstall ]; then /opt/homebrew/bin/trash -F "$app"; fi
    exit
fi
uv pip install --python .venv/bin/python py2app==0.28.10 setuptools
mkdir -p build/pip-rot.iconset
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" assets/pip-rot.png --out "build/pip-rot.iconset/icon_${size}x${size}.png" >/dev/null
done
iconutil -c icns build/pip-rot.iconset -o assets/pip-rot.icns
root="$PWD"
mkdir -p build/app
(cd build/app; "$root/.venv/bin/python" "$root/setup_macos.py" py2app -A) >/tmp/pip-rot-build.log 2>&1
mkdir -p "$HOME/Applications" "$(dirname "$state")"
ditto 'build/app/dist/Pip Rot.app' "$app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
if [ ! -f "$state" ]; then duti -d public.folder > "$state"; fi
if [ "${1:-}" = --set-default ]; then
if ! duti -s com.g0t4.pip-rot public.folder all; then
    printf '%s\n' 'macOS rejected folder-default registration; existing default retained.' >&2
fi
fi
printf 'Installed %s\n' "$app"
