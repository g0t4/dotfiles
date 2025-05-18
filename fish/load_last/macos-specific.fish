if not $IS_MACOS
    # stop executing script, when sourced
    return
end

# FYI using command -q security is a very nice way to group config! even though this is macOS and it will always have the security command
if command -q security
    # consider securityfp (add p to end) for passwords
    #   do this when I start using security command for other credential types
    abbr --set-cursor securityf "security find-generic-password -w -s % -a "
    abbr --set-cursor securityrm "security delete-generic-password -s % -a "
    #
    # * add passwords
    # FYI -w truncates pasted passwords longer than 129 chars (maybe I am doing smth wrong?)
    # abbr --set-cursor securitya "security add-generic-password -U -s % -a -w "
    #
    # BUT, -X hexpassword     => this allows longer than 129, and I verified this works to set from clipboard (easier than pasting twice with -w):
    abbr --set-cursor securitya "security add-generic-password -U -X (pbpaste | xxd -p | tr -d '\n') -s % -a "
    # -U updates if already exists! (w/o this the add fails)

    # had ChatGPT do this based on man page of security cmd (since fish shell generated completions dont work for security subcommadns, just its options)
    #   man -P "col -b" security
    # Completions for the `security` command
    # TODO resume later, just a reminder to add these
    # FYI right now can tab complete subcommand names which is likely enough
    # Function to provide security subcommands
    function __fish_security_subcommands
        echo help list-keychains default-keychain login-keychain \
            create-keychain delete-keychain lock-keychain unlock-keychain \
            set-keychain-settings set-keychain-password show-keychain-info \
            dump-keychain create-keypair add-generic-password \
            add-internet-password add-certificates find-generic-password \
            delete-generic-password set-generic-password-partition-list \
            find-internet-password delete-internet-password \
            set-internet-password-partition-list find-key set-key-partition-list \
            find-certificate find-identity delete-certificate \
            delete-identity set-identity-preference get-identity-preference \
            create-db export import cms install-mds \
            add-trusted-cert remove-trusted-cert dump-trust-settings \
            user-trust-settings-enable trust-settings-export \
            trust-settings-import verify-cert authorize \
            authorizationdb execute-with-privileges leaks smartcards \
            list-smartcards export-smartcard error \
            | tr ' ' '\n'
    end

    # Add completions for each subcommand
    complete -c security -a "(__fish_security_subcommands)"

    # TODO chatgpt sugggested the following... but IIUC I just need to call complete multiple times and provide a desc for each subarg OR
    #  TODO lookup how __fish_seen_* helpers work.. if they can provide descriptions or not?
    ## Add descriptions for each specific subcommand
    #complete -c security -n '__fish_seen_subcommand_from help' -d "Show all commands, or usage for a command"
    #complete -c security -n '__fish_seen_subcommand_from list-keychains' -d "Display or manipulate the keychain search list"
    #complete -c security -n '__fish_seen_subcommand_from default-keychain' -d "Display or set the default keychain"
    #complete -c security -n '__fish_seen_subcommand_from login-keychain' -d "Display or set the login keychain"
    #complete -c security -n '__fish_seen_subcommand_from create-keychain' -d "Create keychains"
    #complete -c security -n '__fish_seen_subcommand_from delete-keychain' -d "Delete keychains and remove them from the search list"
    #complete -c security -n '__fish_seen_subcommand_from lock-keychain' -d "Lock the specified keychain"
    #complete -c security -n '__fish_seen_subcommand_from unlock-keychain' -d "Unlock the specified keychain"
    #complete -c security -n '__fish_seen_subcommand_from set-keychain-settings' -d "Set settings for a keychain"
    #complete -c security -n '__fish_seen_subcommand_from set-keychain-password' -d "Set password for a keychain"
    #complete -c security -n '__fish_seen_subcommand_from show-keychain-info' -d "Show the settings for keychain"
    #complete -c security -n '__fish_seen_subcommand_from dump-keychain' -d "Dump the contents of one or more keychains"
    #complete -c security -n '__fish_seen_subcommand_from create-keypair' -d "Create an asymmetric key pair"
    #complete -c security -n '__fish_seen_subcommand_from add-generic-password' -d "Add a generic password item"
    #complete -c security -n '__fish_seen_subcommand_from add-internet-password' -d "Add an internet password item"
    #complete -c security -n '__fish_seen_subcommand_from add-certificates' -d "Add certificates to a keychain"
    #complete -c security -n '__fish_seen_subcommand_from find-generic-password' -d "Find a generic password item"
    #complete -c security -n '__fish_seen_subcommand_from delete-generic-password' -d "Delete a generic password item"
    #complete -c security -n '__fish_seen_subcommand_from set-generic-password-partition-list' -d "Set the partition list of a generic password item"
    #complete -c security -n '__fish_seen_subcommand_from find-internet-password' -d "Find an internet password item"
    #complete -c security -n '__fish_seen_subcommand_from delete-internet-password' -d "Delete an internet password item"
    #complete -c security -n '__fish_seen_subcommand_from set-internet-password-partition-list' -d "Set the partition list of an internet password item"
    #complete -c security -n '__fish_seen_subcommand_from find-key' -d "Find keys in the keychain"
    #complete -c security -n '__fish_seen_subcommand_from set-key-partition-list' -d "Set the partition list of a key"
    #complete -c security -n '__fish_seen_subcommand_from find-certificate' -d "Find a certificate item"
    #complete -c security -n '__fish_seen_subcommand_from find-identity' -d "Find an identity (certificate + private key)"
    #complete -c security -n '__fish_seen_subcommand_from delete-certificate' -d "Delete a certificate from a keychain"
    #complete -c security -n '__fish_seen_subcommand_from delete-identity' -d "Delete a certificate and its private key from a keychain"
    #complete -c security -n '__fish_seen_subcommand_from set-identity-preference' -d "Set the preferred identity to use for a service"
    #complete -c security -n '__fish_seen_subcommand_from get-identity-preference' -d "Get the preferred identity to use for a service"
    #complete -c security -n '__fish_seen_subcommand_from create-db' -d "Create a db using the DL"
    #complete -c security -n '__fish_seen_subcommand_from export' -d "Export items from a keychain"
    #complete -c security -n '__fish_seen_subcommand_from import' -d "Import items into a keychain"
    #complete -c security -n '__fish_seen_subcommand_from cms' -d "Encode or decode CMS messages"
    #complete -c security -n '__fish_seen_subcommand_from install-mds' -d "Install (or re-install) the MDS database"
    #complete -c security -n '__fish_seen_subcommand_from add-trusted-cert' -d "Add trusted certificate(s)"
    #complete -c security -n '__fish_seen_subcommand_from remove-trusted-cert' -d "Remove trusted certificate(s)"
    #complete -c security -n '__fish_seen_subcommand_from dump-trust-settings' -d "Display contents of trust settings"
    #complete -c security -n '__fish_seen_subcommand_from user-trust-settings-enable' -d "Display or manipulate user-level trust settings"
    #complete -c security -n '__fish_seen_subcommand_from trust-settings-export' -d "Export trust settings"
    #complete -c security -n '__fish_seen_subcommand_from trust-settings-import' -d "Import trust settings"
    #complete -c security -n '__fish_seen_subcommand_from verify-cert' -d "Verify certificate(s)"
    #complete -c security -n '__fish_seen_subcommand_from authorize' -d "Perform authorization operations"
    #complete -c security -n '__fish_seen_subcommand_from authorizationdb' -d "Make changes to the authorization policy database"
    #complete -c security -n '__fish_seen_subcommand_from execute-with-privileges' -d "Execute tool with privileges"
    #complete -c security -n '__fish_seen_subcommand_from leaks' -d "Run /usr/bin/leaks on this process"
    #complete -c security -n '__fish_seen_subcommand_from smartcards' -d "Enable, disable or list disabled smartcard tokens"
    #complete -c security -n '__fish_seen_subcommand_from list-smartcards' -d "Display available smartcards"
    #complete -c security -n '__fish_seen_subcommand_from export-smartcard' -d "Export/display items from a smartcard"
    #complete -c security -n '__fish_seen_subcommand_from error' -d "Display a descriptive message for the given error code(s)"

end


