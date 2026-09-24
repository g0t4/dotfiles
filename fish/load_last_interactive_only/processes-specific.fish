# *** searching ***
#
abbr els "env | bat --language dotenv -p"
abbr egr "env | rg_grep -i "
abbr envb "env | bat -l env" # do this to fix color issues with LESS_TERMCAP_** env vars
# alternative: strip CSI escape codes from LESS_TERMCAP_* env vars (and possibly others)
# env | string replace --regex "\\x1b\[1(;\\d+)+m" ""
#
# shell variables names and values
abbr vls "set | bat --language ini -p"
abbr vgr "set | rg_grep -i "
#
# abbr's
abbr --add agr --set-cursor "abbr | rg_grep -i '%'"
abbr --add agrs --set-cursor "abbr | rg_grep -i '\-\- %'" # starts with b/c `-- name` is consistent format of abbr's list output
#
# complete's
abbr --set-cursor completeC "complete -C '%'"
#
#   abbr --list | rg_grep -i '^an' # another avenue if I have too much trouble relying on `abbr --show` + grep
#
# AFAICT there's no way to lookup an abbr by name... and get its executable format
#   Also, not straight forward to parse the executable format b/c name can appear in many different spots
#
#   abbr --show  # lists all, in executable format
#   abbr --query foo # can check if name exists
#   abbr --show --query foo # would be nice to combine query with show!
#   abbr --list # shows just the list of names
#
# Nice to haves:
#   FYI I have a feature branch hack of combining --query and --show:
#     https://github.com/g0t4/fish-shell/tree/feature-abbr-lookup
#     but don't work on this any more unless grep absolutely falls apart
#

# *** binds (consolidate here) ***
# FYI fish4 OOB has:
#   alt-. history-token-search-backward
#   alt-up history-token-search-backward
#   alt-down history-token-search-forward
#   FYI other shells use Escape-. but fish 4 has up/down which is superior, so use that
#   should I want to retrain myself on escape-. then add this back:
#   bind_both_modes_default_and_insert escape,. history-token-search-backward

# *** processes ***
abbr --position anywhere --add pid -- '$fish_pid'
abbr psg "grc ps aux | rg_grep -i "
function ps_dump_env_vars_when_process_started --argument-names pid
    if $IS_MACOS
        # macOS use ps -E and parse output
        ps -E -p"$pid" \
            # optional => skip headers and go with just the one row for this process (starts w/ PID)
            | rg_grep "^$pid" \
            # env vars are space delimited
            | string split ' ' \
            # grep for lines with FOO=bar pattern... FYI could also constrain to uppercase only (IIAC on the NAME= side)
            #  FYI assumes no = signs in the first columns
            | rg_grep = \
            | bat -l env
    else if $IS_LINUX
        # Linux: read environment from /proc/<pid>/environ
        cat /proc/$pid/environ | tr '\0' '\n' \
            | rg_grep = \
            | bat -l env
    end
end

# fish tracing
abbr enable_fish_tracing "set fish_trace 1"
abbr disable_fish_tracing "set --erase fish_trace"

if $IS_MACOS
    # pgrep macos:
    #   -l long output (list process name too, also w/ -f prints arg list)
    #   -a include pgrep's process ancestors in the match list (i.e. if using sudo pgrep) => they are hidden by default (unlike linux)
    #      # yes include -a... for example, I might be matching on "fish" and so I wanna see that
    #      # FYI if I use grc in front of pgrep... then that grc process always matches b/c its an ancestor... so for now lets get rid of default using grc to avoid that frustration
    #   -f/-i - same as linux
    abbr pgrep "pgrep -ilfa"
    # TLDR -a is added for different reasons between macOS and linux but for now I want it on both
    #

    abbr pgrepu 'pgrep -U $USER -ilfa'

    # -l is only on macOS
    # -i/-f are same as pgrep
    abbr pkill "pkill -9 -ilf" # same options as pgrep (-l (long) shows underlying kill command used per PID)
    abbr pkillu 'pkill -9 -U $USER -ilf'

