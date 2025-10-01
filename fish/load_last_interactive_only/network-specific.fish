abbr trace 'traceroute -n'
abbr trace1 'traceroute -n 1.1.1.1'
abbr tr6 'traceroute -n -6'

abbr ping1 'ping -d 1.1.1.1'
abbr ping8 'ping -d 8.8.8.8'
function _default_gateway
    route -n get default | awk '/gateway/ {print $2}'
end
abbr pingd 'ping -d $(_default_gateway)' # (d)efault gateway
abbr p6 'ping -d -6'

# *** what is my ip ***
function _my_ip4
    curl --fail-with-body -sSL 'https://api.ipify.org?format=raw'
end
function _my_ip6
    curl --fail-with-body -sSL 'https://api64.ipify.org?format=raw'
end
#
# FYI alternate API with more details
# - https://ip-api.com/docs
# - curl ip-api.com => json with geo location, IP etc

# *** SSH ***

function _ssh_exit_all_sockets
    for socket in ~/.ssh/sockets/*
        ssh -O exit -S "$socket" dummyuser@dummyhost
    end
end
