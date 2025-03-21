# arch linux

# gonna leave notes here, not intended to be run automatically (not yet)

# initial setup (-S == --sync) - when arch-chroot'ed into new pacstrap'd mount
pacman -S grub efibootmgr openssh networkmanager
# pacstrap'd => pacman -S base linux linux-kernel? # todo find the ones I used w/ pacstrap
# IIRC => pacstrap w/ base (and a few others, go grab command I used to find explicit ones)

# https://wiki.archlinux.org/title/Pacman
# pkg search: https://archlinux.org/packages

# --needed => don't reinstall
pacman --needed --noconfirm -S tree less neovim \
    which pacman-contrib grc \
    python python-pip python-pipx uv \
    eza jq httpie nmap sudo git wget \
    bat hyperfine \
    ollama ollama-rocm \
    the_silver_searcher fd \
    base-devel cmake ffmpeg man-db \
    core/inetutils \
    nodejs npm \
    dmidecode docker iotop unzip sysstat htop

# dmidecode - bios info
# inetutils => hostname cmd
# sysstat => iostat

# FYI older python versions, use uv to install based on .python-version in a repo dir

pipx install icdiff

# fish
pacman -S fish
chsh -s /usr/bin/fish
# logout/in to create ~/.config/fish/ dir/files (before symlink below)

git clone https://github.com/g0t4/dotfiles ~/repos/github/g0t4/dotfiles
. ~/repos/github/g0t4/dotfiles/install/symlinks.fish
#  FYI symlinks dotfiles fish.config

# installs fish plugins (i.e. z)
#   AND osc for copy over ssh :)
. ~/repos/github/g0t4/dotfiles/fish/install/install.fish

# nvim dev checkouts (TODO why not configure this conditionally?)
git clone https://github.com/g0t4/ask-openai.nvim ~/repos/github/g0t4/ask-openai.nvim
git clone https://github.com/g0t4/illuminate.nvim ~/repos/github/g0t4/illuminate.nvim



# use rustup to install rust
sudo pacman --noconfirm -S rustup
# first needed for vllm deps
# https://rust-lang.github.io/rustup/installation/index.html
rustup install stable
rustup default stable