else if $IS_LINUX
    # -i ignore case (same as mac)
    # -f match full arg list (same as mac)
    # -l == list process name too, not just PID (mac does this too)
    #       however, unlike a mac, -lf together doesn't include arg list
    # -a show full command line (args too)
    # -A ignore pgrep's ancestor processes (on by default and I hate that => always matches self)
    #    FYI if I get rid of -a on mac variant, then I probably wanna add -A here (not remove -a here)... to mirror the exclusion of ancestors
    abbr pgrep "pgrep -ilfa"
    abbr pgrepu 'pgrep -U $USER -ilfa'

    # -l is NOT on linux version
    # -i/-f are same as pgrep
    abbr pkill "pkill -9 -if" # same options as pgrep (-l (long) shows underlying kill command used per PID)
    abbr pkillu 'pkill -9 -U $USER -if'

    # FYI I might still be missing some differences w/ linux... I didn't review all possible pgrep/pkill args
end
abbr kill9 "kill -9"

abbr psfull "grc ps -o 'user,pid,pcpu,pmem,vsz,rss,tty,stat,start,time,comm' -ax"
if $IS_LINUX
    # not sure I wanna even try to replicate this on mac as then I might habituate wanting a different command, I like this alot on linux for showing current shells and their hierarchy of processes
    abbr psf "grc ps f" # i.e. current shells in tree view on linux
end
#
# NOTES:
# - keep non-format options on end of cmd to easily toggle:
# - user:10 - limits to 10 chars (+ indicates ...) (:X ubuntu yes, macos no):
#       ps -o "user:5,pid,pcpu,pmem,vsz,rss,tty,stat,start,time,comm" -ax
#
# *** pstree_grep.py
abbr --set-cursor -- pstreeg "pstree_grep '%'"
abbr --set-cursor -- pstreeg_watch "viddy 'fish -i -c \"pstree_grep \\'%\\'\"'"
#
complete --command pstree_grep --short-option h --long-option help --description 'show this help message and exit'
complete --command pstree_grep --short-option i --long-option ignore-case --description 'case‑insensitive regex matching'
complete --command pstree_grep --long-option ascii --description 'use ASCII tree connectors'
complete --command pstree_grep --short-option f --long-option show-full-cmd --description 'display the full command line instead of name(pid)'
complete --command pstree_grep --arguments '(printf "%s" "PATTERN")' \
    --description 'Regex pattern to match process name or full cmdline' \
    --require-parameter

# *** pstree
# pstreeX => pstree -l X
abbr --add _pstreeX --regex "pstree\d+" --function pstreeX
function pstreeX
    string replace pstree 'pstree -l' $argv
end
abbr pstrees --set-cursor 'pstree -s "%"' # *** NEW FAVORITE, shows all matching parents/descendants (IIUC)
abbr pstreep 'pstree -p' # parents/descendants of PID, without -p then its just descendants
abbr pstreet 'pstree  (ps -o pid=)' # ps gives processes w/ controlling terminal, then pstree shows their hierarchy... similar to "ps f" on *nix
abbr pstreeU 'pstree -U' # skip root only branches
abbr pstreeu 'pstree -u $(whoami)' # my processes
abbr pstreew 'pstree -w' # wide output (otherwise truncated)
# TODO pstree on macos/linux differs - reconcile abbrs based on env? use macos rooted abbrs (i.e. pstrees => pstree -s) but then have it map to smth similar on linux?
function pstree
    # TODO use -g 2 by default on macOS (looks better IMO)
    command pstree -g 2 $argv
end
# TODO look into utils like fuser (not necessarily for abbrs, though maybe) but b/c I need to shore up my knowlege here, so much easier to diagnose what an app is doing if I can look at its external interactions (ie files, ports, etc)

# *** sed ***

