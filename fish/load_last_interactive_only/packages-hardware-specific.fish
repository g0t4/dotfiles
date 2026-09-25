if command -q apt

    # start on apt helpers now that I have fish in almost all of my ubuntu environments

    abbr apts 'apt search'
    abbr apti 'sudo apt install'
    abbr aptu 'sudo apt update'
    abbr aptug 'sudo apt upgrade'

    abbr aptl 'apt list --installed'
    abbr aptlu 'apt list --upgradable'

    abbr aptcm 'apt-cache madison'

    abbr dpkgL 'dpkg -L' # list files installed by package
    abbr dpkgS 'dpkg -S' # search for package that owns file

    function dpkg_L_files
        dpkg -L $argv | xargs -I {} echo 'test ! -d "{}"; and echo "{}"' | source
    end

    complete -c dpkg_L_files -a '(dpkg --get-selections | rg_grep -w "install" | awk \'{print $1}\')' --no-files

    function dpkg_L_tree
        # uses exa to append icons (left side only), pipes to awk to put icon on right side, pipes to treeify and icon ends up on right side
        exa (dpkg_L_files usbutils) --icons=always | awk '{icon=$1; $1=""; sub(/^ /, ""); print $0, icon}' | treeify
    end

    complete -c dpkg_L_tree -w dpkg_L_files

    if not command -q treeify
        function treeify
            echo "treeify not installed, please install it with 'cargo install treeify'"
        end
    end

end

if command -q watch; and status is-interactive
    # VERIFIED watch does this on both macos and ubuntu

    # FYI this is faster than using alias and more obvious what happens:
    function watch
        # FYI uses same pattern of passing $argv as is found in fish's alias helper
        TERM=xterm command watch $argv
        # if watch believes there are 16+ colors (8 regular + 8 brights) it will then init the brights to hard coded colors and screw up background colors too (i.e. for white)... so if it believes there are only 8 colors then it doesn't alter any of them IIUC: https://gitlab.com/procps-ng/procps/-/blob/master/src/watch.c#L181

        # good way to test my colors:
        # watch -n 0.5 --color -- "grc --colour=on kubectl describe pod/web"

        # IIUC viddy doesn't have --color? Do I want to add it to just this watch wrapper?
    end

    function viddy
        # look in args for `-n` and then don't pass if found
        if contains -- -n $argv
            command viddy $argv
        else
            command viddy -n $WATCH_INTERVAL $argv
        end
    end

    export WATCH_INTERVAL=0.5
    if command -q viddy
        set WATCH_COMMAND viddy
    else
        set WATCH_COMMAND watch
    end
    abbr watch $WATCH_COMMAND

    function _expand_watch_last
        set recent_cmd (history -n 1)

        echo "$WATCH_COMMAND --no-title -- $recent_cmd"
    end
    abbr -a watch_last --function _expand_watch_last

    abbr wa $WATCH_COMMAND
    # FYI if you go back to watch... add --color to appropriate abbrs
    abbr wag '$WATCH_COMMAND --no-title -- grc --colour=on'
    # to support --no-title, add --show-kind to kubectl get output
    # - saves top title line and blank line after it for screen realestate!
    # - also nukes showing time in upper right corner
    # - FYI --show-kind already enabled if multi types requested, so NBD
    abbr wak '$WATCH_COMMAND --no-title -- grc --colour=on kubectl get --show-kind' # using alot! I love this
    abbr wad '$WATCH_COMMAND --no-title -- grc --colour=on kubectl describe --show-kind' # using alot! I love this
    abbr wakp '$WATCH_COMMAND --no-title -- grc --colour=on kubectl get --show-kind pods'
    abbr wah '$WATCH_COMMAND --no-title -- http --pretty=colors'
    abbr wahv '$WATCH_COMMAND --no-title -- http --pretty=colors --verbose' # == --print HhBb (headers and body for both request and response)
    abbr wal '$WATCH_COMMAND --no-title -- grc --colour=on ls'
    abbr wat '$WATCH_COMMAND --no-title -- grc --colour=on tree'
    # for k8s prefer kubectl --watch b/c grc colors the output w/o issues.. but when it is not avail to continually monitor then use watch command w/ color output:
    #   watch -n0.5 --color -- grc --colour=on kubectl rollout status deployments

    # FYI find terminfo for a TERM value:
    #    diff_two_commands 'infocmp xterm' 'infocmp xterm-256color'
    #
    # xterm = treated as 8 color
    # FYI xterm-16color still has brights issue
    # xterm-256color = treated as 256 colors (IIUC this is how background colors for bright white gets messed up)

