function help_online --description 'Show online help for the fish shell (fishshell.com/docs/current)'
    argparse -n help_online h/help -- $argv
    or return

    if set -q _flag_help
        __fish_print_help help
        return
    end

    # Mirror the stock help() page mapping.
    set -l fish_help_item (string replace -r -- '\b#$' '' "$argv[1]")
    set -l fish_help_page index.html
    if test -n "$fish_help_item"
        switch "$fish_help_item"
            case '!' ; set fish_help_page cmds/not.html
            case '.' ; set fish_help_page cmds/source.html
            case ':' ; set fish_help_page cmds/true.html
            case '[' ; set fish_help_page cmds/test.html
            case '{' ; set fish_help_page cmds/begin.html
            case '*' ; set fish_help_page cmds/$fish_help_item.html
        end
    end

    set -l url https://fishshell.com/docs/current/$fish_help_page
    if command -q open
        open $url
    else if command -q xdg-open
        xdg-open $url
    else
        printf '%s\n' "help_online: no browser found (need 'open' or 'xdg-open')" >&2
        return 1
    end
end
