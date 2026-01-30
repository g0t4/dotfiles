#!/usr/bin/env fish

sudo timedatectl set-timezone 'America/Chicago'
sudo hostnamectl set-hostname 'foo'


# Define list of packages w/ rationale AIO in the comments
set -l packages "
  python3 python3-pip
  python3-pynvim # for wilder in vim
  nodejs # for github/copilot.vim
  eza # IIRC only newer debian/ubuntu versions have this?
  cargo # treeify

  # networking:
  avahi-utils  # mDNS
  httpie
  jq
  iputils-ping
  iproute2
  net-tools
  whois
  dnsutils
  nmap
  mtr-tiny # combines traceroute and ping, so not adding traceroute too?

  # tcpdump
  # wireshark
  # netcat
  # socat
"
set -l package_list (echo $packages | sed 's/#.*//' | rg -v "^\s*\$" | rg -v "^\s*#.*")
eval "sudo apt install $package_list"
# fish does not do variable expansion like bash, i.e. splitting on whitespace... so just build the commad to run and eval it