end

abbr wc wordcount # when typing wc => expand into custom wordcount func (can still use `wc` in scripts or `command wc` to use wc directly)
function wordcount
    # run wc and then parse result to add labels on each value:
    wc $argv | command awk '{printf("lines: %'\''d\nwords: %'\''d\nchars: %'\''d\n", $1, $2, $3)}'
    # FYI comma delimitted support in awk is not POSIX compliant, but is supported in gawk and mawk IIUC
end

if command -q yq

    # helper to select a document by index from multidocument yaml file
    abbr pyqi "| yq eval 'select(documentIndex == 1) | .status'"
    abbr pyqp "| yq -P" # pretty print (clean/idiomatic yaml) == `yq '... style=""')`
    # FYI `jid < foo.json` can tab complete json property keys... but doesn't appear to support multiple documents (IIAC an put into an array to get it to work)

    function yq_diff_docs
        # usage:
        #   kubectl get pods -o yaml > pods.apply.watch.yaml
        #   yq_diff_docs pods.apply.watch.yaml  0 1 '.status'
        #   leave pair of #s so I can diff across indexes (should add optional arg for second documentindex for that... as mostly I would wanna compare before/after - sequential pairs)

        # PRN how about loop over each document pair in a watched file from k8s
        #   cat pods.apply.watch.yaml  | yq di
        #   IIUC no way to query # documents but can select document indexes or otherwise count lines to get # ... or just loop over document indexes and pair them with next to avoid any maths

        set file $argv[1]
        set doc1 $argv[2]
        set doc2 $argv[3]
        set path $argv[4]

        # https://mikefarah.gitbook.io/yq/operators/document-index
        yq eval "select(documentIndex == $doc1) | $path" $file >/tmp/doc1.yaml
        yq eval "select(documentIndex == $doc2) | $path" $file >/tmp/doc2.yaml

        icdiff -W -L "doc $doc1" /tmp/doc1.yaml -L "doc $doc2" /tmp/doc2.yaml
    end
end

# TODO brew install wader/tap/fq
#    fq = jq for binary files
#    https://github.com/wader/fq

# *** _list_<namespace>_<what>
abbr _reminders_docker_binfmts "docker run --privileged --rm tonistiigi/binfmt" # https://github.com/tonistiigi/binfmt
# idea for a new spot where I can locate what are essentially reminders for commands (i.e. not used often)
# type _reminders<TAB> to see what is available

# examples:
#    tellme_about docker   # executable, symlink
#    tellme_about ld       # executable, not symlink
function tellme_about
    set -l what $argv[1]
    set _where (command -v $what)
    if test -z $_where
        echo "I don't know about $what"
        return 1
    end
    echo $_where # top level match, no indent
    file --brief $_where | _indent # indent the description
    if test -L $_where
        echo "  -> " (readlink $_where) # show target
    end

    # todo multiple matches
    # PRN flesh this out later, just a quick thought... I feel like I've done this before too :)...
end

function _indent
    # $argv = level of indent (1 = 2 spaces, 2 = 4 spaces, etc)
    if test -z $argv
        set spaces 2 # default to 2 spaces (1 level of indent)
    else
        set spaces (math "$argv * 2") # 2 spaces per indent
    end
    sed "s/^/"(string repeat " " -n $spaces)"/"

end

