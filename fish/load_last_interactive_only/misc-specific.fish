function use_nvim_from_source

    set repo "$HOME/repos/github/neovim/neovim"

    export PATH="$repo/build/bin:$PATH" # nvim source dir
    export MANPATH="$repo/build/share/man:$MANPATH" # man pages for neovim
    export VIMRUNTIME="$repo/runtime" # so we have all the vim scripts

end

# * rsync
# key args...
# --dry-run/-n
#   --list-only (implied if no destination dir):
abbr rsync_list_only_source_files rsync --recursive --dry-run .
# --verbose (-v),
# --archive (-a == -Dgloprt)
#   --group/-g - set group on dest
#   --links/-l - tx symbolic links
#   --owner/-o - set owner on dest
#   -p - set perms on dest
#   -r - --recursive/-r
#   -t - set mod-times
# --dirs/-d (instead of --recursive, copy dirs... need trailing slash/ or . to copy dir contents too)
# --checksum (-c) - compare checksum, instead of quick check (file size / mod-time)
# --compress/-z - during tx
# --delete (with -r only)
# --exclude/--include
# --extended-attributes - macos specific
# --force
# --fuzzy/-y - look for files that might be the same
# --ignore-existing
#   --ingnore-non-existing/--existing
# --quiet/-q - only print errors
# --progress - print periodic updates
#   --stats - at end
#
# FYI! always use trailing slash... so its always contents of foo/ to contents bar/ dir
#
# most or all of my abbrs should have --dry-run at the end, I can easily remove it when ready
# FYI if copied smth already with say macos... use --recurisve (instead of --archive which also has --recursive) ... that way you only compare the file contents and not owner/group/mod-time/perms too
# quick = default size/mod-time check
abbr rsync_quick rsync --archive --delete --progress --stats --dry-run
abbr rsync_quick_dry_run rsync --archive --delete --itemize-changes --dry-run
# checksum = compare contents
abbr rsync_checksum rsync --archive --delete --checksum --progress --stats --dry-run
abbr rsync_checksum_dry_run rsync --archive --delete --checksum --itemize-changes --stats --dry-run
# FYI add _dry_run b/c w/ dry-run I want --itemize-changes output... whereas w/ a real copy I want --progress...
#   that said, all have --dry-run just to be safe on end

# * string abbrs
#
# pipe => string split
# FYI won't tab complete, except in command position... so just drop | and see if I like that way?
abbr strs_lines "string split '\n'"
abbr strs_comma "string split ','"
abbr strs_space "string split ' '"
abbr strs_tab "string split '\t'"
abbr strs_colon "string split ':'"
abbr strs_pipe "string split '|'"
#
abbr strjoin_lines "string join '\n'"
#
#
# string match short => long options
#   btw cannot tie to subcommand, only top level command `string`
#   only include options I regularly use
#   btw use a dynamic expansion to qualify overlapping subcommand options
#   ... i.e. string match has `-n/--index` vs string split has `-n/--no-empty`
abbr --command string -- -a --all
abbr --command string -- -q --quiet
abbr --command string -- -r --regex
abbr --command string -- -v --invert

# * BASH

# abbr b bash
# #
# # FYI these alternate bash invocations are mostly for test/demo purposes
# #   only material diff is the env vars passed
# #   99% of the time it's ok to just use `bash` from fish shell... and inherit the env
# #     also ok to not use --login on these too as my startup files don't differentiate
# #
# abbr bash_full_rc 'bash --rcfile "$WES_DOTFILES/bash/full.bashrc.sh"'
# abbr bash_env_no_inherit "env -i HOME=$HOME \$(which bash)"
# abbr bash_env_no_inherit_no_startup "env -i HOME=$HOME \$(which bash) --noprofile --norc"
# function bash_env_iterm_inherit_without_path
#     # restrict env vars inherited..
#     # mostly to ensure my bashrc can run independent of parent fish shell's env vars
#     # skip PATH so I know its setup consistently
#     env -i \
#         LANG="$LANG" \
#         TERM="$TERM" \
#         COLORTERM="$COLORTERM" \
#         SHELL="$SHELL" \
#         USER="$USER" \
#         LOGNAME="$LOGNAME" \
#         TMPDIR="$TMPDIR" \
#         HOME="$HOME" \
#         SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
#         DISPLAY="$DISPLAY" \
#         TERM_PROGRAM="$TERM_PROGRAM" \
#         TERM_PROGRAM_VERSION="$TERM_PROGRAM_VERSION" \
#         LC_TERMINAL="$LC_TERMINAL" \
#         LC_TERMINAL_VERSION="$LC_TERMINAL_VERSION" \
#         __CF_USER_TEXT_ENCODING="$__CF_USER_TEXT_ENCODING" \
#         "$(which bash)" \
#         $argv
# end
#
# abbr bash_abbr_tests "ABBR_TESTS=1 bash"
# abbr bash_abbr_tests_debug "ABBR_TESTS=1 ABBR_DEBUG=1 bash"
# #
# abbr bash_startup_trace 'PS4="+ \${BASH_SOURCE}:\${LINENO}: " bash -x -l'

