export LESS="-I -F -R $LESS"
# -I triggers case insensitive searching in less
# -F quit if less than one page of output
# -R raw control characters => ie ascii color codes (ie ESC[33m)
#
# less colors (i.e. to style man pages)
export LESS_TERMCAP_mb="$(echo -e '\e[1;32m')"
export LESS_TERMCAP_md="$(echo -e '\e[1;32m')"
export LESS_TERMCAP_me="$(echo -e '\e[0m')"
export LESS_TERMCAP_se="$(echo -e '\e[0m')"
#
# so == standout (search matches)
export LESS_TERMCAP_so="$(echo -e '\e[1;48;5;11;38;5;235m')" # terminal bg color for text, bg is yellow
# 1 == bold
#
# 8 bit colors:
#  48;5; => bg 256 color lookup => 11 == bright yellow (based on terminal theme)
#  38;5; => fg 256 color lookup => 235 (fixed black color)
#  - FYI 0-15 are standard 3/4 bit colors (defined in terminal theme)
#  - 16+ are hardcoded colors (see wikipedia:  https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit)
#
export LESS_TERMCAP_ue="$(echo -e '\e[0m')"
export LESS_TERMCAP_us="$(echo -e '\e[1;4;31m')"

#export LESS_TERMCAP_mr=$(tput rev)
#export LESS_TERMCAP_mh=$(tput dim)
#export LESS_TERMCAP_ZN=$(tput ssubm)
#export LESS_TERMCAP_ZV=$(tput rsubm)
#export LESS_TERMCAP_ZO=$(tput ssupm)
#export LESS_TERMCAP_ZW=$(tput rsupm)
#export GROFF_NO_SGR=1         # For Konsole and Gnome-terminal

export PAGER="less"

export WATCH_INTERVAL=0.5 # default to half second so I dont have to pass watch -n0.5!!!! # confirm by run watch cmd and see upper left what interval is
#  see `man watch`

#
# * env vars (without a different home)
[[ -z "$TERM" || "$TERM" = dumb ]] && TERM=xterm-256color
export EDITOR=nvim
export GREP_COLOR="1;38;5;162"
export RIPGREP_CONFIG_PATH="$WES_DOTFILES/.config/ripgrep/ripgreprc"
export DOCKER_HIDE_LEGACY_COMMANDS=1
export KUBECTL_EXTERNAL_DIFF="icdiff -r"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
# export NODE_OPTIONS=--disable-warning=ExperimentalWarning
# export ICDIFF_OPTIONS="--highlight"
# VAGRANT_BOX_UPDATE_CHECK_DISABLE=
# VAGRANT_EXPERIMENTAL=
# VAGRANT_PROVIDER=

# BTW HISTFILESIZE defaults to HISTSIZE (controls # entries in ~/.bash_history)
HISTSIZE=1000000
# set | rg -i HIST   # to review values