if command -q npm

    # TODO REVISIT
    # suppress annoying warning for now
    # (node:76864) ExperimentalWarning: CommonJS module /opt/homebrew/lib/node_modules/npm/node_modules/debug/src/node.js is loading ES Module /opt/homebrew/lib/node_modules/npm/node_modules/supports-color/index.js using require().
    # Support for loading ES Module in require() is an experimental feature and might change at any time
    # (Use `node --trace-warnings ...` to show where the warning was created)
    export NODE_OPTIONS='--disable-warning=ExperimentalWarning'

    function npm_install
        if not _repo_is_index_clean
            log_ --red "cannot npm install w/ outstanding staged (index) changes, aborting..."
            return 1
        end
        # check if staged files
        if not test -f package.json
            log_ --red "package.json not found in current directory, aborting..."
            return 1
        end
        # save me the time by install/add/commit the package info
        npm install $argv
        git commit -m "npm install $argv" package.json package-lock.json
    end

    # PRN as I use and find how I wanna use aliases
    abbr npmi npm_install
    abbr npminit 'npm init -y'
    abbr npml 'npm list'
    abbr npmr 'npm run'
    abbr npmt 'npm test'
    abbr npma 'npm audit'
    abbr npmv 'npm version'
    abbr npms 'npm start'
    abbr npmo 'npm outdated'
    abbr npmun 'npm uninstall'
    abbr npmup 'npm update'

    abbr npxr 'npx run'

    # * brew install tree-sitter-cli
    # function tree-sitter --wraps tree-sitter
    #     # PRN did this work out?
    #     npx tree-sitter-cli $argv
    # end

    # FYI it's fine to get rid of these for a different tool to get the `ts` prefix
    abbr ts tree-sitter
    abbr tsg "tree-sitter generate"
    abbr tsb "tree-sitter build"
    abbr tsp "tree-sitter parse"
    abbr tst "tree-sitter test"
    abbr tsq "tree-sitter query"
    abbr tsh "tree-sitter highlight"
    abbr tsplayground "tree-sitter playground"

end

function npx --description "Run npm/npx tooling in a constrained docker container"
    # todo expand beyond just npx?

    if test (count $argv) -eq 0
        echo "usage: npx <npx command> [args...]"
        return
    end

    set -l cwd (pwd -P)
    set -l allowed_root ~/repos/github

    if not string match -qr "^"(string escape --style=regex $allowed_root)"/[^/]+/[^/]+(?:/.*)?\$" "$cwd"
        echo "Refusing: must be inside $allowed_root/<owner>/<repo>" >&2
        return 1
    end

    if not git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Refusing: not inside a git repository" >&2
        return 1
    end

    set -l repo_root (git -C "$cwd" rev-parse --show-toplevel)

    if not string match -q "$allowed_root/*/*" "$repo_root"
        echo "Refusing: repo root must be under $allowed_root/<owner>/<repo>" >&2
        return 1
    end

    # PRN pass as variable? or env var?
    set node_version latest
    # set node_version 22

    docker run --rm -it \
        --read-only \
        --tmpfs /tmp \
        --tmpfs /root/.npm \
        --cap-drop ALL \
        --security-opt no-new-privileges \
        -v "$repo_root:/work:rw" \
        -w "/work"(string replace "$repo_root" "" "$cwd") \
        node:"$node_version" \
        npx $argv
end

# TODO! add mechanism to discover duplicated abbrs => on-demand check?

abbr bm bitmaths # careful brew uses b* prefix
function bitmaths
    # FYI completions-eval-test-candidate

    # PRN show non-printable chars that make sense to show? i.e. \n \t etc yeah... \r
    echo -n "ascii: "
    python3 -c "print(hex($argv)[2:])" | xxd -r -p
    echo

    echo -n "bin: "
    python3 -c "print(bin($argv))"

    echo -n "hex: "
    python3 -c "print(hex($argv))"

    # echo -n "oct: "
    # python -c "print(oct($argv))" | bc --obase=8

    echo -n "dec: "
    python3 -c "print($argv)"

end

function pretty_size
    # FYI completions-eval-test-candidate
    # user passes in raw number like 1024  or 1024000 and this passes back 1KB, 1MB or w/e nearest size is
    set size $argv[1]
    if test (count $argv) -lt 1
        echo "Usage: size_in_bytes <size>"
        return 1
    end

    python3 -c "
import math;
if $size < 1024/2:
    print(f'{$size}B')
elif $size < 1024**2/2:
    print(f'{$size/1024:.2f}KB')
elif $size < 1024**3/2:
    print(f'{$size/1024**2:.2f}MB')
else:
    print(f'{$size/1024**3:.2f}GB')
"
end

# *** man page helpers
set man_cmd man
if $IS_MACOS
    # brew install man-db
    set man_cmd gman
    abbr man gman
end
abbr man_commands_1 "$man_cmd 1"
abbr man_syscalls_2 "$man_cmd 2"
abbr man_c_stdlib_3 "$man_cmd 3"
abbr man_kernel_interfaces_4 "$man_cmd 4"
abbr man_file_formats_5 "$man_cmd 5"
abbr man_misc_7 "$man_cmd 7"
abbr man_system_8 "$man_cmd 8"
abbr man_kernel_dev_9 "$man_cmd 9"
# list all pages in a section:
abbr --regex "manlist[0-9]" --function manlistX -- manlistX
function manlistX
    set section $(string replace manlist "" $argv[1])
    echo "$man_cmd -k . | rg_grep '($section)'"
