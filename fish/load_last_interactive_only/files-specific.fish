# *** ls
abbr lat "ls -alht" # -t == sort by time
abbr las "ls -alhS" # -S == sort by size
abbr la "ls -alh" # use fish builtin `la` and pass -h by default now

if status is-interactive
    function ls
        # if command -q eza
        #     eza --group-directories-first $argv
        # try lsd for a bit, as daily primary, fallback to eza if not happy
        if command -q lsd
            lsd --group-directories-first $argv
        end
    end
end

# this was in release notes for 3.6.0! regex just added (among other changes)
#    https://fishshell.com/docs/3.6/relnotes.html
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end

abbr --add dotdot --regex '^\.\.+$' --function multicd

# cd-
abbr --add cd- 'cd -'

# TODO impl cp-  or cph (like dirh, interactive to pick recent dir?)
#   see dir stack / history : https://fishshell.com/docs/current/interactive.html#id13
# function _cp-
#     echo cp "$dirprev"
# end
#
# abbr --add cp- --regex 'cp-' --function _cp-

## *** ask-openai related

abbr ask_status "git -C (z --echo dotfiles) status; git -C (z --echo ask-openai.nvim) status; git -C (z --echo devtools.nvim) status"

## *** fish related

function _reload_config
    source ~/.config/fish/config.fish
end

function _update_dotfiles
    if test -d ~/repos/github/g0t4/dotfiles
        git -C ~/repos/github/g0t4/dotfiles pull
    end
end

function _update_os_lazy

    if command -q apt
        sudo apt update
        sudo apt dist-upgrade -y
        sudo apt autoremove -y
        sudo apt clean
    end

end

function _update_completion
    # PRN add more completions (helm, kubectl, etc)

    mkdir -p ~/.config/fish/completions/

    echo "updating completions in ~/.config/fish/completions/"

    command -q minikube; and minikube completion fish >~/.config/fish/completions/minikube.fish
    command -q kubectl; and kubectl completion fish >~/.config/fish/completions/kubectl.fish
    command -q helm; and helm completion fish >~/.config/fish/completions/helm.fish

    command -q docker; and docker completion fish >~/.config/fish/completions/docker.fish
    # FYI fish shell only, generated completions are superior to DDfM bundled completions

    command -q tree-sitter; and tree-sitter complete --shell fish >~/.config/fish/completions/tree-sitter.fish

end

# *** touchp
abbr touch touchp # make it explicit and help me remember I made the change
abbr mkfile touchp # PRN consider renaming (and maybe get rid of touch and just make file if not exists?)
function touchp
    if test -z "$argv"
        echo "create a file and optionally its parent dir(s) if they don't exist"
        echo "usage: "
        echo "  touchp path/to/file"
        return
    end

    # why use mkdir -p + touch when I can do it all in one command!
    set -l path $argv
    set -l parent (dirname $path)
    mkdir -p $parent
    touch $path
    # PRN handle case where touchp has a / on end and make it behave like mkdir -p in that case? (not create the file)... not really a primary use case for the touch command other than I could write a unified command to create a dir or a file
end

function mkpath
    # if ends in / => dir, else file
    set -l path $argv

    if test -z "$path"
        echo "usage: "
        echo "  mkpath path/to/file"
        echo "  mkpath path/to/dir/"
        return
    end

    if string match --quiet '*/' $path
        mkdir -p $path
    else
        touchp $path
    end
end

## dirs
function take
    if test -z "$argv[1]"
        echo "takefiles requires at least a new directory to create and usually files to move into it"
        echo "usage:"
        echo "'takefiles newdir file1 [file2 ...]'"
        return
    end

    # not only create the dir, move the files passed as args 2+
    mkdir -p $argv[1]
    # strip arg1
    set files $argv[2..]
    if test -z "$files"
        # with 1 arg, effectively works the asme as 'take'
        cd $argv[1]
        return
    end
    mv $files[1..] $argv[1]
    cd $argv[1]
    # PRN what if I don't wanna cd into the final dir? maybe have an alternative version of this that drops the final cd?
