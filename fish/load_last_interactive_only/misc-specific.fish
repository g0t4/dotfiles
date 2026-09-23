function use_nvim_from_source

    set repo "$HOME/repos/github/neovim/neovim"

    export PATH="$repo/build/bin:$PATH" # nvim source dir
    export MANPATH="$repo/build/share/man:$MANPATH" # man pages for neovim
    export VIMRUNTIME="$repo/runtime" # so we have all the vim scripts

end

# Shared abbreviations are defined in the Xonsh module and generated for Fish.
source $WES_DOTFILES/fish/generated/misc-abbreviations.fish

# These remain Fish-only.
abbr pPATH 'for p in $PATH; echo $p; end'
reminder_abbr date_unixtime "date +%s"

function which_versions --argument-names cmd
    for exec in (which -a $cmd)
        set -l version_output (eval $exec --version)
        if test $status -eq 0
            set ver $version_output
        else
            set ver (eval $exec -v)
        end
        # TODO ssh -V # no --version, nor -v => might want to build up list of known tools that don't use --version and -v

        echo "$exec: $ver"
    end
end

# *** Keyboard Maestro CLI ***
if test -x "/Applications/Keyboard Maestro.app/Contents/MacOS/keyboardmaestro"
    function km --description "Execute a Keyboard Maestro macro by name or UUID"
        # usage: km <macro-name-or-uuid> [-a] [-v] [-p value] [-e]
        # usage: km --list [--search pattern]

        if test (count $argv) -eq 0
            echo "Usage:" >&2
            echo "  km <macro-name-or-uuid> [-a] [-v] [-p value] [-e]" >&2
            echo "  km --list" >&2
            echo "" >&2
            echo "Options:" >&2
            echo "  -a, --async     Run asynchronously (don't wait for completion)" >&2
            echo "  -e, --edit      Edit mode (open in editor instead of running)" >&2
            echo "  -p, --parameter Pass value as the parameter to macro" >&2
            echo "  -v, --verbose   Verbose output" >&2
            echo "  -h, --help      Show this help message" >&2
            echo "" >&2
            echo "Commands:" >&2
            echo "  --list          List all macros (UUID|Name format)" >&2
            return 1
        end

        # Handle --list flag
        if test "$argv[1]" = --list
            set search_pattern ""
            if test (count $argv) -gt 1
                set search_pattern $argv[2]
            end

            # Write helper script to temp file
            set tmp_script (mktemp /tmp/km_list_XXXXXX.scpt)
            echo 'tell application "Keyboard Maestro"
    set output to ""
    repeat with m in every macro
        set output to output & (id of m) & "|" & (name of m) & "\n"
    end repeat
    return output
end tell' >$tmp_script

            # Execute the script - NO filtering, let user pipe to whatever they want
            osascript $tmp_script | string trim

            # Clean up
            rm -f $tmp_script

            return
        end

        # Handle --help flag
        if test "$argv[1]" = --help
            echo "Usage:"
            echo "  km <macro-name-or-uuid> [-a] [-v] [-p value] [-e]"
            echo "  km --list"
            echo ""
            echo "Options:"
            echo "  -a, --async     Run asynchronously (don't wait for completion)"
            echo "  -e, --edit      Edit mode (open in editor instead of running)"
            echo "  -p, --parameter Pass value as the parameter to macro"
            echo "  -v, --verbose   Verbose output"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Commands:"
            echo "  --list          List all macros (UUID|Name format)"
            return
        end

        # Execute macro by name or UUID
        command /Applications/Keyboard\ Maestro.app/Contents/MacOS/keyboardmaestro $argv
    end
end

# * secure entry
function secure_entry_pids
    ioreg -l | awk -F'= ' /kCGSSessionSecureInputPID/ \
        | rg_grep -o "kCGSSessionSecureInputPID.=\d+" \
        | string replace --regex "^[^\d]+" "" \
        | uniq
end

function secure_entry_who
    # find what app enabled secure entry
    set -l pids (secure_entry_pids)
    if test (count $pids) -gt 0
        ps -p $pids -o pid,comm,args
    else
        echo "Secure Input not enabled."
    end
end
