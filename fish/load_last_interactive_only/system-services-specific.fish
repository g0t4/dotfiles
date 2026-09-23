if not status is-interactive
    # *** this file is ALL interactive only modifications (especially command/func overrides, but also abbrs are useless to non-interactive)
    return
end

# function warn_if_abbr_exists --argument-names abbr_name \
#     --description "EXPENSIVE-ISH: precaution for abbrs that are likely to have overlap"
#     # TODO foooo this is broken for command scoped abbrs... that overlap but are for diff commands (or one is command scoped and another is global (not command))
#     # FYI not expensive if only doing this on a handful of abbrs...
#     #  but when you have 10K abbrs => 10K*24us => 240ms which is OUCH!
#     #
#     # TODO! contribute a setting $fish_warn_replace_abbr to do warn on replace (always) and then a --replace to squelch the warning?
#     #   TODO would need to be very low overhead OR enabled in some mode that dumps debug info only
#     if not abbr --query "$abbr_name"
#         return
#     end
#
#     log_ --apple_red "## WARNING $abbr_name already defined:"
#
#     # * show existing abbr (not fool proof due to need to pattern matching)
#     #  there is no way to lookup an abbr in fish, not currently...
#     #  that said they do show if you redefine, they show both definitions (not sure if that is new and/or intentional, I just noticed it)
#     # TODO! add `abbrs foo` like `functions foo` for fish-shell (lookup an abbr and show only its value)
#     abbr | rg --fixed-strings -- "-- $abbr_name"
#     abbr | rg --fixed-strings -- "-- '$abbr_name'" # if quoted, then will have '' around abbr
#     # FYI \-\- matches most (if not all abbrs that start with the pattern after):
#
# end
#
# function abbr_with_warn --argument-names abbr_name --description "MAKE SURE TO PASS abbreviated text first!!!"
#     # TODO make check efficient enough I can replace with all abbr usages?
#     warn_if_abbr_exists $abbr_name
#     abbr $argv
#
#     # usage:
#     #   abbr foo bar
#     #   abbr_with_warn foo bar  # warns since foo defined already
# end

# modify delay to consider if esc key a seq or standalone
set fish_escape_delay_ms 200 # 30ms is default and way too fast (ie esc+k is almost impossible to trigger)

# PRN add a binding to clear screen + reset status of last run command
#    OR modify prompt (type fish_prompt) as it already distinguishes (with bold) if status was carried over from previous command so perhaps I could find a way to hijack that ?
#    OR hide status in the prompt (perhaps like zsh I could show non-zero exit code on last line before new prompt?)

### FISH HELP ###
# `help<space>` expands to `help_online`, which opens fishshell.com/docs/current
# instead of the local (Homebrew) HTML docs — browser highlights/notes persist
# across fish upgrades. See fish/functions/help_online.fish.
abbr help help_online

### BINDINGS ###
# some of these might be a result of setting up iTerm2 to use xterm default keymapping (in profile), might need to adjust if key map is subsequently changed
# bind_both_modes_default_and_insert shift-delete kill-word # shift+del to kill forward a word (otherwise its esc+d only), I have a habit of using this (not sure why, probably an old keymapping in zsh or?)
#  dont wanna clobber new shift-delete in autosuggests... and I don't think I used shift-delete often for delete forward anyways
function on_change_show_verbose_prompt --on-variable show_verbose_prompt
    commandline --function repaint
end
function toggle_show_verbose_prompt
    if not set --query show_verbose_prompt
        set --universal show_verbose_prompt yes
    else
        set --universal --erase show_verbose_prompt
    end
    # commandline --function repaint
end
bind_both_modes_default_and_insert f4 toggle_show_verbose_prompt

if command -q launchctl
    abbr lcl 'launchctl list'
    abbr lcp 'launchctl print system'
    abbr lcpu 'launchctl print user/$(id -u)'
    abbr lcpg 'launchctl print gui/$(id -u)'
    abbr lcds 'launchctl disable system/'
    abbr lcdu 'launchctl disable user/$(id -u)'
    abbr lcdg 'launchctl disable gui/$(id -u)'
    # PRN lce (enable)
    abbr lcstart 'launchctl start TODO'
    abbr lcstop 'launchctl stop TODO'
    abbr lcrm 'launchctl remove TODO'
    #
    abbr lcexamine 'launchctl examine TODO'
    # blame
    # debug
    # attach # cool! (first set debug, then restart, then attach)
    #

    # TODO flesh out later
end