end
abbr man1 "$man_cmd 1"
abbr man2 "$man_cmd 2"
abbr man3 "$man_cmd 3"
abbr man4 "$man_cmd 4"
abbr man5 "$man_cmd 5"
abbr man6 "$man_cmd 6"
abbr man7 "$man_cmd 7"
abbr man8 "$man_cmd 8"
abbr man9 "$man_cmd 9"
#
# gman has --regex among other improvements
abbr mana "$man_cmd --all --regex" ## -a = all, -w = list path(s) open all matching pages
abbr mank apropos # man -k ~= apropos
abbr manf whatis # man -f == whatis
#
# * gnu man short => long options
#
# FYI for now, if I type -k/-K standalone then I will expand it (but I won't expand it in my abbrs below where -K matches my intuition)
abbr --command "$man_cmd" -- -K --global-apropos
abbr --command "$man_cmd" -- -k --apropos
#
abbr --command "$man_cmd" -- -w --where
abbr --command "$man_cmd" -- -a --all

# * search all manpage text (preformatted files)
#   not in macOS's man
reminder_abbr man_grep "use mgr"
reminder_abbr man_grep_list_matches "use mgrw"
#
# I have -K/-w mostly burned into memory... so keep these
abbr manK "$man_cmd -K" # I recall K all the time so I like manK in this case
abbr manw "$man_cmd --where -K" # man -w == whereis for man pages, or map to whereis?
#
# long term I wanna use a `gr` style:
abbr mgr "$man_cmd -K" # [m]an [gr]ep (common pattern I use is *gr for grep)
abbr mgrw "$man_cmd --where -K" # --where/--path/--location (print the location)
# i.e. gman -w -K autostash
# note -K is slow, hence why by default it starts showing pages it finds so you can look at them while it searches (presumably it continues searching in bg?)
#
abbr manbash "$man_cmd $HOME/repos/github/g0t4/bash/doc/bash.1"
# use newest build of bash man page (at least don't use 3.2 from apple!)
abbr mbash "$man_cmd $HOME/repos/github/g0t4/bash/doc/bash.1"
#
# force pages in homebrew installed manpages to WIN
#  that way the manpage there for bash always takes precedence
#  and I NEVER see bash 3.2 from Apple's crap
#    that you cannot DELETE EITHER in /usr/share/man/man1/bash.1
# NOTE : colon on end means this is PREPENDED to std MANPATH (so I don't lose other pages, I just put these first)
#
# must use set b/c fish has special handling for PATH vars, so cannot just use trailing : like in bash
set -x MANPATH /opt/homebrew/share/man ""
# abbr manw "whereis" ???
# PRN whereis helpers?
# PRN apropos helpers?
# PRN whatis helpers?

# *** mitmproxy
abbr mitm mitmproxy
abbr mitml "mitmproxy --mode=local"
#
abbr mitmw mitmweb # web interface # PRN just set this to --mode=local?
abbr mitmwl "mitmweb --mode=local" # local mode
#
abbr mitmd "mitmdump --mode=local" # PRN just set this to --mode=local?
abbr mitmdl "mitmdump --mode=local" # local mode
#
# read flow files:
abbr mitmr "mitmproxy --no-server --rfile" # when reading, dont start server (that way can run separate instances with sep flow recordings)
#
# orphaned server:
# - sometimes mitmproxy server becomes orphaned (quit CLI doesn't stop it... so I need to find/stop it)
# - ignore if --no-server
abbr mitm_pgrep 'pgrep -ilf mitmproxy | rg_grep -v "\--no-server" || true' # don't error if not found, avoid confusion
abbr mitm_kill 'pgrep -ilf mitmproxy | rg_grep -v "\--no-server" | awk \'{print $1}\' | xargs sudo kill -9 || true'
#
# program specific
abbr mitmlc "mitmproxy --mode=local:'Visual Studio Code.app'" # capture just vscode (note not insiders)
abbr mitmlci "mitmproxy --mode=local:'Visual Studio Code - Insiders.app'"
abbr mitmlcurl "mitmproxy --mode=local:'curl'"
#
abbr mitms "mitmproxy --scripts" # pass script (i.e. python addons) # TODO do I use this?
abbr mitmsave "mitmproxy --save-stream-file" # # TODO do I use this?
#
# FYI possible options for config file:
#   PRN sync ~/.mitmproxy/config.yml via dotfiles
#   --anticomp # (default off) # TODO try to get servers to return uncompressed content, IIGC to make it easier to mod responses... FYI set this in config file not CLI arg
#   --console-layout {horizontal,single,vertical} # single (default) or split horiz/vertical an extra pane (ctrl+left/right).. just use `-` to switch layout on the fly for now
#       --no-console-layout-headers / --console-layout-headers   # PRN set in ~/.mitmproxy/config.yml
#
# Add when needed:
#   --map-remote PATTERN
#   --map-local PATTERN
#   --modify-body
#   --modify-headers
#
#   --intercept  # hard filter # maybe have option for this when using --save-stream-file since this is more likely to matter when saving
#   --view-filter  # soft filter (view only, actually captured still) # I would rather just do this with `f` in the running instance unless I wanna persist across restarts

