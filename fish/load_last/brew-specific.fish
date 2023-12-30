
# PRN if other scripts need HOMEBREW_PREFIX then move this earlier in startup scripts
# if homebrew is present, add env vars/PATH
if test -f /opt/homebrew/bin/brew
    # apple silicon macs
    eval $(/opt/homebrew/bin/brew shellenv)
else if test -f /usr/local/bin/brew
    # intel macs
    eval $(/usr/local/bin/brew shellenv)
end
