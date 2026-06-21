#
# * ssh-agent
# using ssh-agent for ssh key passphrases (for git repos push/pull)
if $IS_ARCH
    # need to set socket env var:
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

    # FYI one time must enable socket (for socket activation)
    # systemctl --user enable ssh-agent.socket
    #  then reboot OR start ssh-agent.socket
    #  then service will start when socket is accessed... i.e. ssh-add -l w/ SSH_AUTH_SOCK set as above

    function ssh_agent_status
        # arch has ssh-agent.service OOB
        # * user service *
        systemctl --user status ssh-agent.service ssh-agent.socket

        echo FYI:
        echo   `ssh-add -l` to list keys
        echo   `ssh-add ~/.ssh/path/to/id_foo` to add passphrase
        echo  OR use `AddKeysToAgent` in ssh config
    end

end

