
# modify delay to consider if esc key a seq or standalone
set fish_escape_delay_ms 200 # 30ms is default and way too fast (ie esc+k is almost impossible to trigger)

function kill_whole_line_and_copy
    # is there a better way to get last entry from kill ring instead of reading buffer (and trim newline) before kill?
    commandline -b | tr -d '\n' | fish_clipboard_copy
    commandline -f kill-whole-line
    # without copy to clipboard, have to use yank to paste removed line
end

bind \ek kill_whole_line_and_copy

# ctrl+c clear command line instead of cancel-commandline (why pollute terminal history to cancel a command!)
bind \cc 'commandline -r ""'

# PRN add a binding to clear screen + reset status of last run command
#    OR modify prompt (type fish_prompt) as it already distinguishes (with bold) if status was carried over from previous command so perhaps I could find a way to hijack that ? 
#    OR hide status in the prompt (perhaps like zsh I could show non-zero exit code on last line before new prompt?)


### FISH HELP ###
set __fish_help_dir "" # overwrite fish help dir thus forcing the use of https://fishshell.com instead of local files (which I prefer b/c I have highlighting of fishshell.com pages) # ... try it with: `help help` => opens https://fishshell.com/docs/3.6/interactive.html#help
# see `type help` to find the part of the help command that decides what to open 


### iTerm2 COLORS
# - FYI currently using '2023-08-03 wes dark colors - bg from 23252d to 17xxxx' if need to revert iterm2 changes
### fish syntax colors ###
# FYI https://color.adobe.com/create/color-wheel to pick colors
# - fish_config browse
#   fish_config theme show # preview all themes
#      theme files: share/fish/tools/web_config/themes/Seaweed.theme
# - revert to defaults:  fish_config theme choose "fish default"
# - dump current theme in a loadable format:   fish_config theme dump
# - FYI fish_color_* are universal vars (changes affect all shells)
#     stored in: ~/.config/fish/fish_variables
#     thus modifying one without specifying scope will result in persistent changes
#        redefine new var in a local scope to test changes in the current shell only
#           eg: set -l fish_color_normal green
#              set -le fish_color_normal # erases local scoped change
# - FYI each color variable holds arguments that you would pass to `set_color` (ie color + modifiers)
#   use smth like `type fish_greeting` or other builtin to get a good preview of a given color theme
# PRN only run once b/c its stored in universal variables? but I like versioning the values in config.fish files (and don't wanna try to version fish_variables), so for now set these on every startup
#
# color vars explained: https://fishshell.com/docs/current/interactive.html#syntax-highlighting-variables
set fish_color_normal normal # default: normal
set fish_color_autosuggestion 555 brblack # default: 555 brblack
set fish_color_cancel -r # default: -r (reverse color)
# cancel (\cc preset cancels current command so ^C shows w/ cancel color)
set fish_color_command blue --bold # default: blue
set fish_color_comment brblack # default: red
set fish_color_error brred --bold # default: brred
set fish_color_escape brcyan # default: brcyan
set fish_color_history_current --bold # default: --bold
set fish_color_keyword blue # default: blue
set fish_color_match --background=brblue # default: --background=brblue
set fish_color_option cyan # default: cyan
set fish_color_param cyan # default: cyan
set fish_color_quote yellow # default: yellow
set fish_color_search_match bryellow '--background=brblack' # default: bryellow '--background=brblack'
set fish_color_selection white --bold '--background=brblack' # default: white --bold '--background=brblack'
set fish_color_valid_path --underline # default: --underline
#
# various separators / redirects (all color coordinated currently):
set fish_color_end A37ACC --bold # default: green  # |(pipe), ;(semicolon)
set fish_color_operator A37ACC --bold # default: brcyan
set fish_color_redirection A37ACC --bold # default: cyan --bold # > /dev/null
### default prompts colors: (won't matter depending on how I override the prompt)
set fish_color_status red # default: red
set fish_color_cwd green # default: green
set fish_color_cwd_root red # default: red
set fish_color_user brgreen # default: brgreen
set fish_color_host normal # default: normal
set fish_color_host_remote yellow # default: yellow
#
### Pager COLORS ###
# TBD fish_pager_color_*
# primary => odd numbered unselected completions:
set fish_pager_color_background # default: empty
set fish_pager_color_completion normal # default: normal
set fish_pager_color_description B3A06D yellow -i # default: B3A06D yellow -i
set fish_pager_color_prefix normal --bold --underline # default: normal --bold --underline
# secondary => even numbered unselected completions:
set fish_pager_color_secondary_background # default: empty
set fish_pager_color_secondary_completion # default: empty
set fish_pager_color_secondary_description # default: empty
set fish_pager_color_secondary_prefix # default: empty # prefix = --/- dashes
# selected completion:
set fish_pager_color_selected_background -r # default: -r
set fish_pager_color_selected_completion # default: empty
set fish_pager_color_selected_description # default: empty
set fish_pager_color_selected_prefix # default: empty
# bottom bar summarizes # matches etc:
set fish_pager_color_progress brwhite '--background=cyan' # default: brwhite '--background=cyan'
#
### grep color ###
# default of red is fine too
if is_macos
    # macOS => Use GREP_COLOR (singular) only
    #   - cursory research shows macos grep doesn't use GREP_COLORS
    #       - only GREP_COLOR mentioned in man page
    #       - AND in testing only GREP_COLOR modified colors)
    #       - GREP_COLORS is used w/ GNU grep (ie ubuntu/WSL IIAC)
    #   - IIUC GREP_COLOR is only for matching text
    #       - whereas GREP_COLORS supports multi color style (matches, context, line#, setc)
    #   - use `set | grep -i  color_c` to test color choice:
    export GREP_COLOR='01;38;5;191' # bold + color 191 of 255
    # uses ANSI control sequences (SGR):
    #   font style:
    #       0 normal/reset, 1 bold, 2 dim, 3 italic, 4 underline, 7 inverse, 9 strike
    #       10 default font, 11-19 alt fonts
    #       21 double underline, 22 normal intensity, 23+ (remove bold/italic/etc)
    #   fg colors:
    #       30-37 # fg colors (3-bit)
    #          90-97 # bright fg colors (4-bit)
    #          # https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
    #       38;5;X # 256 color mode (X is 0-255)
    #           38;5;191 # color 191
    #           8-bit color: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
    #       39 # default fg color
    #   bg colors:
    #       40-47 # bg colors
    #           100-107 # bright bg colors
    #       48;5;X # 256 color mode (X is 0-255)
    #       49 # default bg color
    #   58 set underline color (8-bit) / 59 default underline color
    #       4;58;5;191' # only underline is color 191!
    #   combine with ;
    #       01;07 # bold + inverse
    #       01;38;5;191 # bold + color 191
    #           38;5;191;01 # same (order doesn't matter)
    #   SRG https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
    #   test entire color/style range:
    #     for i in (seq 1 107); export GREP_COLOR="$i"; echo $i; set | grep -i color_r; end;
end
