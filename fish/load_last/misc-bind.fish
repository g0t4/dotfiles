
# modify delay to consider if esc key a seq or standalone
set fish_escape_delay_ms 100 # 100 ms, 30ms is default and way too fast

bind \ek kill-whole-line
# PRN setup Esc+k to also copy to clipboard? IIRC I do that in zsh
# ! TODO port / review mybindings.plugin.zsh
