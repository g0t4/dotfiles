ealias trace='traceroute -n'
ealias trace1='traceroute -n 1.1.1.1'
ealias tr6='traceroute -n -6'

ealias ping='ping -d'
ealias ping1='ping -d 1.1.1.1'
ealias ping8='ping -d 8.8.8.8'
_default_gateway() {
    route -n get default | awk '/gateway/ {print $2}'
}
ealias pingd='ping -d $(_default_gateway)' # (d)efault gateway
ealias p6='ping -d -6'

# *** what is my ip ***
_my_ip4() {
    curl --fail-with-body -sSL 'https://api.ipify.org?format=raw'
}
_my_ip6() {
    curl --fail-with-body -sSL 'https://api64.ipify.org?format=raw'
}
#
# FYI alternate API with more details
# - https://ip-api.com/docs
# - curl ip-api.com => json with geo location, IP etc

# *** SSH ***

function _ssh_exit_all_sockets() {
  for socket in ~/.ssh/sockets/*; do
    ssh -O exit -S "$socket" dummyuser@dummyhost
  done
}
