[[ -n "$WES_TRACE_STARTUP" ]] && (IFS="<" echo "sourcing ${BASH_SOURCE[*]}")

# ! KEEP THIS FILE MINIMAL, only critical, early config should be in here

echo WARNING THIS IS YOUR FULL BASHRC

source "$BASH_DOTFILES/shared.bashrc.sh"

for script in "$BASH_DOTFILES/startup/full-only/"*.bash; do
    source "$script"
done

# would be interesting to get this working fully with abbr:
#   https://github.com/akinomyoga/ble.sh
#   just a few issues with how spaces trigger but otherwise looks ok:
