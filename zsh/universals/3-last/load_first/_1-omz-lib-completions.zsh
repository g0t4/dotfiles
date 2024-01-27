#
# ***  most of the following comes from OMZ's lib/completion.zsh (with my mods)
# ! *** MUST BE post compinit (ALSO should be before my ealias library which overrides ^I/tab for example)

HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"


# provides menuselect keymap (bindkey):
zmodload -i zsh/complist

WORDCHARS=''

unsetopt menu_complete   # do not autoselect the first completion entry
unsetopt flowcontrol
setopt auto_menu         # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end

zstyle ':completion:*:*:*:*:*' menu select

# case insensitive (all), partial-word and substring completion
if [[ "$CASE_SENSITIVE" = true ]]; then
  zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
else
  if [[ "$HYPHEN_INSENSITIVE" = true ]]; then
    zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*'
  else
    zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
  fi
fi
unset CASE_SENSITIVE HYPHEN_INSENSITIVE

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

if [[ "$OSTYPE" = solaris* ]]; then
  zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm"
else
  zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm -w -w"
fi

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion:*' use-cache yes
# zstyle ':completion:*' cache-path $ZSH_CACHE_DIR # use default which is ~/.zcompcache

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
        clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
        gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
        ldap lp mail mailman mailnull man messagebus  mldonkey mysql nagios \
        named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
        operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
        rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
        usbmux uucp vcsa wwwrun xfs '_*'

# wes tinkering:
# add summary of matched items (types %d and counts %n) => more specific first, general after (for this style it seems first match wins)
#zstyle ':completion:*:aliases' format ' %F{yellow}-- %d -- %n' # %n = count, %d = description (ie alias)
#zstyle ':completion:*' format ' %F{blue}-- %d -- %n' # %n = count, %d = description (ie alias/function/external command/etc)
#zstyle ':completion:*:descriptions' format ' %F{blue}-- %d -- %n' # limit to descriptions tag (high level desc of matches)
#zstyle ':completion:*' group-name '' # group types!
# zstyle ':completion:*:messages' format ' %F{blue}-- %d -- %n' # %n = count, %d = description (ie alias/function/external command/etc)
# zstyle ':completion:*:warnings' format 'No matches for %d' # message to show when there is no match for all types searched => type bogus alias and TAB to test this
#
# zstyle ':completion:*' verbose yes # IIUC this is default true/yes
#
# FYI this guide is great for searching for a given word like 'auto-description' to see what it is about: https://zsh.sourceforge.io/Guide/zshguide06.html
#     and/or docs lookup: https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Completion-System

# ... unless we really want to.
zstyle '*' single-ignored show



# FYI I override ^I/tab in my ealias lib so I could just nuke this:
if [[ ${COMPLETION_WAITING_DOTS:-false} != false ]]; then
  expand-or-complete-with-dots() {
    # use $COMPLETION_WAITING_DOTS either as toggle or as the sequence to show
    [[ $COMPLETION_WAITING_DOTS = true ]] && COMPLETION_WAITING_DOTS="%F{red}…%f"
    # turn off line wrapping and print prompt-expanded "dot" sequence
    printf '\e[?7l%s\e[?7h' "${(%)COMPLETION_WAITING_DOTS}"
    zle expand-or-complete
    zle redisplay
  }
  zle -N expand-or-complete-with-dots
  # Set the function as the default tab completion widget
  bindkey -M emacs "^I" expand-or-complete-with-dots
  bindkey -M viins "^I" expand-or-complete-with-dots
  bindkey -M vicmd "^I" expand-or-complete-with-dots
fi

# automatically load bash completion functions
autoload -U +X bashcompinit && bashcompinit
