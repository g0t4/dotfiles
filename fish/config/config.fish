# fish startup:
# - https://fishshell.com/docs/current/language.html#configuration
# - https://fishshell.com/docs/current/tutorial.html#tut-config

# TODO review feature flags: https://fishshell.com/docs/current/language.html#future-feature-flags
# TODO review options, i.e.:
set fish_greeting ""

if status is-interactive
    # status --is-login
    # Commands to run in interactive sessions can go here
end

# TODO => use ~/.config/fish/conf.d/ OR source here?

# find WES_ paths
# ! OPTIMIZE readlink/dirname calls here are very expensive (2,4,2 ms on each of these three lines - fix this)
if test (uname) = Darwin
    set -g IS_MACOS true
    set -g IS_LINUX false
else
    # assume linux, differentiate distros later if needed
    set -g IS_MACOS false
    set -g IS_LINUX true
end

set -g WES_BOOTSTRAP ~/repos/wes-config/wes-bootstrap
set -g WES_DOTFILES ~/repos/github/g0t4/dotfiles
export WES_DOTFILES=$WES_DOTFILES

# source $WES_DOTFILES/fish/load_first/*.fish # glob not working for multiple files in dir, just one?!
if status is-interactive
    for file in $WES_DOTFILES/fish/load_first/interactive_only/*.fish
        source $file
    end
end

for file in $WES_DOTFILES/fish/load_first/*.fish
    source $file
end
for file in $WES_DOTFILES/zsh/compat_fish/*.zsh
    source $file
end

if status is-interactive
    for file in $WES_DOTFILES/fish/interactive_only_last/*.fish
        source $file
    end
end

# optional, private config
if test -f $HOME/.config/fish/config-private.fish
    source $HOME/.config/fish/config-private.fish
end

# optional, iterm2 shell integration (must be installed here, i.e. by installing via iterm menus)
if test -e $HOME/.iterm2_shell_integration.fish

    source $HOME/.iterm2_shell_integration.fish

    # *** ask-openai variables to identify env (i.e. sshed to a remote shell):
    if test -f /etc/os-release
        set ask_os (cat /etc/os-release | grep '^ID=' | cut -d= -f2)
    else
        set ask_os (uname) # Darwin, Linux, etc
    end

    function split_pwd_on_path_change --on-variable PWD
        # this is a hack to fix the fact that "path" variable is not reliable
        #   when a program is running remotely (over SSH)
        #   the path flips to a local path
        #   run `sleep 60` and check Inspector to see this happen
        #   when program halts, it reverts to a correct, remote, path

        # this is for my iTerm2 split pane/tab/window and preserve path/SSH combo
        if functions -q iterm2_set_user_var
            iterm2_set_user_var split_path $PWD
        end
    end

    function iterm2_print_user_vars
        # mostly to avoid stale values after exist SSH, to set back to values the host has
        # FYI this is called by iterm2_shell_integration.fish on every prompt
        iterm2_set_user_var ask_shell fish
        # FYI caching value in $ask_os, to avoid penality on every prompt
        iterm2_set_user_var ask_os "$ask_os"
    end
else
    # TODO warn? and tell to use ansible to setup?
end

# if llvm-18 present, use it, in future detect which version I want or set it per env?
#   FYI test -e takes 23us in fish on m1 mac so that is acceptable overhead for startup files
if test -e /usr/lib/llvm-18/bin/
    set -x PATH /usr/lib/llvm-18/bin $PATH
end

## WHY fish?
# PROS:
# - menu completion with tooltip (desc) for not just current menu selection but all current menu options
#   function foo --description 'bar the doo boo bie' # explicit function descriptions (shows in completion)
# - suggestions (inline) out of the box just work => that said I am more of a fan of expanding aliases but we shall see if suggests win me over
#   - I am already liking suggestions based on completions for things I've never done before
#   does it have a way to show multiple suggestsions like pwsh? might be nice to use one-off
#   - like this for cd'ing a dir or two!
# - syntax highlighting out of the box (just works)
# - exit codes show in default prompt (when failure) => FYI can do this in zsh too, and zsh can show exit codes before next prompt which is useful too
# - readable scripts
#   - query env: status is-interactive/is-login
#   - or, and => &&, ||
#   - IIUC line wraps w/o a continuation char?
# - man pages for builtins are direct (don't have to use man zshbuiltins)
# - abbreviations (expand) => equiv of my zsh ealias
#   - AND aliases (don't expand)
#   - cursor position in aliases, function to build expansion (dynamic), regex matching expansions
# - status builtin
#     status basename/dirname => of current script, AMEN
# - type
#   - on a func => shows file path & syntax colors output!
# - prompt
#   - default `fish_prompt` is well partitioned into funcs (i.e. prompt_pwd) / sub funcs to override just what I want w/o rewrite the whole thing
#   - prompt functions take -h/--help flag! => `prompt_pwd -h` and return a man page of info!
# - conventions
#   builtins: -q/--query (boolean testing), -n/--names (list) [type,set,builtin,functions so far all have these]
# - set (vars)
#   -l/--local
# - command substitution
#   - () works like $() in zsh
# - autoloading
#   - several config dirs meant to lazy load customizations (ie a function)
#   - `funcsave foo`,`funced foo` to save/edit autoload function file, i.e. ~/.config/fish/functions/foo.fish
# - cd hacks:
#   foo => cd foo
#   fb => cd foobar  #zsh doesn't support this! don't have to have sequential letters in a given dirname!
# - history
#   up/down filters on prefix already typed
#       - also shows fuzzy matches in the middle of history commands (TODO look up behavior of this)
#         => really like w/ dotX aliases, i can type gst (as always) and up arrow pulls back `dotgst` if I last used it! yes! same w/ gsl=>UP=>dotgsl,glo etc
# - fish line editor (name?)
#   `type up-or-search` shows 'widget (name?)' impl colorized
# - variables are not split on interpolation!
#    i.e. `mkdir $foo` where `set -l foo "foo bar"` doesn't make two dirs, just one named "foo bar" with space in name
#    universal => vars shared across instances of zsh (PRN should I be versioning the corresponding file fish_variables or not?)
# - `fish --profile=file` => on exit dumps to file! awesome
#     `fish --profile-startup=file` => after startup dumps to file
# - argparse/fish_opt clear/concise option specs + validation (ie argparse --min 1 => warns if less than 1!)
# - control flow
#    - blocks all end with `end` => amen noo more esac,fi,done,etc
#    - if test/string reads so nicely! (drop verbose ; then crap)
#       no crap about [] and [[]] and (()) yuck!!
#       to be fair zsh can use `if test` => however it has `; then` on end of line yuck
# - comments
#    can have comments between line continuation lines!
#       can't in zsh
# - variables
#   - all vars are lists (interesting, perhaps easier to reason about?)
#   - AFAIK no concept of a dict/hash/map (I bet someone has a lib to do this with lists)
# CONS:
# - abbreviations cannot be used as aliases too (like I setup in my ealias lib in zsh)... so an alias must be defined additionally else you cannot use abbreviations inside a function for example... seem to only expand in fish line editor?
# - ?
# UNCERTAINS:
# - which/whence in zsh take patterns (-m) => does fish have this? (haven't seen it yet in type man page) could use `functions | grep foo`?
# - does fish have <() or =() command substitution like zsh to pass tmp file to say icdiff
#  *** z => not fsh :( ... can I run as zsh script from fish? or is it integrated into zsh as a widget or? )
#     TODO test: https://github.com/jethrokuan/z   (fish port)
#           via fisher: https://github.com/jorgebucaran/fisher
# - use type instead of whence/which? type doesn't resolve for abbreviations? is there a better way to resolve anything (including the file its defined in like whence -v/f does in zsh)?
#   how can I pattern match on all types? i.e. which -m \*foo\* in zsh
# - why does `git push --<TAB>` not show --recurse-submodules, but auto suggestion does once `--re` typed?
# - string builtin:
#    string replace ... etc (how do I feel about this after using it a bit?)
# - set => I like foo="bar" syntax (not seeing this in fish examples and funcs so must not be supported, I get it, this is part of that compact shell syntax that becomes unruly but that said it is so common in programming languages!)

## ! TO MIGRATE
# - z cmd & see what fishisms exist to do the same?
# * ask-openai so I can ask when I am learning!
# lower priority:
#  - cdc?, =cmd expansion?
#  .., cdr, etc

## TO READ UP ON / USEs
# - event handlers: https://fishshell.com/docs/current/language.html#event-handlers
# - ~/.config/fish/functions/ + funcsave foo => save to autoload files! => only thing is I don't know that I like each function having its own file vs grouping related? that said autoload is a benefit, plus related funcs should be prefixed the same and thus grouped that way so ok... maybe!

## TO HABITUATE

## PROMPT
# fish_prompt is the default prompt function, also fish_right_prompt
#   default uses prompt_login, prompt_pwd, fish_vcs_prompt (override to change/hide)

# TMP use bash if CWD is course dir
#  KEEP THIS AT END OF startup files so it doesn't block loading something else that might matter... just in case
if status --is-interactive
    # don't want for non-interactive (i.e. fish -c "...")
    if string match --quiet --regex "g0t4/.*course.*-bash.*" "$(_repo_root)"
        bash
    end
end