end
abbr mkdir 'mkdir -p' # I already use this in take and that's never been a problem so I suspect its always gonna be fine
#  BTW I understand why mkdir -p in a script/non-interactive shell would possibly be a problem (i.e. get one part of a path wrong and it just works)... though arguably that is a matter of writing a proper/tested script... anyways my impl here is never for non-interactive

# TODO better name for remkdir?
function remkdir
    # ensure dir exists AND is empty
    if test -d $argv
        # trash dir if it exists
        trash $argv
        if test $status -ne 0
            echo "failed to remove existing dir: $argv"
            return 1
        end
    end
    mkdir -p $argv
end

## cd_dir_of helpers
#
# zsh's =cmd expansion as fish abbreviation!
#   =fish => /opt/homebrew/bin/fish
function expand_zsh_equals
    set -l cmd (string replace --regex '^=' '' $argv)
    type --path $cmd
end
abbr --add zsh_equals --regex '=[^\b]+' --function expand_zsh_equals

function dir_of_man_page --wraps man
    set -l man_page $argv[1]
    if test -z "$man_page"
        echo "usage: dir_of_man_page <man page name>"
        return 1
    end
    # man -w <page> == shows path to man page
    set -l man_path (man -w $man_page)
    echo $man_path
end

function cd_dir_of_man_page --wraps man
    if test -z "$argv"
        echo "usage: cd_dir_of_man_page <man page name>"
        return 1
    end
    set -l man_path (dir_of_man_page $argv)
    cd_dir_of_path $man_path
end
abbr cdm cd_dir_of_man_page

function cd_dir_of_brew_pkg --wraps "brew list"
    set package_name $argv[1]
    if not set package_path (brew --prefix $package_name 2>/dev/null)
        # /opt/homebrew/Caskroom/<pkgname>
        set package_path "$(brew --caskroom)/$package_name"
        if test ! -d $package_path
            echo "abort... no prefix nor cask path found..."
            return 1
        end
    end
    echo "package_path: '$package_path'"

    cd_dir_of_path $package_path
end
abbr cdbrew cd_dir_of_brew_pkg

function cd_dir_of_command
    cd_dir_of_path (type --path $argv) # ~ zsh's =foo
end
abbr cdc cd_dir_of_command

function cd_dir_of_path
    set -l _cd_path $argv
    argparse --min 1 -- $argv or return 1

    if test ! -e $_cd_path
        echo "$_cd_path not found"
        return
    end

    # resolve symlinks (-f => recursively)
    if test -L $_cd_path
        echo -e "symlink:\n   $_cd_path =>"
        set _cd_path $(readlink -f $_cd_path)
        # PRN use `path resolve $_cd_path` instead (fish only)
    end

    if test -d $_cd_path
        # dir
        cd $_cd_path
    else
        # file
        cd (dirname $_cd_path)
    end

    log_ --apple_white "cd $(pwd)"
end
abbr cdd cd_dir_of_path

# *** bat ***
# if batcat exists map to bat
if command -q batcat # -q => w/o output
    # ubuntu
    function bat
        batcat $argv
    end
end

# *** batman (not man alone)...
#abbr man batman (stick with less for now, and custom TERMCAP env vars)
complete -c batman -w man # wrap man completions
function batman
    # honestly not many themes do much and many man pages only have minor colorings... TODO find a better tool to color for man pages specifically?
    BAT_THEME="Monokai Extended" command batman
end

# abbr cat bat # PRN go back to this if I don't like batls
abbr bath 'bat --style=header' # == header-filename (i.e. for multi files show names)
abbr batf 'bat --style=full'

