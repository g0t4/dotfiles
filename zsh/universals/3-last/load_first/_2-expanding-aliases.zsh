
# DOES NOT NEED TO BE POST-COMPINIT # ! just needs to load before 3-last/helper scripts
# ! must load after completions.zsh (dependent on menuselect keymap for binding below)

# ealias must be global (else ealias calls below, i.e. bgr, won't be registered as ealias and will be plain old alias)
typeset -ag ealiases
typeset -ag ealiases_no_space_after
# PRN support cursor placement after expansion! then I can have `ealias gcmsg='git commit -m ""'` and cursor is placed between quotes after expansion! this could replace nospaceafter! or compliment it!
#   see this for alias with a placeholder (might have tab completion through placeholders?) https://github.com/yuki-yano/zeno.zsh => way more advanced than I need for now but still cool idea

function ealias()
{
    # parse options and remove (-D) them from positional args
    local -a flags # bool
    zparseopts -E -a flags -D -- g NoSpaceAfter # FYI `man zshmodules` /zparseopts
    # -E don't stop on first non-matching flag => allow args before/after aliasdef

    local -a positional_args=("${(@)argv}") # remaining are positional (assumes all flags parsed)
    if [[ -z $positional_args ]]; then
        echo "aborting - no alias definition supplied"
        echo "    USAGE: ealias [-g] [-NoSpaceAfter] aliasname=aliasdef"
        echo "    OR: ealias [-g] [-NoSpaceAfter] aliasname aliasdef"
        return -1
    fi
    if (( ${#positional_args[@]} > 2 )); then
        echo "aborting - invalid alias definition (> 2 positional args)"
        echo "    USAGE: ealias [-g] [-NoSpaceAfter] aliasname=aliasdef"
        echo "    OR: ealias [-g] [-NoSpaceAfter] aliasname aliasdef"
        return -1
    fi
    local aliasdef
    if (( ${#positional_args[@]} == 1 )); then
        # one positional arg => assume `foo=bar` format
        aliasdef="${positional_args[@]}"
        # PRN validate =?
    else
        # two positional args => assume `foo bar` format
        aliasdef="${positional_args[1]}=${positional_args[2]}"
        # PRN validate no = in aliasname
    fi

    local aliasname=${aliasdef%%\=*}
    if (( ${flags[(I)-g]} )); then
        # global alias can be used anywhere (not just in command position)
        # echo "global: $aliasdef" # troubleshoot
        alias -g $aliasdef
    else
        alias $aliasdef
    fi
    # why alias is used under the hood:
    # - reuse zsh's _expand_alias func
    #   - including w/ global aliases now
    #   - ealias essentially flags which aliases should expand automatically (that's really it for now!)
    # - fallback if expansion fails, or doesn't trigger
    # - supports which/whence lookup
    # PRN would love to have tooltips too like I get with pwsh so tab completion shows the alias value too! that might be smth I can do with zstyle for aliases??

    # PRN generalize nospaceafter to a set of options (i.e. -NoSpaceAfter, -NoColorize?, etc)
    #   FYI don't have to track -g option since alias -g is the only diff there
    # support for -NoSpaceAfter like in my pwsh impl
    if (( ${flags[(I)-NoSpaceAfter]} )); then
        # echo "NoSpaceAfter: $aliasdef" # troubleshoot
        ealiases_no_space_after+=(${aliasname})
    fi

    # add alias name to ealiases array, i.e. `ealias foo=bar` maps to `alias foo=bar` and ealiases+=(foo)
    ealiases+=(${aliasname})
    # for -NoSpaceAfter and -g (global aliases) => add metadata to a separate ealiases_metadata array?
}

function expand-ealias()
{
    # TLDR: trigger zsh's alias expansion any time the cursor is right after an ealias (NOTE not after non-ealias aliases which I don't want expanded automatically)
    local last_word_left_of_cursor=$(echo $LBUFFER | awk '{print $NF}') # v2 => match last word left of cursor and if its an ealias then trigger zsh's expand alias

    # FYI troubleshoot w/ PREDISPLAY="\n..." https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
    # POSTDISPLAY="
    # last_word_left_of_cursor: $last_word_left_of_cursor"

    if (( ${ealiases[(Ie)$last_word_left_of_cursor]} )); then
        # FYI (I) = case insensitive, (e) = not pattern match
        LBUFFER=${LBUFFER%%[[:space:]]} # trim last space => so that right after completion selection (on space) this triggers alias expansion too (else selection adds space and then ealias expansion won't work)
        local initial_LBUFFER=$LBUFFER
        zle _expand_alias # zsh function to expand any alias (hence check ealias first) => FYI _expand_alias is default bound to ^Xa (via compinit)
        # FYI completion regular style (default=true) means aliases are only expanded in command position, global style (default=true) decides if _expand_alias expands global aliases
        if [[ $LBUFFER != $initial_LBUFFER ]]; then
            # FYI could check rc of _expand_alias to confirm expansion but I believe that is redundant?
            if (( ${ealiases_no_space_after[(Ie)$last_word_left_of_cursor]} )); then
                _ealias_expanded_no_space_after=true # used by my magic-space widget below to not add space in some situations (ie gcmsg)
                # FYI I could use last_word_left_of_cursor in calling widgets (if I needed to get metadata but lets cache the metadata here instead)
            fi
        fi
        zle expand-word
        return 0
    fi
    return 1
}

function expand-ealias-then-magic-space()
{
    _ealias_expanded_no_space_after=reset
    zle expand-ealias
    if [[ $_ealias_expanded_no_space_after != true ]]; then
        zle magic-space
    fi
}

function expand-ealias-then-accept-line()
{
    zle expand-ealias
    # zle add-colorize-command-python # this is a separate widget I am working on (not shared, yet)
    zle accept-line
    POSTDISPLAY="" # i.e. clear ask-openai messages
}

function expand-ealias-then-accept-line-without-colorize(){
    # temp - disable colorize for one command
    zle expand-ealias
    zle accept-line
    POSTDISPLAY="" # i.e. clear ask-openai messages
}

# register UDF widgets above
zle -N expand-ealias
zle -N expand-ealias-then-accept-line
zle -N expand-ealias-then-magic-space
zle -N expand-ealias-then-accept-line-without-colorize

bindkey -M emacs ' '  expand-ealias-then-magic-space # intercept (space) => expand alias first (space after word, or space to select completion)
bindkey -M emacs '^ ' magic-space     # (control-space) => bypass completion (i.e. for troubleshooting)
bindkey -M emacs '^M' expand-ealias-then-accept-line # intercept (return) => expand alias first! (return on command line)
bindkey -M menuselect '^M' expand-ealias-then-accept-line # (return to select completion), also adding accept-line to run it so return means execute selection (normally return just selects)
bindkey -M emacs '^J' expand-ealias-then-accept-line-without-colorize # Ctrl-J defaults to accept-line, repurpose to expand w/o colorize too (i.e. when colorize is not desireable/misbehaving)
# FYI '^I'(tab) is later bound to fzf-complete (or w/o fzf maps to expand-or-complete == try shell expand (not aliases) or start complete) so don't bother overriding it here, let tab start tab completion only! later space/return selects completion and triggers bindings above
# Test Cases:
#  dcr<SPACE> => expands to 'docker container run'
#  dcpsa<RETURN> => expands to 'docker container ps -a', colorizes, then executes it
#  dcr<CTRL+SPACE> => just adds space w/o expanding => 'dcr '
#  dcr<CTRL+J> => expands to 'docker container run', no colorizing, then executes it
#  dcr<TAB> => starts tab completion (not altered here currently)
#     <SPACE> => select completion and attempt to expand alias as if typed a space right after selection
#     <RETURN> => select completion, expand if alias, colorize, and execute it
# New Test Cases:
#  echo foo<SPACE> => expands to 'echo foo '  (assuming foo is a global ealias)
#  which _ealias_ => resolves
#    which _global_ealias_ => resolves based on alias value
#    which \_global_ealias_ => resolves based on alias name

##  FIRST EALIASes!
ealias bgr="bindkey | grep -i" # search bind keys easily
# tests
# ealias foo="echo oof" -g
# ealias -g doo="echo oof"
# ealias boo="echo oob"

## origins, IIRC I started with https://github.com/zigius/expand-ealias.plugin.zsh/blob/master/expand-ealias.plugin.zsh


# Ideas:
# - "git c" => "git commit" [support spaces in alias/abbreviation, i.e. in https://zsh-abbr.olets.dev/essential-commands.html#expand-them)]
#       but, tab completion seems superior b/c it doesn't require definitions (beyond completions) and is just a tab instead of space (to expand)