function show_hex_rgb_color

    # TODO check if shell supports 24bit RGB true color, iTerm2 supports this (validated in my testing), but vscode doesn't (smth to do w/ color correction but don't care to fix that right now)

    #  show_hex_rgb_color "#000000" "000000"   # s/b all black (but vscode terminal isn't) => BEST INDICATOR of color corrections happening in vscode
    #  show_hex_rgb_color "#000000" "ff0000"   # s/b bright red
    #  show_hex_rgb_color "#000000" "00ff00"   # s/b bright green
    #  show_hex_rgb_color "#000000" "0000ff"   # s/b bright blue
    #  show_hex_rgb_color "#000000" "ffffff"   # s/b bright white on black
    #  show_hex_rgb_color "#ffffff" "000000"   # s/b black on white

    # usage: show_hex_rgb_color "#ff0000"  # show bgcolor only
    # usage: show_hex_rgb_color "#ff0000" "#000000" # show bgcolor and fgcolor
    set bgcolor $argv[1]
    set fgcolor $argv[2]

    # PRN handle other color formats as needed... or maybe make other methods for those

    # always have bgcolor:
    set bg_hex (string replace --regex -- "^#" "" $bgcolor) # ok if fails b/c no matches
    set bg_red (math "0x$(string sub $bg_hex --start 1 --length 2)")
    set bg_green (math "0x$(string sub $bg_hex --start 3 --length 2)")
    set bg_blue (math "0x$(string sub $bg_hex --start 5 --length 2)")

    if test -z $fgcolor
        # Print the background color in terminal, without any text
        printf "\e[48;2;%d;%d;%dm   %s   \e[0m\n" $bg_red $bg_green $bg_blue "           " # show spaces w/o text
    else
        set fg_hex (string replace --regex -- "^#" "" $fgcolor) # ok if fails b/c no matches
        set fg_red (math "0x$(string sub $fg_hex --start 1 --length 2)")
        set fg_green (math "0x$(string sub $fg_hex --start 3 --length 2)")
        set fg_blue (math "0x$(string sub $fg_hex --start 5 --length 2)")

        # Print the background color in terminal, with text
        printf "\e[38;2;%d;%d;%dm\e[48;2;%d;%d;%dm   %s   \e[0m\n" $fg_red $fg_green $fg_blue $bg_red $bg_green $bg_blue " text looks like " # show spaces w/o text
    end

end

if command -q luarocks

    # * DO NOT ADD global abbrs unless you change neovim to find and use global luarocks install, I'd rather you symlink ~/.luarocks across users if you really need global installs
    #  path varies for global across OSes/distros
    #  that way you always look in ~/.luarocks! (easy peasy)
    #
    abbr lr luarocks
    # abbr lrl luarocks list # global and local, for newest lua version # stop making it easy to look at global luarocks packages as a reminder to stay local
    abbr lrll luarocks list --local # only local
    abbr lrl1 luarocks list --lua-version=5.1 --local # nvim uses 5.1
    abbr lrl4 luarocks list --lua-version=5.4 --local # hammerspoon uses this + its the current release
    abbr lrl5 luarocks list --lua-version=5.5 --local

    # abbr lrd luarocks doc # show docs for package

    abbr lri1 luarocks install --lua-version=5.1 --local
    abbr lri4 luarocks install --lua-version=5.4 --local
    abbr lri5 luarocks install --lua-version=5.5 --local

    abbr lrrm1 luarocks remove --lua-version=5.1 --local
    abbr lrrm4 luarocks remove --lua-version=5.4 --local
    abbr lrrm5 luarocks remove --lua-version=5.5 --local

    abbr lrs1 luarocks search --lua-version=5.1
    abbr lrs4 luarocks search --lua-version=5.4
    abbr lrs5 luarocks search --lua-version=5.5

    abbr lrshow1 luarocks show --lua-version=5.1
    abbr lrshow4 luarocks show --lua-version=5.4
    abbr lrshow5 luarocks show --lua-version=5.5