if status --is-interactive
    # EXPERIMENTAL to see if I like it and if it causes issues (best approach for dotfile changes, esp material ones, is to use it and see what blows up and/or what is awesome)
    # ok wait, lets just use cat... I have to use command cat to get around (mostly) so why not just keep cat as the function name (or bat at least)
    # abbr cat batls # only expand cat => batls as a reminder to try to use this... if I like it I will reach for it and use it alongside ls/la and always instead of cat me thinks

    function _batls_file
        set path $argv
        if command -q bat
            # PRN inject language detection to override bat defaults that I don't like?
            bat $path
        else if command -q batcat
            # debian family => batcat to avoid clash... and my bat alias won't match command so I need this case too
            batcat $path
        else
            cat $path
        end
    end

    function _batls_dir
        set path $argv
        # todo other default args I like for ls?
        if command -q exa
            exa -al $path
        else if command -q eza
            eza -al $path
        else if command -q lsd
            lsd -al $path
        else
            ls -al $path
        end
    end

    function cat

        if not isatty stdin
            # use cases:
            #   stat /dev/fd/1 | cat
            #      # w/o checking if STDIN is a TTY... I would list the current directory!
            #
            #   I think if I wanna pipe to cat and have syntax highlighting I s/b just using bat directly...
            #   maybe this is another indicator that I shouldn't override cat and should maybe use a custom
            #   bat OR a new *at alias instead?
            #
            # bat $argv # this allows me to pass args for styling though... might be useful but I shouldn't be using bat args on cat IMO
            command cat $argv # FYI I could recursively call cat here
            return
        end

        if test -z "$argv"
            _batls_dir . # just like ls command
        end

        for path in $argv

            # PRN if multiple items => show each $path first?

            if test -f $path
                if string match -q 'image/*' (file --mime-type --brief $path)
                    if command -q imgcat
                        imgcat $path
                    else
                        echo "error, missing imgcat and $path is an image, aborting cat..."
                        return
                    end
                    continue
                end
                # for plain text files I wanna color them too.. cat would normally show the file so no harm in coloring the output, color would even be dropped if piped/non-interactive
                _batls_file $path
            else if test -d $path
                # override cat for dirs to list files, cat would normally error here so no harm in overriding that
                _batls_dir $path
                # FYI! ALL ELSE SHOULD NOT ALTER CAT COMMAND:
                # else if test -S $path; or test -c $path; or test -b $path; or test -p $path
                #     # -S socket, -c char dev, -b block dev, -p named pipe
                #     # file $path # show file type only # PRN add back ONLY if find a new name, do not use cat and replace cat's functionality (i.e. cat /dev/urandom should not show the file type) or cat /dev/tty .. that should still work wes... derphead
                #     command cat $path
                # else if test ! -e $path
                #     # real cat handles this gracefully so just use it
                #     command cat $path # cat: /foob: No such file or directory
                # else if test -t $path
                #     # echo "Terminal file descriptor: $path" # do not modify cat behavior for exotic file types
                #     command cat $path
            else
                # fallback is use cat directly... maybe just do this overall???
                command cat $path # FYI consider using this in a new condition above?
            end

        end

    end
end

function lspath
    # usage? # lspath | grep python ??

    for dir in $PATH
        if not test -d $dir
            continue
        end

        # PRN show file name, file type?, symlinks?
        log_ --apple_white --bold $dir
        ls -1 -F $dir
        log_blankline
    end

end

