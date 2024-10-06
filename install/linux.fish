
#!/usr/bin/env fish

sudo timedatectl set-timezone 'America/Chicago'
sudo hostnamectl set-hostname 'foo'

sudo apt install -y python3 python3-pip

# node for github/copilot.vim
# pynvim for wilder in vim
sudo apt install -y python3-pynvim nodejs