end

if command -q pacman

    # arch linux

    # FYI this could collide with my p* pipe abbrs (i.e. pgr => | rg_grep -i), resolve it when that happesn
    abbr pm pacman

    # *** -S sync
    abbr --set-cursor pmss "sudo pacman -Ss '^%'" # (s)earch, name starts with
    abbr --set-cursor pm_search "sudo pacman -Ss '^%'" # reminder only
    # pacman -Ss regex => (s)earches desc too, can be noisy
    abbr pmsi "pacman -Si" # pkg (i)nfo
    abbr pm_info "pacman -Si"
    # pacman -Sl [repo] # list all pkgs in repo extra
    abbr pms "sudo pacman --noconfirm -S" # install (aka sync)
    abbr pm_install "sudo pacman --noconfirm -S" # reminder
    abbr pmsu "sudo pacman -Syu" # think [Sy]nc + [u]pgrade
    abbr pm_update "sudo pacman -Syu" # reminder is all

    # *** -R remove
    abbr pmr "sudo pacman -R --recursive" # -R remove, -s (--recursive) => also rm the deps that it has that are no longer needed
    abbr pm_uninstall "sudo pacman -R --recursive" # reminder

    # *** -Q query (local aka installed pkgs)
    abbr pmq "pacman -Q"
    abbr pm_listinstalled "pacman -Q" # training wheels reminder for what command b/c this is all truly confusing IMO, perhaps I should better wrap my mind around the commands?
    abbr pmqi "pacman -Qi" # pkg (i)nfo (probably easier to just use -Si for most pkgs unless install a local dev checkout)
    # search installed pkgs:
    abbr pmqs "pacman -Qs" # (s)earch ERE(regex) search installed pkgs (prolly just use `pacman -Q | rg_grep -i`)
    abbr --set-cursor pmqg "pacman -Q | rg_grep -i '%'" # I prefer grep, it's just easier to not need another tool specific option
    abbr --set-cursor pmqgs "pacman -Q | rg_grep -i '^%'"
    #
    abbr pmql "pacman -Ql" # (l)ist files for pkg, can list multiple too (in which case first col is pkg name)
    # TODO any reason why I wouldn't just use -Fl always? perhaps if I custom build a pkg?
    abbr --set-cursor pmqlt "pacman -Qlq % | treeify_with_icons " # tree like list (-q == --quiet => show less info, in this case dont list pkg name column, just file paths)
    function treeify_with_icons
        # just a quick take on this... would like color too but treeify would need an option to support that too
        pacman -Ql procs | awk '{print $2}' | while read -l path
            if test -f "$path"
                set icon (lsd --icon=always "$path" 2>/dev/null | awk '{print $1}')
                echo "$path $icon"
            end
        end | treeify
    end

    abbr --set-cursor pm_listinstalledpkgfiles "pacman -Qlq % | treeify" # reminder
    #pacman -Qk fish # verify installed files
    abbr pmqo "pacman -Qo" # (o)wned by pkg
    abbr pm_whoownsfile "pacman -Qo"
    #pacman -Qo /path/to/file # find package for an installed file
    #pacman -Qo ip # owned by iproute2
    #
    # *** explicit / implicit installed pkgs
    abbr pmqe "pacman -Q --explicit" # list (e)xplicitly installed pkgs
    abbr pmqd "pacman -Q --deps" # list (e)xplicitly installed pkgs
    abbr pm_list_explicit_installs "pacman -Q --explicit" # -e/--explicit
    abbr pm_list_implicit_installs_aka_deps "pacman -Q --deps" # -d/--deps
    #pacman -Qet # explicit installed packages (not required as deps of another package)
    #   IIUC, minimal set of packages to install to get back to where I am not
    #   IOTW -Qe == all packages I asked to install
    #        -Qet == if I asked for A and B, and B is a dep of A, then only A shows here (b/c A would trigger B's install)
    #pacman -Qdt # orphans (not explicitly installed, also no longer a dep of another package)
    abbr pm_list_upgrades "pacman -Q --upgrades"

    # *** Files database
    abbr pmf "pacman -F" # (f)ile => find file in remote packages
    # pacman -F /path/to/file # find file in remote package (i.e. not yet installed)
    # pacman -F ollama # or, w/o path => find what provides ollama command
    #
    # FYI for -Fl vs -Ql... mostly gonna be ok to use -Fl... but, if build a pkg by hand it might only be avail in locally installed packages
    abbr pmfl "pacman -Fl" # (l)ist files for (remote) pkg
    abbr --set-cursor pmflt "pacman -Flq % | treeify" # treeify list of files
    abbr --set-cursor pm_listremotepkgfiles "pacman -Flq % | treeify" # reminder
    abbr pmfy "sudo pacman -Fy" # reminder - download/s(y)nc fresh package databases

    # * pactree
    # local DB == installed pkgs, sync DB == all pkgs (uninstalled too)
    # abbr pmtree_list_installed_pkgs_used_by "pactree --color" # FYI might be useful for optional dependencies that are installed (vs not installed)... if so, determine how to list optional with pactree and implement this abbr as needed
    abbr pmtree_list_installed_pkgs_that_use "pactree --reverse --color"
    #
    abbr pmtree_list_all_pkgs_used_by "pactree --sync --color" # FYI no need to differentiate installed/all for dependencies of a pkgg... install status is irrelevant (unless get into optional deps)
    abbr pmtree_list_all_pkgs_that_use "pactree --sync --reverse --color"
    #
    abbr --add __pactree_depth --command pactree --regex '^d(\d+)$' --function __pactree_depth
    function __pactree_depth
        # dX => --depth=X
        string replace --regex -- '^d(\d+)$' '--depth=$1' $argv
    end

    # TODOs (as I use and figure out what I want):
    # -R == --remove
    abbr prm "sudo pacman -R"
    # -U == --upgrade
    abbr pum "sudo pacman -U"