# ok cd to a file should take to its dir
if status --is-interactive

    if not functions -q _original_cd
        # on reload config files, don't redefine this, would fail anyways since already exists
        functions -c cd _original_cd # FYI don't just use builtin cd, cd has dirhistory tracking (i.e. for cd -)
    end
    # todo see ideas for testing in fish/run-tests.fish (careful w/ cd as it can't be subshelled)
    # PRN change behavior based on STDIN/OUT is/isn't a TTY?

    # TODO... more dir/file command ideas:
    #    https://github.com/wting/autojump
    #    jo (jump and open in Finder) => jo Movies
    #       think... z + open
    #       open -R (z --echo Claude) ???
    #       lolz I have `oz` already which kinda does this (not entirely... but make sure I need smth new before doing this, I couldn't recall oz when first thinking about this today :) )
    #    jc  # child of a dir
    #  fasd # https://github.com/clvv/fasd#introduction (see the alias ideas)
    #  locate (build db of paths and use with fzf/fasd/etc?)

    function supercd
        # TODO! package this up in a separate repo and support diff fallbacks? share like z/v/autojump (simple to install and use)
        #   do the same with other commands that I like, maybe a single package/repo with the best ones (i.e. cd to file name, pwdcp/cppath, etc)

        # TODO make cd default to supercd?
        #
        # super cd uses a series of fallbacks to try to cd to the dir requested
        #    cd /foo/bar     # 1. tried first
        #    z /foo/bar      # 2. tried second
        #    cdz /foo/bar    # 3. tried third - any way to just take first match from fzf and cd to it? and only open interactive if NO matches with fzf?
        #      think of cd gaining the ability to match like z does (fuzzy match to paths that I have not yet cd'd to so they're not in z's db)
        #      and if cdnew fails then we should a failure message, which would be rare I believe
        #      alternatively, I could index some commmon dirs and add them to z's db (maybe with a modified z command that uses this db set second)
        #    fzf --query /foo/bar  # 4. interactive selection

        cd $argv 2>/dev/null 1>/dev/null # ensure I use func so this can include file name
        if test $status -eq 0
            return
        end
        z $argv 2>/dev/null 1>/dev/null
        if test $status -eq 0
            return
        end
        # tmp idea... get all dirs (of current dir!) and query with fzf...
        # TODO if I like this, I should get the locate database working to speed it up?
        # fallback to interactive cd! with fd+fzf
        #   FYI fd does not use a db so it is gonna be slow when I target entire filesystem: /
        #  FYI this is now setup to work only with nested dirs (in contrast to `z` which can jump anywhere...
        #     this might not be the best way to do this...
        #     maybe that is why I had `fd /` ...
        #     lets just try this way and see how I feel
        #
        # FYI --select-1 auto selects if only one matching entry instead of showing fzf UI
        set selected_dir (fd --type d | fzf --select-1 --preview 'ls {}' --query "$argv")
        # TODO when I use locate, how about allow picking a file too (not just dirs) b/c I can use my cd below to handle that and maybe there is a file name I am targeting and I know nothing else about the path
        if test $status -eq 0; and test -e $selected_dir
            cd $selected_dir
            return
        end
        echo "no dir found to cd to"
    end

    function cd
        set -l path $argv[1]
        if test -f $path; and test (count $argv) -eq 1
            # only override IF path is a file and no other args, else let _original_cd handle it (including handling failures for multiple args)
            # PRN handle other file types as needed, not sure yet what might arise, I just wanted files for now
            _original_cd (dirname $path)
        else
            # calls here if path is empty, multi args, or single arg that is not a file (i.e. a dir)
            _original_cd $argv
        end
    end

end

# *** DISK USAGE ***
# only expand du, don't also alias
abbr du _du # sort by size (makes sense only for current dir1) => most of the time this is what I want to do so just use this for `du`
#  FYI I could add psh => '| sort -hr' global alias (expands anywhere)?
# retire: abbr du 'grc du -h'  # tree command doesn't show size of dirs (unless showing entire hierarchy so not -L 2 for example, so stick with du command)
abbr dua 'grc du -ha' # show all files (FYI cannot use -a with -d1)
#
# show only N levels deep
#   du1 => du -hd 1
abbr --add duX --regex 'du\d+' --function duX
function duX
    string replace --regex '^du' 'grc du -hd' $argv
end
#
abbr df 'grc df -h' # use command to avoid infinite recursion
# Mac HD: (if fails try df -h and update this alias to be be more general)
abbr dfm 'grc df -h /System/Volumes/Data'

# a few hard coded _du nested helpers
function _du3
    # REALLY JUST USE FINDER AT THIS POINT... can easily drill in  and move around with sizes cached
    _du "$argv[1]" "$argv[2]" 3
end

