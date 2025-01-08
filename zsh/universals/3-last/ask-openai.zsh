# FYI I clear POSTDISPLAY on accept-line in other code I have yet to share (expanding aliases), to clear asking/failure messages from below the command prompt, uncomment and use the following for now:
# zle -N clear_post_display_then_accept_line_widget
# bindkey -M emacs '^M' clear_post_display_then_accept_line_widget
# function clear_post_display_then_accept_line_widget(){
#     POSTDISPLAY=""
#     zle accept-line
# }


_new_line=$'\n'

function _set_post_display(){
    POSTDISPLAY="${_new_line}$@"
}

# vars for subshells to pass back openai response (via tmp files)
RESPONSE_POSTDISPLAY_FILE=$(mktemp)
RESPONSE_BUFFER_FILE=$(mktemp)
MAINSHELL_PID=$$

zle -N ask_openai_widget
bindkey -M emacs '^B' ask_openai_widget
function ask_openai_widget(){

    _set_post_display "asking openai..."

    last_question_asked=$BUFFER # think question history limited to 1 item currently, b/c question doesn't go into command history (never executed)

    {
        # subshell to avoid blocking zsh (so POSTDISPLAY shows "asking...")
        #   alternative: append " # asking..." to buffer like I do in powershell (cons: double undo to get back to original question, pros: Ctrl+C to kill request, unsure?)

        _python3="${WES_DOTFILES}/.venv/bin/python3"
        _single_py="${WES_DOTFILES}/zsh/universals/3-last/ask-openai/single.py"
        response=$( $_python3 $_single_py 2>&1 \
            <<STDIN_CONTEXT
env: zsh on $(uname)
question: $BUFFER
STDIN_CONTEXT
)
        # 2>&1 so STDERR ends up in POSTDISPLAY too (else its printed to terminal, messing up prompt)
        exit_code=$?

        if [[ $exit_code == 2 ]]; then
            # exit 2 => troubleshooting mode
            # *** type "dump" then trigger ask
            echo "[CONTEXT]:${_new_line}${response}" > $RESPONSE_POSTDISPLAY_FILE
        elif [[ $exit_code != 0 ]]; then
            echo "[FAIL]: $response" >  $RESPONSE_POSTDISPLAY_FILE
        else
            echo "$response" > $RESPONSE_BUFFER_FILE
            echo "done" > $RESPONSE_POSTDISPLAY_FILE
        fi

        kill -SIGUSR1 $MAINSHELL_PID # signal main shell that response is ready

    } &|

}





function on_openai_done_trap() {
  zle update_zle_with_response_widget
}

trap 'on_openai_done_trap' SIGUSR1

zle -N update_zle_with_response_widget
function update_zle_with_response_widget() {
    post_display_tmp="$(cat $RESPONSE_POSTDISPLAY_FILE)"

    buffer_tmp="$(cat $RESPONSE_BUFFER_FILE)"
    if [[ $post_display_tmp == "done" ]]; then

        # show suggested command
        BUFFER="${buffer_tmp}"

        # fixes syntax highlighting after buffer replaced:
        zle _zsh_highlight__zle-line-finish
        # NOTE: I did not verify if this is the right way to do this I just stumbled on this and it worked (found via `zle -la | grep highlight`)
        # w/o redoing highligths, the replaced buffer keeps previous highlights (i.e. first word is often red b/c first word of ? is not usually a valid command, plus highlighting wraps over POSTDISPLAY)

        # clear messages on success:
        POSTDISPLAY=""
        # obviates most of the need for clearing POSTDISPLAY on accept-line!

        # ? remove `` surrounding suggested command + show POSTDISPLAY warning that `` removed?
        # ? when might `` be necessary => i.e. `echo ls` (should just be ls)... can I modify system command / prompt to ask for simplified commands?

    else
        _set_post_display "${post_display_tmp}"
    fi

    zle reset-prompt # else POSTDISPLAY/BUFFER changes won't draw until keypress
}





zle -N restore_last_question_widget
bindkey -M emacs '^G' restore_last_question_widget # PRN better key to use?
function restore_last_question_widget(){
    # use ctrl+Z right after ask to revert buffer to question
    # but, when you then exec suggested command and want to modify the last question then use this to restore it!
    BUFFER=$last_question_asked
}