set --global sed_cmd sed
if $IS_MACOS
    set sed_cmd gsed
    abbr sed gsed # encourage gsed for uniform w/ linux distros
    #  i.e. gnu allows `sed -i` whereas BSD requires the extension `sed -i''` be passed
end
#
# * general sed abbrs:
abbr --set-cursor sede "$sed_cmd -Ei 's/%//g'"
abbr --set-cursor sedd "$sed_cmd --debug -i 's/%//g'"
abbr --set-cursor sedi "$sed_cmd -i 's/%//g'"

# * examples (can nuke if need be)
# abbr sed_duplicate_lines $sed_cmd' \'N; /^\(.*\)\n\1$/!P; D\' file'

# rg => (rg --files-with-matches __)
# use rg to limit which files are passed to sed (so not touching all files)
# use this to take your sed search regex and limit the files and then the file names are passed back
abbr --set-cursor --command $sed_cmd -- rg "(rg --files-with-matches %)"

# abbr "*l" "test redefined (do you see this in warning?)"
function build_abbrs_for_filetype
    # FYI there may be some bugs here in porting this, just heads up... use and find out

    set -l filetype_letter $argv[1]
    set -l glob_end $argv[2]
    set -l _abbr "sed$filetype_letter"

    # * two approaches to making it easier to target specific files...
    set rg_filter "(rg -g '*.$glob_end' --files-with-matches '___')"

    # 1. dedicated abbr per file type(s)
    #   i.e. sedl, sedf, sedp, etc
    abbr --set-cursor $_abbr "$sed_cmd -Ei 's/%//g' $rg_filter"

    # within rg command expand into glob filter
    # rg *l => rg -g '*.lua'
    abbr --command rg -- "*$filetype_letter" "-g '*.$glob_end'"

    # 2. *l => (rg -g "*.lua" --files-with-matches ___)
    abbr "*$filetype_letter" --command $sed_cmd $rg_filter

    # * ripgrep
    abbr "rg$filetype_letter" "rg -g '*.$glob_end'"

end

build_abbrs_for_filetype f fish
build_abbrs_for_filetype j "{json,js}"
build_abbrs_for_filetype l lua
build_abbrs_for_filetype m md
build_abbrs_for_filetype p py
build_abbrs_for_filetype t ts
build_abbrs_for_filetype r rs
build_abbrs_for_filetype y "{yaml,yml}"
build_abbrs_for_filetype x xsh


abbr --command rg -- "*nd" "--glob '!datasets'" # easily exlude datasets JSON files from shared traces

# all -  use rg w/o a filter on language (no -g *.lua for example)
abbr --set-cursor seda "$sed_cmd -Ei 's/%//g' (rg --files-with-matches ___) "
abbr --command $sed_cmd "*a" "(rg --files-with-matches ___) "

# allow , - or _ to split start/end number
#   lines1,2    lines 3-10    lines4_6
abbr _cat_range --function _cat_range_abbr --regex "(lines|catr|catrange|sedr|sedrange)\d+[,_-]\d+"
function _cat_range_abbr
    # purpose:   cat range -n '10,25p' foo.txt
    set matches (string match --regex "(\d+)_(\d+)" $argv[1])
    set start $matches[2]
    set end $matches[3]
    echo "$sed_cmd -n '$start,$end""p'"
end

# *** code finders
# TODO WIP ... change as you use these... help with log/print review
abbr lua_logs "rg -g '*.lua' '^\\s*log'"
abbr lua_logs_commented_out "rg -g '*.lua' '^\\s*--\\s*log'"
abbr lua_prints "rg -g '*.lua' '^\\s*print\\\('"
abbr lua_prints_commented_out "rg -g '*.lua' '^\\s*--\\s*print\\\('"

# *** dns
# TODO port more dns/arp helpers here
function _flush_dns
    # PRN check if macos, if not use different command or warn
    sudo killall -HUP mDNSResponder
end

function kill_hung_grc
    # if grc hangs (ie due to invalid config) then use this
    # kill grcat is all you need, the grc process dies after
    pkill -ilf grcat
end