# *** systemctl (if avail)
if command -q systemctl

    # * sc == prefix for system services
    abbr sc 'sudo systemctl'
    # * scu == prefix for user services
    abbr scu 'systemctl --user'
    abbr scudr 'systemctl --user daemon-reload'
    abbr scdr "sudo systemctl daemon-reload"

    abbr scm 'man systemd.index' # great entrypoint to systemd man pages

    abbr scs 'sudo systemctl status'
    abbr scus 'systemctl --user status'
    abbr scstop 'sudo systemctl stop'
    abbr scustop 'systemctl --user stop'
    abbr scstart 'sudo systemctl start'
    abbr scustart 'systemctl --user start'
    abbr screstart 'sudo systemctl restart'
    abbr scurestart 'systemctl --user restart'
    abbr scenable 'sudo systemctl enable'
    abbr scuenable 'systemctl --user enable'
    abbr scdisable 'sudo systemctl disable'
    abbr scudisable 'systemctl --user disable'
    abbr sck 'sudo systemctl kill'
    abbr scukill 'systemctl --user kill'

    abbr sccat 'sudo systemctl cat'
    abbr scucat 'systemctl --user cat'
    abbr scedit 'sudo systemctl edit'
    abbr scuedit 'systemctl --user edit'
    abbr screvert 'sudo systemctl revert'
    abbr scurevert 'systemctl --user revert'
    abbr scshow 'sudo systemctl show'
    abbr scushow 'systemctl --user show'

    abbr scls 'sudo systemctl list-units'
    abbr sculs 'systemctl --user list-units'
    abbr sclsf 'sudo systemctl list-unit-files'
    abbr sculsf 'systemctl --user list-unit-files'
    abbr sclss 'sudo systemctl list-sockets'
    abbr sculss 'systemctl --user list-sockets'
    abbr sclsd 'sudo systemctl list-dependencies'
    abbr sculsd 'systemctl --user list-dependencies'

    # * jc == prefix for system services
    abbr jc 'sudo journalctl --unit'
    # * jcu == prefix for user services
    abbr jcu 'journalctl --user --unit'

    abbr jcb 'sudo journalctl --boot --unit' # current boot
    abbr jcub 'journalctl --user --boot --unit' # current boot
    abbr jcb1 'sudo journalctl --boot=-1 --unit' # previous boot
    abbr jcub1 'journalctl --user --boot=-1 --unit' # previous boot
    abbr jcboots 'sudo journalctl --list-boots'

    abbr jcs 'sudo journalctl --since "1min ago" --unit'
    abbr jcus 'journactl --user --since "1min ago" --unit'
    abbr jck 'sudo journalctl -k' # kernel/dmesg
    abbr jcuk 'journalctl --user -k'

    abbr jcf 'sudo journalctl --follow --unit'
    abbr jcuf 'journalctl --user --follow --unit'
    abbr jcfa 'sudo journalctl --follow --no-tail --unit' # all lines + follow
    abbr jcufa 'journalctl --user --follow --no-tail --unit' # all lines + follow

    # AFAICT I don't need user equivalentsof rotate/vacuum
    # WIP - figure out what I want for cleanup, when testing I often wanna just clear all logs and try some activity to simplify looking at journalctl history, hence jcnuke
    #
    # rotate (archive active journal files) then vacuum=delete=nuke (all archived journal files)
    abbr jc_rotate_vaccum 'sudo journalctl --rotate --vacuum-time=1s'
    abbr jc_nuke 'sudo journalctl --rotate --vacuum-time=1s' # see if I can internalize using nuke?
    #
    abbr jc_rotate_only 'sudo journalctl --rotate' # rotate (archive) all active journal files (uses new journal files going forward)
    abbr jcvs 'sudo journalctl --vacuum-size=100M' # vacuum logs to keep total size under 100M
    #
    abbr jcdu 'sudo journalctl --disk-usage' # total disk usage
    abbr jcud 'journalctl --user --disk-usage'
end

# *** containerd
if command -q ctr

    abbr ctr 'sudo ctr'
    abbr ctrn 'sudo ctr namespaces ls'

    # containers:
    abbr ctrc 'sudo ctr container ls'
    abbr ctrci 'sudo ctr container info'
    abbr ctrcrm 'sudo ctr container rm'

    # images:
    abbr ctri 'sudo ctr image ls'
    abbr ctripull --set-cursor 'sudo ctr image pull docker.io/library/%'
    abbr ctrirm --set-cursor 'sudo ctr image rm docker.io/library/%'

    # tasks:
    abbr ctrtls 'sudo ctr task ls'
    abbr ctrtps 'sudo ctr task ps' # by CID
    abbr ctrta 'sudo ctr task attach'
    abbr ctrtrm 'sudo ctr task rm'
    abbr ctrtk 'sudo ctr task kill --all'
    abbr ctrtks 'sudo ctr task kill --all --signal=SIGKILL'
    abbr ctrtpause 'sudo ctr task pause'
    abbr ctrtresume 'sudo ctr task resume'
    abbr ctrtstart 'sudo ctr task start' # created container that is not running
    abbr ctrtexec 'sudo ctr task exec --tty --exec-id 100 '

    # run:
    abbr ctrr 'sudo ctr run -t --rm'
    # demo examples:
    abbr ctrrnd 'sudo ctr run -d docker.io/library/nginx:latest web' # w/o host networking
    abbr ctrrn 'sudo ctr run -t --rm --net-host docker.io/library/nginx:latest web' # w/ host networking

    # content
    # leases
    # snapshots

    # *** containerd
    #  a few useful commands, just qualify them w.r.t. containerd full command name, rare but useful
    abbr containerdc "containerd config dump | bat -l toml"
    abbr containerdcdefault "containerd config default | bat -l toml"
    # PRN try new abbr --command option instead:   containerd c<TAB>  ???

end
