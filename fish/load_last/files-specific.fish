
# *** ls
# still not using exa/eza (not worth hassle, esp b/c fish builtin ls/la colors work well enough)
abbr lat "ls -alht" # -t == sort by time
abbr las "ls -alhS" # -S == sort by size
abbr la "la -h" # use fish builtin `la` and pass -h by default now

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

    # why? one reason is I can install beta releases of these tools and uninstall brew package and not lose out on completions

end

function _shorts
    set --universal wes_recording_youtube_shorts_need_small_prompt 1
end

function _not_shorts
    set --erase wes_recording_youtube_shorts_need_small_prompt
end

function _recording

    # PRN if calling repeatedly (ie on spal activate) causes problems => return if already in recording mode?

    _disable_fish_suggestions

    # ? use diff history file i.e. for ctrl+R history pager search
    # set -U fish_history recording # ~/.local/share/fish/recording_history

    # TODO disable showing return code failures in prompt? wait to see how much of a hassle this is when editing some new videos

    # FYI - I added Keyboard Maestro macros to:
    #   on screenpal (launch or activate) =>
    #       /opt/homebrew/bin/fish -c "_recording" 2>&1
    #       PRN on activate too?
    #       FYI can take a second or two to apply to all windows
    #   on screenpal quits =>
    #       /opt/homebrew/bin/fish -c "_not_recording" 2>&1
    # ?? PRN quicktime too?

end

function _not_recording
    _enable_fish_suggestions
    # set -U fish_history default # revert to ~/.local/share/fish/fish_history
end

function _disable_fish_suggestions
    #https://fishshell.com/docs/current/language.html#envvar-fish_autosuggestion_enabled
    set -U fish_autosuggestion_enabled 0
    # -U => universal applies to all windows (can be slight lag to apply to all windows, but most of the time its nearly immediate)
end

function _enable_fish_suggestions
    set -U fish_autosuggestion_enabled 1
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
        set levels = 1
    end


    if not test -e $dir
        log_ --yellow "skipping non-existent dir $argv[2]"
        return
    end
    log_ --blue -- $dir "$threshold" # show both
    grc du -h -d$levels $threshold $dir | sort -h --reverse
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
abbr --add findd --set-cursor=! 'find . -type d -iname "*!*"'
abbr --add finddr --set-cursor=! 'find . -type d -iregex ".*!.*"' # another idea to consider
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

# *** see treeify ideas in  fish/load_last/globals-specific.fish

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
export EDITOR="vim"


#### nvim:
# FYI I changed session restore to use passed files/paths to open after session restored, so now I want that to only be if I explicitly ask for a file to be opened and not show dir every time I open, show last file open in most cases... I might need to alter this later
abbr n nvim # n<space> is perfect now
abbr nh nvim # short for nvim here => nvim . => nvim (all the same)
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