abbr z_clean 'z --clean' # mostly a reminder, removes non-existant directories from z history file
function z
    # TLDR = wcl + z
    # FYI still uses z fish completions (b/c same name)

    # -- ensures $argv can have options to z (i.e. --clean)
    # Detect a repository URL (https:// or git@) and clone/cd to it via wcl
    if string match --quiet --regex "(?:https://[^/]+/.+|git@[^:]+:.+)" -- $argv
        # If a repo URL then clone and/or cd to it
        set path (wcl --path-only $argv)
        if test -d $path
            cd $path
        else
            wcl $argv
            cd $path
        end
    else
        # PRN in future detect if org/repo format ($argv)... AND if z has no matching results... then attempt to clone and cd to it...?
        # otherwise just call z like normal
        # TODO __z --delete does not take a path! it deletes curent dir...
        #   I want to modify this to add support to delete a path
        #   and all subpaths (maybe -R)

        if __z $argv
            # success = CD'd
            return
        end
        # failure == no matches in z "database"
        # fallback to ~/repos dir, using $argv query
        if set selection (fd --type dir $argv ~/repos | fzf --query $argv)
            cd $selection
            return
        end
        echo cancel
        # PRN drop passing $argv to fd (left side) and only filter argv with fzf on right?
        #  dropping fd filter would allow changing the entire query w/o relaunching z/fd+fzf...
    end
end

# * z --echo
abbr --position=anywhere --set-cursor --function _abbr_ze -- ze
function _abbr_ze
    # intended to easily select a directory for another outer command, or just print a path
    # i.e.:
    #    mv foo.txt ze<SPACE> => mv (z --echo _)
    #    ze<SPACE> => z --echo _
    #       # or ... what about:
    #       echo (z --echo _)?
    #
    # echo "'"(commandline -b)"'"
    # return
    if string match --quiet --regex '^ze $' (commandline -b)
        # only 'ze ' at start of line, then don't use cmd substitution
        echo 'z --echo'
        return
    end
    echo '(z --echo %)' # insert z --echo so you can pick a path to include in another outer command
end

# *** terraform
if command -q terraform

    abbr tf terraform

    abbr tfv 'terraform validate' # *** favorite
    abbr tfi 'terraform init'
    abbr tfimport 'terraform import'
    abbr tff 'terraform fmt'
    abbr tfa 'terraform apply'
    abbr tfp 'terraform plan'
    abbr tfo 'terraform output'

    abbr tfshow 'terraform show' # dump all resources in state
    #
    abbr tfs 'terraform state' # subcommands
    abbr tfsl 'terraform state list' # list resources currently in state
    abbr tfss 'terraform state show' # dump one resource in state
    abbr tfsrm 'terraform state rm' # remove resource from state
    abbr tfr 'terraform refresh'

    abbr tfd 'terraform destroy'
    abbr tft 'terraform taint'
    abbr tfu 'terraform untaint'

end

# *** bindings
#
# idea: shortcut to change to command position and replace command (type new command), i.e.:
#    ls /etc/docker/daemon.json
#    # shortcut: ctrl+shift+delete
#    _ /etc/docker/daemon.json
#    cat /etc/docker/daemon.json
function custom-kill-command-word
    # PRN move to start of current command in a pipeline of multiple commands
    commandline -f beginning-of-line
    commandline -f kill-word