function _du2
    # todo if I like this then find a way to generalize it...
    #   one issue is now I am back to the path (first arg) being way to the left.... yucky
    #   but I also dont really want it to the right b/c then I have to pass all the other args
    _du "$argv[1]" "$argv[2]" 2
end

function _du
    # use this for du now? so I don't have to arrow back and put path in middle (before sort)
    set dir $argv[1]
    set threshold $argv[2] # empty to not filter
    if test -n "$threshold"
        # otherwise leave empty to not apply it
        set threshold "-t $threshold"
    end
    set levels $argv[3]
    if test -z "$levels"
        set levels 1
    end

    if not test -e $dir
        log_ --yellow "skipping non-existent dir $argv[2]"
        return
    end

    set cmd "grc du -h -d$levels $threshold $dir | sort -h --reverse"
    log_ --blue -- $cmd
    eval $cmd
end

function gpristine_nested_repos
    for i in *
        test -d $i && git -C $i reset --hard && git -C $i clean -dffx
    end
end

function review_huge_files
    # somewhat a reminder how I wanna clean things
    if test $USER = wes
        log_blankline
        log_blankline
        log_ --bold --brred "USE wesdemos for all VMs/containers/models/etc, do not put on both accounts... or share between them"
        log_blankline
        log_blankline
    end

    set threshold 100M
    if test -n "$argv"
        set threshold "$argv"
    end

    log_ --bold --white "USE FINDER FOR ~/repos .. often a few repos blow up => .venv or build/target dirs\n   just use this CLI entrypoint as a reminder for common spots and then finder the rest"
    log_ --bold --white "use gpristine on large repos that can be cleaned"
    log_blankline

    _du $HOME/.cache $threshold
    # .cache => packer, huggingface, whisper, vosk, lm-studio, package managers

    log_ --yellow "Check for other VM dirs in home dir => vbox, vmware fusion"
    _du $HOME/Parallels $threshold

    _du $HOME/.config $threshold
    _du $HOME/.local $threshold
    _du $HOME/.local/share $threshold
    _du $HOME/.ollama $threshold
    _du $HOME/Library/Application\ Support/pywhispercpp/models $threshold
    _du $HOME/Downloads $threshold
    _du $HOME/.Trash $threshold
    #_du $HOME/Library $threshold

    # might be a few BIG apps in there worth removing
    # _du /opt/homebrew $threshold
    _du /opt/homebrew/Cellar $threshold
    _du /opt/homebrew/Caskroom $threshold

    #  search these in finder... very easy to find HUGE repos
    #_du ~/repos # use finder to drill in... sometimes a few repos are MASSIVE

    log_ --red "FYI checking home dir is last so feel free to ctrl+c"
    _du $HOME # $threshold
    # todo docker image/container store
    # log files?
    # VM dirs in home dir
    # do on entire home dir last too? .. that way can ctrl+c before that point and work on first detected issues

    # package caches (get unruly over time)
    ##   also get moved at times?
    #_du $HOME/.local/share/NuGet # one of these is old! $threshold
    #_du $HOME/.nuget $threshold
    #_du $HOME/.npm $threshold
    #_du $HOME/.local/pipx $threshold
    #_du $HOME/.cache/uv $threshold
    #_du $HOME/.minikube/cache $threshold
    #_du $HOME/.vagrant.d/boxes $threshold
    #_du $HOME/.docker $threshold
    #_du $HOME/.gradle $threshold

    # maybe clears:
    #    ~/.vscode  # old extensions and stuff here? logs? 4.1G on wesdemos

end

## loop helpers (i.e. forr30<SPACE> for testing line height, not sure why I dont just use $LINES)
abbr --add forr --regex "forr\d*" --function forr_abbr
function forr_abbr
    set count (string replace "forr" "" $argv)
    if test -z "$count"; or test $count -eq 30
        echo 'echo LINES: $LINES'
        echo 'echo COLUMNS: $COLUMNS'
        return
    end
    echo "seq 1 $count | xargs -I {} echo {}"
