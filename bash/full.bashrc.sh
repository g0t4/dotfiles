[[ -n "$WES_TRACE_STARTUP" ]] && (IFS="<" echo "sourcing ${BASH_SOURCE[*]}")

# ! KEEP THIS FILE MINIMAL, only critical, early config should be in here

echo WARNING THIS IS YOUR FULL BASHRC

source "$BASH_DOTFILES/shared.bashrc.sh"

source "$BASH_DOTFILES/.generated.abbrs.bash"

for script in "$BASH_DOTFILES/startup/full-only/"*.bash; do
    source "$script"
done
