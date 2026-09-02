import rich

# using ssh-agent for ssh key passphrases (for git repos push/pull)
if $IS_ARCH:
    if not "XDG_RUNTIME_DIR" in @.env:
        rich.print("[yellow]No XDG_RUNTIME_DIR set, cannot setup SSH_AUTH_SOCK[/]")
    else:
        # need to set socket env var:
        $SSH_AUTH_SOCK=f"{$XDG_RUNTIME_DIR}/ssh-agent.socket"

    # FYI one time must enable socket (for socket activation)
    # systemctl --user enable ssh-agent.socket
    #  then reboot OR start ssh-agent.socket
    #  then service will start when socket is accessed... i.e. ssh-add -l w/ SSH_AUTH_SOCK set as above

    def ssh_agent_status():
        # arch has ssh-agent.service OOB
        # * user service *
        systemctl --no-pager --user status 'ssh-agent*'

        echo
        echo
        import rich
        rich.print(f"""[bold]Your env has:[/]\n    SSH_AUTH_SOCK={$SSH_AUTH_SOCK}""")

        echo
        echo FYI:
        echo   `ssh-add -l` to list keys
        echo   `ssh-add ~/.ssh/path/to/id_foo` to add passphrase
        echo  OR use `AddKeysToAgent` in ssh config