end

##### find helpers #####
# WIP - new ideas to consider (added when trying to find ~/Library/Application\ Support/*elgato* dirs for streamdeck config)
# find directories by name
abbr --add findd --set-cursor 'find . -type d -iname "*%*"'
abbr --add finddr --set-cursor 'find . -type d -iregex ".*%.*"' # another idea to consider
# IDEAs: tree command for dirs? or exa?

###### ls/exa/eza/lsd/etc ######
# PRN port over zsh mods for ls to use eza (though I am happy with fish's ls currently)

###### tree ######

# - only show directories
#   - show w/ eza --only-dirs
#   - show w/ tree cmd's -d
function treed
    # PRN add treehd/treeud and add L expansions below too
    if command -q eza
        tree --only-dirs
    else
        command tree -d
    end
end

set package_dirs "node_modules|bower_components|.git|.venv|iterm2env"
set more_ignore_dirs "*.lproj" # in /Applications/*/Contents/Resources/*.lproj (I hate seeing these in normal tree output)

if status is-interactive
    function tree
        # TODO I might like to write something a bit more flexible for ignoring dirs... the globs are somewhat fragile... like I'd prefer *.lproj to be limited to Contents/Resources/*.lproj but that doesn't work
        #  what if I had a builder that looked at the path passed and based on it activated/inactivated ignore globs and maybe other parameters?
        # FYI verify icdiff (drop --icons and run -L1/2 if diffs to find them w/o lotsa scrolling)
        if command -q eza
            eza --tree --group-directories-first \
                --ignore-glob $package_dirs --ignore-glob "*.lproj" \
                --color-scale=all --icons \
                --git-repos --git-ignore $argv
        else
            command tree --dirsfirst --noreport --filelimit 100 \
                -I $package_dirs -I $more_ignore_dirs \
                --gitignore $argv
        end
        # else if command -q lsd
        #    lsd --tree --group-dirs first --ignore "node_modules|bower_components|.git" --color always $argv
        #    return
    end
end

# file types and corresponding options:
# - dotfiles/dirs
#   - show w/ eza --all
#   - show w/ tree cmd's -a
# - gitignores/ignores
#   - hide w/ eza --git-ignore
#   - hide w/ tree cmd's --gitignore
# - package dirs
#   - hide w/ eza --ignore-glob $package_dirs
#   - hide w/ tree cmd's -I $package_dirs

function treeh
    # show ignores + dotfiles/dirs but not package_dirs
    # FYI not quite like ag -h b/c that still hides .gitignore files and shows package dirs (flip of this one), work on naming over time
    if command -q eza
        eza --tree --group-directories-first --ignore-glob $package_dirs --color-scale=all --icons --git-repos --all $argv
    else
        command tree --dirsfirst --noreport --filelimit 100 -I $package_dirs -a $argv
    end
end

function treeu
    # u = unrestricted (like ag -u)
    if command -q eza
        eza --tree --group-directories-first --color-scale=all --icons --git-repos --all $argv
    else
        command tree --dirsfirst --noreport --filelimit 100 -a $argv
    end
end

# treeX => tree -L X
abbr --add _treeX --regex 'tree\d+' --function treeX
function treeX
    string replace --regex '^tree' 'tree -L' $argv
end
# treedX => treed -L X
abbr --add _treedX --regex 'treed\d+' --function treedX
function treedX
    string replace --regex '^treed' "treed -L" $argv
end
# treehX => treeh -L X
abbr --add _treehX --regex 'treeh\d+' --function treehX
function treehX
    string replace --regex '^treeh' "treeh -L" $argv
end
# treeuX => treeu -L X
abbr --add _treeuX --regex 'treeu\d+' --function treeuX
function treeuX
    string replace --regex '^treeu' "treeu -L" $argv
end

# *** *z functions to combine z cmd w/ opening editor to the repo root
function cz
    z $argv
    code (_repo_root)
