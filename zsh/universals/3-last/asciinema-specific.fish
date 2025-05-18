abbr anr 'asciinema rec --overwrite test.cast' # PRN remake in fish:    abbr --set-cursor --add anr 'asciinema rec --overwrite %.cast'
abbr anp 'asciinema play'
abbr anu 'asciinema upload'
abbr anc 'asciinema cat'

abbr aggo "agg --font-size 20 --font-family 'SauceCodePro Nerd Font' --theme 17181d,c7b168,555a6c,dc3d6f,9ed279,fae67f,469cd0,8b47e5,61d2b8,c229cf test.cast test.gif"

# NOTES about ROWS/COLUMNS:
# - check current size with: echo lines: $LINES cols: $COLUMNS
# ! *** prefer resize terminal before recording and asciinema will capture $ROWS $COLUMNS and just works on export then => dry run commands and see how they appear with constraints (ie upper left quarter of screen position window gives smaller window thats probably ideal for sharing a terminal gif recording)
#  *** OR `asciinema rec --rows X --cols Y...` works too though can be weird if smaller than actual terminal, esp if output would overflow the limits you place in --rows/--cols so best not to use this just set cols/rows by resizing window
#  IF YOU set agg's --cols/rows < actual cols/rows (in cast file) then you get a % and new lines in agg gif output

## agg
# PRN does agg support a config file? upon cursory inspection of repo I didn't see any documented nor in brief code review
#
# brew install agg
#
# config:
# --font-size 20+/--line-height
#   --font-dir/--font-family
#     mac:    --font-family 'SauceCodePro Nerd Font'
# --rows X / --cols Y
# --theme asciinema, dracula, monokai, solarized-dark, solarized-light, custom
# --speed 1.0
# --idle-time-limit 5.0 / --last-frame-delay 3.0
#   my terminal dark    --theme 17181d,c7b168,555a6c,dc3d6f,9ed279,fae67f,469cd0,8b47e5,61d2b8,c229cf
#
#
## asciicast2gif retired
#   https://github.com/asciinema/asciicast2gif
#   alias asciicast2gif='docker run --rm -v $PWD:/data asciinema/asciicast2gif'
#   successors:
#   - listed by asciicast2gif repo: https://github.com/asciinema/agg
#       nix! flake!
#   - copilot suggests: try ttygif?