# * strace
# --trace=syscall
# --trace=/regex_syscall
# categories
abbr --set-cursor strace_process "strace -f -e trace=process bash"
abbr --set-cursor strace_file "strace -f -e trace=file bash"
abbr --set-cursor strace_network "strace -f -e trace=network bash"
abbr --set-cursor strace_signal "strace -f -e trace=signal bash"
abbr --set-cursor strace_desc "strace -f -e trace=desc bash"
abbr --set-cursor strace_ipc "strace -f -e trace=ipc bash"
abbr --set-cursor strace_memory "strace -f -e trace=memory bash"
abbr --set-cursor strace_all "strace -f -e trace=all bash"
# fds=
abbr --set-cursor strace_fds "strace -f -e fds=0,1,2 bash"
abbr --set-cursor strace_fdSTDIN "strace -f -e fds=0 bash"
abbr --set-cursor strace_fdSTDOUT "strace -f -e fds=1 bash"
abbr --set-cursor strace_fdSTDERR "strace -f -e fds=2 bash"
# use fdSTDERR to see where the shell writes the prompt!
#
# syscalls / regex
abbr --set-cursor strace_open "strace -f -e trace=/open bash"
abbr --set-cursor strace_read "strace -f -e trace=/read bash"
abbr --set-cursor strace_write "strace -f -e trace=/write bash"
#
# count / summary
abbr --set-cursor stracec "strace -c -e trace=all sleep 1"
abbr --set-cursor straceC "strace -C -e trace=all sleep 1"

# *** fish
abbr --set-cursor -- fishc "fish -c '%'"
abbr pPATH 'for p in $PATH; echo $p; end'

abbr date_s "date +%s"
reminder_abbr date_unixtime "date +%s" # reminder abbr

## general cd
abbr cdr 'cd "$(_repo_root)"' # * favorite

## open
abbr orr 'open "$(_repo_root)"' # can't use `or` in fish :)
abbr oh 'open .'

####### vscode aliases:
abbr ch 'code .' # * favorite
abbr cih 'code-insiders .'
abbr cr 'code "$(_repo_root)"' # * favorite
abbr cir 'code-insiders "$(_repo_root)"'
## adv
abbr cie 'code --inspect-extensions=9229 .' # attach then with devtools, mostly adding this so I remember it
abbr cieb 'code --inspect-brk-extensions=9229 .' # attach, set breakpoints, then run!

# #### zed
# abbr zh 'zed .'
# abbr zr 'zed "$(_repo_root)"'
# abbr zph 'zed-preview .'
# abbr zpr 'zed-preview "$(_repo_root)"'

### cursor
abbr cs 'cursor .'
abbr csr 'cursor "$(_repo_root)"'

# z
abbr zx 'z -x'

# tar:
abbr tarx 'tar -xf' # e(x)tract
abbr tarx_stdout 'tar -O -xf' # e(x)tract to std(O)ut
abbr tart 'tar -tf' # lis(t) / (t)est
abbr tarc 'tar --xz -cf' # create xz (todo use set-position to put cursor in name that already has .txz extension)
abbr tarcg 'tar --gzip -cf' # create gzip (todo use set-position to put cursor in name that already has .tgz extension)
abbr tarcb 'tar --bzip2 -cf' # create bzip2 (todo use set-position to put cursor in name that already has .tbz2 extension)

# *** jar (zip)
abbr jarx 'jar -xf' # e(x)tract
abbr jart 'jar -tf' # lis(t) / (t)est
abbr --set-cursor -- jartree 'jar -tf %.jar | treeify'
abbr jaru 'jar -uf' # u(n)pack
abbr jarc 'jar -cf' # create
# TODO more based on jar/zip/unzip (FYI bsdtar supports zip, not gnu tar)

# *** unzip
abbr unzipx_stdout 'unzip -p' # e(x)tract to std(O)ut
abbr unzipl 'unzip -l' # lis(t) / (t)est
# TODO flesh out later, FYI use zip for create equivalaents
#   PRN make all these abbrs via zip and unzip? same set and just use respective command based on action? (unlike tar which has one command for all ops)


# *** line endings
# abbr trim_trailing_new_line 'truncate -s -1'
abbr trim_trailing_new_line 'perl -pe "chomp if eof" -i' # chomp removes \n which for EOF is blank line or last line if it has no \n on it... either way same net effect, trim it if present only!

# *** which
abbr whicha "which -a"
# show which versions I have installed
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
