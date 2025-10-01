
### *** iTerm2 COLORS
# - FYI currently using '2023-08-03 wes dark colors - bg from 23252d to 17xxxx' if need to revert iterm2 changes
# => future, reconsider my iterm2 3/4 bit color scheme, i.e. white probably should be white and not magenta ;) (and magenta not purple?) but have to consider what all this affects

### *** fish syntax colors ###
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
# cancel (\cc preset cancels current command so ^C shows w/ cancel color)
set fish_color_history_current --bold # default: --bold
set fish_color_match --background=brblue # default: --background=brblue
#
# fish_color_search_match (background only - i.e. underline/bold don't work, default: bryellow '--background=brblack'), default is terrible b/c it makes the command impossible to read... can't help but wonder if I overrode default before realizing that... this default seems inane
# set fish_color_search_match -r # inverse for differentiating, looks good enough
set fish_color_search_match '' # don't differentiate... often I just wanna hit up arrow and not make it obvious that I used history completion, just messes up video recordings w/o really adding anything meaninful to viewers who don't care where the command came from
#
set fish_color_selection white --bold '--background=brblack' # default: white --bold '--background=brblack'
set fish_color_cancel -r # default: -r (reverse color)
#
### *** key commandline components (user input):
set fish_color_keyword green # default: blue # if followed by command so make the two different to stand out (but don't overly emphasize keywords)
set fish_color_error brred --bold # default: brred
set fish_color_command blue --bold # default: blue
set fish_color_option cyan --bold # default: cyan # -/--opt # make this stand out vs params? me thinks so
set fish_color_param cyan # default: cyan # arg1 arg2
set fish_color_quote yellow # default: yellow
set fish_color_valid_path --underline # default: --underline
set fish_color_comment brblack # default: red
#
# various separators / redirects (all color coordinated currently):
set fish_color_end A37ACC --bold # default: green  # |(pipe), ;(semicolon)
set fish_color_operator A37ACC --bold # default: brcyan
set fish_color_redirection A37ACC --bold # default: cyan --bold # > /dev/null
set fish_color_escape brcyan # default: brcyan
### *** fish default prompts colors: (won't matter depending on how I override the prompt)
set fish_color_status red # default: red
set fish_color_cwd green # default: green
set fish_color_cwd_root red # default: red
set fish_color_user brgreen # default: brgreen
set fish_color_host normal # default: normal
set fish_color_host_remote yellow # default: yellow
#
### *** fish pager colors (ie tab completion) ###
# TBD fish_pager_color_*
# primary => odd numbered unselected completions:
set fish_pager_color_background # default: empty
set fish_pager_color_completion normal # default: normal
set fish_pager_color_description brblack yellow -i # default: B3A06D yellow -i   # 2nd color (yellow) is the fallback color
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
set fish_pager_color_progress '000' '--background=brwhite' # default: brwhite '--background=cyan'
#
### *** ANSI COLOR CODES (ensure sync w/ color-specific.zsh)
function dump_8bit_colors
    # 8-bit lookup table: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
    for i in (seq 0 255)
        # 1 => bold to stand out
        echo -se "$i:\033[1;38;5;$i" "m foo \033[0m bar"
    end
end
set -g __color_bold 1
set -g __color_99 "38;5;99" # purple
set -g __color_162 "38;5;162" # hot pink (darker) works!
set -g __color_191 "38;5;191" # neon yellow/green
set -g __color_200 "38;5;200" # neon pink (bright)
set -g __color_matching_text "$__color_bold;$__color_162"

### *** wip LSCOLORS?
# if $IS_MACOS
#    set -gx LSCOLORS HfBxDxExCxGxgxaxbx
# end

### *** macOS GREP_COLOR
# default of red is fine too
if $IS_MACOS
    # macOS => Use GREP_COLOR (singular) only
    #   - cursory research shows macos grep doesn't use GREP_COLORS
    #       - only GREP_COLOR mentioned in man page
    #       - AND in testing only GREP_COLOR modified colors)
    #       - GREP_COLORS is used w/ GNU grep (ie ubuntu/WSL IIAC)
    #   - IIUC GREP_COLOR is only for matching text
    #       - whereas GREP_COLORS supports multi color style (matches, context, line#, setc)
    #   - use `set | grep -i  color_c` to test color choice:
    export GREP_COLOR="$__color_matching_text" # cannot defer expand color variable
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

# PRN GREP_COLORS (GNU grep)

### *** ag command
#   (search for `alias ag=`, currently in ag.zsh compat file)

### *** TODO next commands