end

if command -q nvidia-smi
    # PRN if all these linux commands introduce too much overhead (i.e. in the command -q part)..
    #   then split them into a file and bail at top if not linux as a first check $IS_LINUX
    #  prefix == "nv" # seems fine, might overlap with neovim at some point?
    #  PRN alternative => use abbr --command nvidia-smi ... command level abbrs? or perhaps just need to fix completions which don't work even with fuc on man pages)
    abbr --set-cursor nv "nvidia-%" # kinda weird with space => dash but lets see how I feel as i use it and if it collides w/ anything else

    # TODO can I find a better source of copmletions?
    complete -c nvidia-container-cli --no-files -a "list info configure --help"

    # Basic commands
    abbr ns nvidia-smi
    abbr nsl "nvidia-smi -L" # List GPUs
    abbr nst "nvidia-smi -q -d temperature | bat -l yml" # not yaml, but close enough
    abbr nsu "nvidia-smi -q -d utilization | bat -l yml" # not yaml, but close enough
    abbr nstw "\$WATCH_COMMAND nvidia-smi -q -d temperature"
    abbr nsuw "\$WATCH_COMMAND nvidia-smi -q -d utilization"
    abbr nsm "nvidia-smi -q -d memory | bat -l yml" # Memory usage
    abbr nsmw "\$WATCH_COMMAND nvidia-smi -q -d memory"
    abbr nsp "nvidia-smi -q -d power | bat -l yml" # Power usage
    abbr nspm "\$WATCH_COMMAND -n 1 nvidia-smi -q -d power,memory,utilization" # Power and memory monitoring
    abbr nsf "nvidia-smi -q -d clock | bat -l yml" # Clock frequencies

    # Monitoring commands with loop
    abbr nsdmon "nvidia-smi dmon" # Device monitoring in scrolling format
    abbr nspmon "nvidia-smi pmon" # Process monitoring in scrolling format
    abbr nswatch "\$WATCH_COMMAND -n 1 nvidia-smi" # Basic monitoring with refresh

    # More specialized queries
    abbr nspids "nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv" # List processes using GPU
    abbr nstopo "nvidia-smi topo -m" # GPU topology matrix
    abbr nsnvlink "nvidia-smi nvlink -s" # NVLink status
    abbr nsgpu "nvidia-smi --query-gpu=gpu_name,gpu_bus_id,vbios_version --format=csv" # GPU details
    abbr nsall "nvidia-smi --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,pcie.link.gen.max,pcie.link.gen.current,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv" # Detailed GPU info