end
function zz
    z $argv
    zed (_repo_root)
end
function oz
    z $argv
    open (_repo_root)
end
function nz
    z $argv
    nvim
end

export EDITOR="nvim"
# alt+o/v allows editing current command line thanks to EDITOR variable

#### nvim:

# nvim server mode
abbr nvim_start_server_attached "nvim --listen localhost:6666" # and attach to its UI
abbr nvim_start_server_not_attached "nvim --listen localhost:6666 --embed" # don't attach to its UI
# note headless is not the same as embed, embed allows remote UI connections
abbr nvim_client_attach_ui "nvim --server localhost:6666 --remote-ui" # pass files too, to open
abbr nvim_client_send_command "nvim --server localhost:6666 --remote-send"
abbr nvim_client_eval_expr "nvim --server localhost:6666 --remote-expr"
abbr nvim_client_open_files_in_new_tabs "nvim --server localhost:6666 --remote-tab" # open file(s) in new tab(s)
# fyi :detach when done, or :quit will kill server
# server is useful for test automation
# TODO consider porting some/all "open with" functionality to using a server?
# not yet in NVIM: --remote*-wait variants, and servername/list (from vim)

# FYI I changed session restore to use passed files/paths to open after session restored, so now I want that to only be if I explicitly ask for a file to be opened and not show dir every time I open, show last file open in most cases... I might need to alter this later
abbr n nvim # n<space> is perfect now
abbr nr --function nr_expand
function nr_expand
    if not string match --quiet (_repo_root) (pwd)
        echo -n "cd (_repo_root); "
    end
    echo nvim
end

abbr nd --function nd_expand
function nd_expand
    if not string match --quiet $WES_DOTFILES (pwd)
        echo -n "cd $WES_DOTFILES; "
    end
    echo nvim
end

abbr nh --function nh_expand
function nh_expand
    if not string match --quiet $WES_DOTFILES/.config/hammerspoon (pwd)
        echo -n "cd $WES_DOTFILES/.config/hammerspoon; "
    end
    echo nvim
end

abbr nn --function nn_expand
function nn_expand
    if not string match --quiet $WES_DOTFILES/.config/nvim (pwd)
        echo -n "cd $WES_DOTFILES/.config/nvim; "
    end
    echo nvim
end

if command -q nvim
    abbr vim nvim
    abbr vi nvim
end

function nvselect
    #    use with :CopyFileSystemLink cmd
    # nvselect ~/repos/github/g0t4/dotfiles/.config/nvim/lua/non-plugins/github-links.lua:83

    set link $argv[1] # path/too/foo.txt:10-20
    set file (string split ':' $link)[1]
    set range (string split ':' $link)[2]
    set start_line (string split '-' $range)[1]
    set end_line (string split '-' $range)[2]

    if test -z "$end_line"
        set end_line $start_line
    end

    set line_count (math "$end_line - $start_line")
    nvim +$start_line +"normal! V{$line_count}jzz" "$file"
end

# *** free
if command -q free
    abbr free 'free -wh'
    abbr frees 'free -whs 1' # still, prefer using watch
end

# *** fzf "widgets" for selecting a file to pass to a command
function _fzf_nested_dir_widget -d "Paste selected directory into command line"
    set -l dir (fd --type d . | fzf --height 50% --border)
    if test -n "$dir"
        commandline -i -- (string escape -- "$dir")
    end
    commandline -f repaint
end

function _fzf_nested_file_widget -d "Paste selected file into command line"
    # TODO could I add a toggle to this fzf to switch to/from unrestricted? IIRC you can do that...
    set -l file (fd --type f . | fzf --height 50% --border)
    if test -n "$file"
        commandline -i -- (string escape -- "$file")
    end
    commandline -f repaint
end

# --- fzf per-directory MRU cache --------------------------------------------

set -g FZF_MRU_DIR ~/.cache/fzf-mru
set -g FZF_MRU_CAP 30 # per dir limit, only most recent are gonna matter anyways

