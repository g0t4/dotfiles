# * ok lets do it! I want vi bindings!
# PRN move this elsewhere?
# https://fishshell.com/docs/current/interactive.html#vi-mode
fish_vi_key_bindings
function bind_both_modes_default_and_insert
    # FYI this is for using vi-mode, to bind in both normal and default modes
    #  default also works in non-vi-mode (emacs like)
    #  NOTE default == normal in vi-mode
    bind -M default $argv
    bind -M insert $argv
end

# * add back ctrl-R? or should I just get used to /?
bind_both_modes_default_and_insert ctrl-r history-pager

# * idea... to simulate my favorite vim motions/command combos
#   unfortunately, "word" doesn't match between fish and vim... fish treats - as a boundary too
#   so I am going with word == bigword
bind -M default d,i,w _diw
function _diw
    commandline -f backward-bigword
    commandline -f kill-bigword
end

bind -M default c,i,w _ciw
function _ciw
    commandline -f backward-bigword
    commandline -f kill-bigword
    set fish_bind_mode insert
    # alternatively use `bind -m insert` to switch modes after the bound function completes
end

# * half baked ideas:
#
# you surround like
bind -M default y,s,i,w _ysiw
function _ysiw
    set cmd (commandline)
    set cursor_0based (commandline --cursor)

    # TODO what to do when cursor is on whitespace? for now it grabs two words (one before and one after) which might be actually useful

    # Find word boundaries
    # set before (string sub --length $cursor_0based -- "$cmd")
    # set after (string sub --start (math $cursor_0based + 1) -- "$cmd")

    # # Use regex to find word under cursor
    set start_1based (string match --all --index --regex '\s\w' "foo the bar" | cut -d' ' -f1 | awk "\$1 <= $cursor_0based" | tail -n1)
    set end_1based (string match --all --index --regex '\w\s' "foo the bar" | cut -d' ' -f1 | awk "\$1 > $cursor_0based" | head -n1)

    # btw end_1based is the last char of the word
    if test "$end_1based" = ""
        set end_1based (string length $cmd)
    end

    if test "$start_1based" = ""
        set start_1based 1
    else
        # whitespace is the first char in the start_1based match
        # ... so, add one to get start of word
        set start_1based (math $start_1based + 1)
    end

    set word (string sub --start $start_1based --end $end_1based "$cmd")

    set before (string sub --start 1 --length (math $start_1based - 1) -- "$cmd")
    set after (string sub --start (math $end_1based + 1) -- "$cmd")

    # TODO handle '/" => multiple binds? ysiw' and ysiw" ? for now just use '
    set new_cmd "$before'$word'$after"

    # # testing
    # commandline --append "'s$start_1based/c$cursor_0based/e$end_1based'"
    # commandline --append " '$word'"
    # commandline --append " '$before' '$after'"

    commandline --replace -- $new_cmd
    commandline --cursor (math $cursor_0based + 2) # Move cursor forward after opening quote
end
#
#
bind -M default v,i,w _viw
function _viw
    set fish_bind_mode visual
    commandline -f backward-bigword
    commandline -f begin-selection
    commandline -f forward-bigword
    # this does select the text, but I am not sure what else I can do with it?
end
#
# function _copy_selection
#     set -l buf (commandline)
#     set -l start (commandline --selection-start)
#     set -l end (commandline --selection-end)
#
#     echo $start/$end
#
#
#     if test $start -lt 0
#         return # no selection
#     end
#
#     set -l selection (string sub --start (math $start) --end (math $end + 1) -- "$buf")
#
#     echo -n $selection pbcopy # use xclip/wl-copy if not macOS
#     commandline -f cancel
# end
#
# copy word? (but don't delete/kill it)
# bind -M default y,i,w _yiw
# function _yiw
#     set fish_bind_mode visual
#     commandline -f backward-bigword
#     commandline -f begin-selection
#     commandline -f forward-bigword
#     _copy_selection
# end
#

# TODO! should I move these bindings to nvim too?!
# undo/redo should work in insert mode too
bind_both_modes_default_and_insert -M insert ctrl-z undo # TODO ctrl-z not working in normal mode, IS ok in insert mode now?!
bind_both_modes_default_and_insert -M insert ctrl-Z redo
# FTR, fish_default_key_bindings has the following, of which I am only mapping ctrl-z/Z for now:
#
# bind | rg -i undo
#   bind --preset ctrl-/ undo
#   bind --preset ctrl-_ undo
#   bind --preset ctrl-z undo
#
# bind | rg -i undo
#   bind --preset ctrl-/ undo
#   bind --preset ctrl-_ undo
#   bind --preset ctrl-z undo
