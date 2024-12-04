export LESS="-I -F -R $LESS"
# -I triggers case insensitive searching in less
# -F quit if less than one page of output
# -R raw control characters => ie ascii color codes (ie ESC[33m)
#
# less colors (i.e. to style man pages)
# TODO adjust to my liking
export LESS_TERMCAP_mb=(echo -e '\e[1;32m')
export LESS_TERMCAP_md=(echo -e '\e[1;32m')
export LESS_TERMCAP_me=(echo -e '\e[0m')
export LESS_TERMCAP_se=(echo -e '\e[0m')
export LESS_TERMCAP_so=(echo -e '\e[01;33m')
export LESS_TERMCAP_ue=(echo -e '\e[0m')
export LESS_TERMCAP_us=(echo -e '\e[1;4;31m')
# TODO others:? not sure these are needed:
#export LESS_TERMCAP_mr=$(tput rev)
#export LESS_TERMCAP_mh=$(tput dim)
#export LESS_TERMCAP_ZN=$(tput ssubm)
#export LESS_TERMCAP_ZV=$(tput rsubm)
#export LESS_TERMCAP_ZO=$(tput ssupm)
#export LESS_TERMCAP_ZW=$(tput rsupm)
#export GROFF_NO_SGR=1         # For Konsole and Gnome-terminal

export PAGER="less"

export WATCH_INTERVAL=0.5  # default to half second so I dont have to pass watch -n0.5!!!! # confirm by run watch cmd and see upper left what interval is
#  see `man watch`
