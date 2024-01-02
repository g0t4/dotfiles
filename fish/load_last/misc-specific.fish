
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
# PRN only run once b/c its stored in universal variables? but I like versioning the values in config.fish files (and don't wanna try to version fish_variables), so for now set these on every startup
set fish_color_autosuggestion '555'  'brblack'
set fish_color_cancel -r
set fish_color_command blue
set fish_color_comment brblack # default: red
set fish_color_cwd green
set fish_color_cwd_root red
set fish_color_end green
set fish_color_error brred
set fish_color_escape brcyan
set fish_color_history_current --bold
set fish_color_host normal
set fish_color_host_remote yellow
set fish_color_keyword blue
set fish_color_match --background=brblue
set fish_color_normal normal
set fish_color_operator brcyan
set fish_color_option cyan
set fish_color_param cyan
set fish_color_quote yellow
set fish_color_redirection 'cyan'  '--bold'
set fish_color_search_match 'bryellow'  '--background=brblack'
set fish_color_selection 'white'  '--bold'  '--background=brblack'
set fish_color_status red
set fish_color_user brgreen
set fish_color_valid_path --underline
### Pager COLORS ###
# TBD fish_pager_color_*
set fish_pager_color_background
set fish_pager_color_completion normal
set fish_pager_color_description 'B3A06D'  'yellow'  '-i'
set fish_pager_color_prefix 'normal'  '--bold'  '--underline'
set fish_pager_color_progress 'brwhite'  '--background=cyan'
set fish_pager_color_secondary_background
set fish_pager_color_secondary_completion
set fish_pager_color_secondary_description
set fish_pager_color_secondary_prefix
set fish_pager_color_selected_background -r
set fish_pager_color_selected_completion
set fish_pager_color_selected_description
set fish_pager_color_selected_prefix


