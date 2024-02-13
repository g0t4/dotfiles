
# modify delay to consider if esc key a seq or standalone
set fish_escape_delay_ms 200 # 30ms is default and way too fast (ie esc+k is almost impossible to trigger)

# PRN add a binding to clear screen + reset status of last run command
#    OR modify prompt (type fish_prompt) as it already distinguishes (with bold) if status was carried over from previous command so perhaps I could find a way to hijack that ? 
#    OR hide status in the prompt (perhaps like zsh I could show non-zero exit code on last line before new prompt?)


### FISH HELP ###
set __fish_help_dir "" # overwrite fish help dir thus forcing the use of https://fishshell.com instead of local files (which I prefer b/c I have highlighting of fishshell.com pages) # ... try it with: `help help` => opens https://fishshell.com/docs/3.6/interactive.html#help
# see `type help` to find the part of the help command that decides what to open 

### BINDINGS ###
# some of these might be a result of setting up iTerm2 to use xterm default keymapping (in profile), might need to adjust if key map is subsequently changed
bind -k sdc kill-word # shift+del to kill forward a word (otherwise its esc+d only), I have a habit of using this (not sure why, probably an old keymapping in zsh or?)


# *** systemctl (if avail)
if command -v systemctl >/dev/null

    eabbr sc 'sudo systemctl'
    eabbr scu 'sudo systemctl --user'

    eabbr scs 'sudo systemctl status'
    eabbr scstop 'sudo systemctl stop'
    eabbr scstart 'sudo systemctl start'
    eabbr screstart 'sudo systemctl restart'
    eabbr scenable 'sudo systemctl enable'
    eabbr scdisable 'sudo systemctl disable'
    eabbr sck 'sudo systemctl kill' # PRN --signal=SIGKILL?

    eabbr sccat 'sudo systemctl cat'
    eabbr scedit 'sudo systemctl edit'
    eabbr screvert 'sudo systemctl revert'
    eabbr scshow 'sudo systemctl show'

    eabbr scls 'sudo systemctl list-units'
    eabbr sclsf 'sudo systemctl list-unit-files'
    eabbr sclss 'sudo systemctl list-sockets'
    eabbr sclsd 'sudo systemctl list-dependencies'

    eabbr jc 'sudo journalctl -u'
    eabbr jcu 'sudo journalctl --user-unit'

    eabbr jcb 'sudo journalctl --boot -u' # current boot
    eabbr jcb1 'sudo journalctl --boot=-1 -u' # previous boot
    eabbr jcboots 'sudo journalctl --list-boots'

    eabbr jcs 'sudo journalctl --since "1min ago" -u'
    eabbr jck 'sudo journalctl -k' # kernel/dmesg

    eabbr jcf 'sudo journalctl --follow -u'
    eabbr jcfa 'sudo journalctl --follow --no-tail -u' # all lines + follow

    # WIP - figure out what I want for cleanup, when testing I often wanna just clear all logs and try some activity to simplify looking at journalctl history, hence jcnuke
    eabbr jcnuke 'sudo journalctl --rotate --vacuum-time=1s' # ~effectively rotate (archive all active journal files) then nuke (all archived journal files)
    eabbr jcr 'sudo journalctl --rotate' # rotate (archive) all active journal files (new journal files going forward)
    eabbr jcvs 'sudo journalctl --vacuum-size=100M' # vacuum logs to keep total size under 100M
    eabbr jcdu 'sudo journalctl --disk-usage' # total disk usage
end