end

# *** trash helpers

function trash
    if not command -q trash
        echo "trash not installed...  install or find workaround for your OS"
        return 1
    end

    if $IS_MACOS
        # -F => use finder to ensure `Put Back` works
        #   otherwise item is in trash but have to manually restore location
        for file in $argv
            if test -e $file
                command trash -F $file
            end
        end
    else if command -q trash
        command trash $argv
    else
        echo "TODO not implemented yet for your OS"
    end
end

# mostly for fun, also a good way to remember this exists :)
abbr fuc fish_update_completions

function _fish_from_source
    # paths to possible builds
    set -l release_path ~/repos/github/fish-shell/fish-shell/target/release/fish
    set -l debug_path ~/repos/github/fish-shell/fish-shell/target/debug/fish

    if test -x $release_path
        echo $release_path
    else if test -x $debug_path
        echo $debug_path
    else
        echo "Warning: No fish binary found in release or debug build."
        return 1
    end
end

abbr --add fish_from_source --function _fish_from_source

# *** ls* abbrs
if $IS_LINUX then

    # lscpue
    abbr lscpue "lscpu -e" # table like extended view
    abbr lscpuon "lscpu -e --online"
    abbr lscpuoff "lscpu -e --offline"

    # lspci
    abbr lspcit "lspci -tv" # tree, verbose
    abbr lspcik "lspci -k" # show kernel drivers (compatible and in use)
    #
    # -d [<vendor>]:[<device>][:<class>]		Show only devices with specified ID's
    # classes: https://admin.pci-ids.ucw.cz/read/PD/
    abbr lspciu "lspci -k -d ::00xx" # unclassified
    abbr lspcii "lspci -k -d ::01xx" # storage
    abbr lspcin "lspci -k -d ::02xx" # network
    abbr lspcig "lspci -k -d ::03xx" # graphics

    # lsblk # PRN

    # lshw
    abbr lshw "sudo lshw"
    abbr lshws "sudo lshw -sanitize"
    abbr lshwb "sudo lshw -businfo"
    abbr lshwcd "sudo lshw -class display"
    abbr lshwcn "sudo lshw -class network"
    abbr lshwcs "sudo lshw -class storage"

    # lsmod
    abbr --set-cursor lsmodg "sudo lsmod | rg_grep -i '%'"

    # lsmem
    abbr lsmem "lsmem --output-all"

    # lspath
    # lstopo

    # lsusb
    abbr lsusb "lsusb -tv" # concise tree, a few more details
    abbr lsusbv "lsusb -v" # very detailed

    # dmesg
    abbr --set-cursor dmesgg "sudo dmesg | rg_grep -i '%'"

end

if $IS_MACOS

    # map some abbrs so I can get similar info on my mac to what I am used to using on linux/arch
    # FYI these are just a first take, ok to change and/or nuke
    abbr sp "system_profiler"
    abbr sp_list_datatypes "system_profiler -listDataTypes"
    abbr lsusb "system_profiler SPUSBHostDataType" # FYI macos Tahoe renamed SPUSBDataType => SPUSBHostDataType
    abbr lspci "system_profiler SPPCIDataType"
    abbr lscpu "sysctl -n machdep.cpu.brand_string; sysctl -n hw.physicalcpu; sysctl -n hw.logicalcpu"
    abbr lsblk "diskutil list"
    abbr dmidecode "system_profiler SPHardwareDataType" # would just system_profiler make more sense here?
    abbr inxi "system_profiler SPHardwareDataType; system_profiler SPSoftwareDataType"
    abbr hwinfo "system_profiler SPHardwareDataType"
    abbr free vm_stat
    abbr dmesg "log show --predicate 'eventMessage contains \"kernel\"' --info --debug --last 1m"

else if $IS_LINUX
    abbr lsblk_fs "lsblk --fs"
    abbr lsblk_nvme "lsblk --nvme"
    abbr lsblk_scsi "lsblk --scsi"
    abbr lsblk_virtio "lsblk --virtio"

    abbr lsblk_topology "lsblk --topology"

    abbr fdisk_ls "sudo fdisk -l"
    abbr fdisk_details "sudo fdisk -lx"

    abbr findmnt_fstab "findmnt --fstab" # based on /etc/fstab (not necessarily loaded)
    abbr findmnt_verify "findmnt --verify --verbose" # will report warning if new fstab entries are not yet loaded, that is ok
end