function __fzf_mru_key
    pwd | shasum | string split ' ' | head -n 1
end

function __fzf_mru_file --argument-names picker
    mkdir -p $FZF_MRU_DIR/$picker/
    echo $FZF_MRU_DIR/$picker/(__fzf_mru_key)
end

function __fzf_mru_read --argument-names picker
    set -l file (__fzf_mru_file $picker)
    test -f $file; or return

    cat $file | while read -l path
        # check that the files still exist
        test -e "$path"; and echo "$path"
        # PRN async write (fire and forget) to save filtered list into file?
    end
end

function __fzf_mru_write --argument-names picker path
    set -l file (__fzf_mru_file $picker)

    begin
        echo "$path"
        test -f $file; and grep -Fxv -- "$path" $file
    end | head -n $FZF_MRU_CAP >$file
end

# ---------------------------------------------------------------------------

function _fzf_nested_file_unrestricted_widget \
    -d "Paste selected file (including hidden) into command line"

    set -l file (
        begin
            __fzf_mru_read unrestricted
            fd --type f . -u | grep -Fxv -f $FZF_MRU_FILE 2>/dev/null
        end | fzf --height 50% --border
    )

    if test -n "$file"
        __fzf_mru_write unrestricted "$file"
        commandline -i -- (string escape -- "$file")
    end

    commandline -f repaint
end

function _fzf_nested_both_file_and_dirs_widget -d "Paste selected file or directory into command line"
    # btw `diff_two_commands 'fd --type f --type d' 'fd'` differ in symlinks (at least)
    set -l file (fd . | fzf --height 50% --border)
    if test -n "$file"
        commandline -i -- (string escape -- "$file")
    end
    commandline -f repaint
end

function _fzf_nested_git_commit_widget -d "Pick a git commit_hash"
    # TODO look at commandline! and decide based on the git subcommand?!
    #  git diff => pick a commit_hash
    #   heck I could do this and add defaults for all sorts of commands (and fallback could ask AI to pick a picker!)

    set log_format "%C(white)%h%Creset %Cblue%cr%Creset%C(auto)%d%Creset %s"
    set -l commit_hash $(
        git log --reverse --format="$log_format" \
        | fzf --height 50% --border --ansi --accept-nth=1
    )
    if test -n "$commit_hash"
        commandline -i -- (string escape -- "$commit_hash")
    end
    commandline -f repaint
end

bind_both_modes_default_and_insert alt-shift-d _fzf_nested_dir_widget
bind_both_modes_default_and_insert alt-shift-f _fzf_nested_file_widget
bind_both_modes_default_and_insert alt-shift-u _fzf_nested_file_unrestricted_widget
bind_both_modes_default_and_insert alt-shift-b _fzf_nested_both_file_and_dirs_widget
# TODO what all pickers for git history might I want?
bind_both_modes_default_and_insert alt-shift-g _fzf_nested_git_commit_widget

# *** chmod,chgrp,chown,chsh
abbr chmx "chmod +x"
abbr chmR "chmod -R"

function prepend_to_file

    # uses ed command to prepend a line
    # 0a specifies to add at beginning of buffer
    # ok to be multiple lines... . is effectively marks when to stop appending content and then wq commands save and quit (just like vim which is based on ed)

    read _stdin
    printf "0a\\n$_stdin\n.\nwq\n" | ed -- "$argv[1]"

end

function shebangify
    # chmod +x + shebang

    set script_file $argv[1]
    set extension (string lower $(path extension $script_file))

    touch $script_file
    chmod +x $script_file

    if not string match --regex --quiet '.(sh|zsh|fish|bash)$' $extension
        echo "not known script type"
        return 1
    end

    if string match --quiet --regex '^#!.*' (head --lines=1 -- $script_file)
        echo "shebang already present"
        return 0
    end

    # strip leading .
    set dotless_extension (string replace "." "" $extension)

    echo "#!/usr/bin/env $dotless_extension\n" | prepend_to_file $script_file

end
