
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


### Syntax COLORS ###
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

# FYI apple's macOS default dark colors: (see my log_ function for details)
set -l apple_red FF453A
set -l apple_orange ff9f0a
set -l apple_yellow ffd60a
set -l apple_green 32d74b
set -l apple_mint 66d4cf
set -l apple_teal 6ac4dc
set -l apple_cyan 5ac8f5
set -l apple_blue 0a84ff
set -l apple_indigo 5e5ce6
set -l apple_purple bf5af2
set -l apple_pink ff375f
set -l apple_brown ac8e68
set -l apple_gray 98989d

set fish_color_autosuggestion 555 brblack # default: 555 brblack
set fish_color_cancel -r # default: -r (reverse color)
set fish_color_command blue --bold # default: blue
set fish_color_comment brblack # default: red
set fish_color_cwd green # default: green
set fish_color_cwd_root red # default: red
set fish_color_end green # default: green
set fish_color_error brred --bold # default: brred
set fish_color_escape brcyan # default: brcyan
set fish_color_history_current --bold # default: --bold
set fish_color_host normal # default: normal
set fish_color_host_remote yellow # default: yellow
set fish_color_keyword blue # default: blue
set fish_color_match --background=brblue # default: --background=brblue
set fish_color_normal normal # default: normal
set fish_color_operator brcyan # default: brcyan
set fish_color_option cyan # default: cyan
set fish_color_param cyan # default: cyan
set fish_color_quote yellow # default: yellow
set fish_color_redirection cyan --bold # default: cyan --bold
set fish_color_search_match bryellow '--background=brblack' # default: bryellow '--background=brblack'
set fish_color_selection white --bold '--background=brblack' # default: white --bold '--background=brblack'
set fish_color_status red # default: red
set fish_color_user brgreen # default: brgreen
set fish_color_valid_path --underline # default: --underline
### Pager COLORS ###
# TBD fish_pager_color_*
set fish_pager_color_background # default: empty
set fish_pager_color_completion normal # default: normal
set fish_pager_color_description B3A06D yellow -i # default: B3A06D yellow -i
set fish_pager_color_prefix normal --bold --underline # default: normal --bold --underline
set fish_pager_color_progress brwhite '--background=cyan' # default: brwhite '--background=cyan'
set fish_pager_color_secondary_background # default: empty
set fish_pager_color_secondary_completion # default: empty
set fish_pager_color_secondary_description # default: empty
set fish_pager_color_secondary_prefix # default: empty
set fish_pager_color_selected_background -r # default: -r
set fish_pager_color_selected_completion # default: empty
set fish_pager_color_selected_description # default: empty
set fish_pager_color_selected_prefix # default: empty
