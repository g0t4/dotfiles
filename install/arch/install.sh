# arch linux

# gonna leave notes here, not intended to be run automatically (not yet)

# initial setup (-S == --sync) - when arch-chroot'ed into new pacstrap'd mount
pacman -S grub efibootmgr openssh networkmanager
# pacstrap'd => pacman -S base linux linux-kernel? # todo find the ones I used w/ pacstrap
# IIRC => pacstrap w/ base (and a few others, go grab command I used to find explicit ones)

# https://wiki.archlinux.org/title/Pacman
# pkg search: https://archlinux.org/packages

# *** list files:
pacman -Ql fish # list of files installed (IIUC for local installed packages)
pacman -Fl fish # for remote packages
pacman -Qk fish # verify installed files

# *** search packages by file/command
pacman -Qo fish /path/to/file # find package for an installed file
pacman -Qo ip                 # owned by iproute2
pacman -Fy                    # sync files database (for searching)
pacman -F /path/to/file       # find file in remote package (i.e. not yet installed)
pacman -F pactree             # used to find pactree => extra/pacman-contrib

# *** explicit/implicit packages
pacman -Qdt # orphans (not explicitly installed, also no longer a dep of another package)
pacman -Qet # explicit installed packages (not required as deps of another package)

pactree fish # list deps tree

# -R == --remove
# -U == --upgrade

# others (FYI if already installed, will reinstall)
# --needed => don't reinstall
pacman --needed --noconfirm -S tree less neovim \
    python which pacman-contrib extra/python-pip \
    eza jq httpie nmap sudo git bat wget

# TODOs:
#  pynvim?

# fish
pacman -S fish
chsh -s /usr/bin/fish
# logout/in to create ~/.config/fish/ dir/files (before symlink below)

# not avail, install from src:
# icdiff

git clone https://github.com/g0t4/dotfiles ~/repos/github/g0t4/dotfiles
. ~/repos/github/g0t4/dotfiles/install/symlinks.fish
#  FYI symlinks dotfiles fish.config

# installs fish plugins (i.e. z)
#   AND osc for copy over ssh :)
. ~/repos/github/g0t4/dotfiles/fish/install/install.fish

