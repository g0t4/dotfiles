
uv tool install "xonsh[full]" --with-requirements ~/repos/github/g0t4/dotfiles/xonsh/requirements.txt

# stop using homebrew to install xonsh

# macos (requires old value to change to new value, hence `dscl -read UserShell`)
sudo dscl . -change /Users/$USER UserShell "$(dscl . -read /Users/$USER UserShell | awk '{print $2}')" "$HOME/.local/bin/xonsh"

# linux (todo)

# bypass `chsh` so you can use user installed xonsh and not need to modify /etc/shells to add it for every user
# sudo usermod -s "$HOME/.local/bin/xonsh" "$USER"
#
# FYI I am fine with xonsh via pacman for now... though it might be nice to use it via `uv` on linux machines too
# TODO migrate to uv tool install on linux machines?