end
# ctrl+ins
bind_both_modes_default_and_insert ctrl-o custom-kill-command-word # ctrl +o ([o]verwrite command)
# bind_both_modes_default_and_insert  '*' custom-kill-command-word # * alone works w/o interrupt mid suggestion
# ctrl+o/q unbound currently IIUC
# '[1;5H' # ctrl+home (interrupts suggestion)
# '[1;6H' # ctrl+shift+home (rest seem to interrupt too, likely b/c bound to smth else and triggering two bindings, maybe? i.e. home moves to home)
# '[1;7H' # ctrl+alt+home
# '[1;13H' # ctrl+alt+home
#    H=>F (home=>end key)
#
function toggle-grc
    # PRN port to zsh/pwsh

    # can easily ditch grc in kubectl command to get tab completions to work and add it back to color output and then pull back history of previous command and switch it off to tab complete easily again and grc to run it when done
    #   PRN turn off grc by default in abbrs where tab completion is often used and doesn't work well w/ grc
    #   also I am well aware that I should get grc tab completion fixed and I will look into that too
    set -f cmd (commandline)
    if test -z $cmd
        # if empty cmd, then use last command (and thus toggle its grc)
        # idea is, run command and be like oh no I wanted grc, then bam run it again, or vice versa
        set cmd (history | head -n 1)
    end

    if string match --quiet --regex "^grc\s" -- $cmd
        set cmd (string replace --regex -- "^grc\s+" "" $cmd)
        commandline -r $cmd
    else
        fish_commandline_prepend grc
        return
    end
    # ALTERNATIVE - pull back last command, toggle-grc, run - can use if I find myself doing this two step process often
end
bind_both_modes_default_and_insert ctrl-q toggle-grc # terrible key choice (ctrl+q) but it isn't used currently so yeah

function toggle-git_commit_command
    # toggle wrapping current command line in a git commit
    # to commit changes w.r.t. running a command
    # for example:
    #   uv add ipykernel
    #   => git commit -m 'uv add ipykernel'
    set -f cmd (commandline)
    if test -z "$cmd"
        # if empty cmd, then use last command
        # pull back last non git command (so I can stage files and then commit)
        set cmd (history | rg_grep --no-config --invert-match '^git\s' | head -n 1)
    end

    if string match --quiet --regex "^git\scommit\s-m\s" -- $cmd
        # unwrap
        # use regex capture group to extract the message part only (strip quotes too)
        set cmd (string replace --regex -- "^git\scommit\s-m\s'(.*)'" "\1" -- $cmd)
        commandline -r $cmd
    else
        # wrap
        commandline -r "git commit -m '$cmd'"
        return
    end
end

bind_both_modes_default_and_insert ctrl-f12 toggle-git_commit_command
# FYI -M default applies to both vi/emacs modes... default==normal in vi-mode

# *** lsof
if command -q lsof

    # find app for a given port
    # sudo lsof -i :8080 (for now hardcode 8080 as reminder, once that's annoying I can remove it)
    abbr --set-cursor lsofi 'sudo lsof -i :8080%'
    abbr --set-cursor lsof_process_for_port 'sudo lsof -i :8080%' # reminder (so I can tab complete it when I inevitably forget the lsof options again)

    # files for a process:
    # TODO how to deal with multiple matches, I don't like using head but at least it is obvious in the expanded command so leave it for now
    abbr --set-cursor lsofp 'sudo lsof -p $(pgrep -if "%" | head -1)'
    abbr --set-cursor lsof_ports_for_process_pgrep 'sudo lsof -p $(pgrep -if "%" | head -1)' # reminder
    abbr --set-cursor lsofpi 'sudo lsof -p $(pgrep -if "%" | head -1) -a -i'
    abbr --set-cursor lsof_ports_for_pid 'sudo lsof -p % -a -i' # reminder
    # -p PID
    # -i == internet files (ports)
    # -a == AND constraints

    abbr --set-cursor lsofp_watch '$WATCH_COMMAND "sudo lsof -p \$(pgrep -if \"%\" | head -1)"'

end

# TODO wireshark
# start listening on intereface X and then with filter, i.e.:
#   !mdns and !db-lsp-disc and !nbns and tcp.port==62750

# TODO
# *** netstat
# if command -q netstat
# end

# *** ss
if command -q ss
    # -n # not resolve
    # -t -u # tcp+udp
    # -l # listening
    abbr ss_listening_ports "sudo ss -tunl" # listening are ommited by default
    abbr ss_notlistening_ports "sudo ss -tun"
    abbr ss_all_ports "sudo ss -tuna" # listening and not
end
