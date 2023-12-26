# FYI `set_color  --print-colors` to see actual colors

function log_info
    echo (set_color blue)"[INFO] $argv"(set_color normal)
end

function log_warn
    echo (set_color cyan)"[WARN] $argv"(set_color normal)
end

function log_error
    echo (set_color red)"[ERROR] $argv"(set_color normal)
end

function log_md
    echo $argv | bat --language Markdown --paging never --plain
end

function log_blankline
    echo ""
end

function log_header
    echo (set_color --bold yellow)"$argv"(set_color normal)
end



function log_ --description 'echo + set_color'

    # can completion use argparse specs (somehow share them?)
    # FYI argparse strips options so just message is left in $argv
    # FYI argparse also validates options (add -E to allow not defined options)
    argparse \
        # string join " " (set_color --print-colors) => copy/paste:
        # terminal color scheme:
        black blue cyan green magenta red white yellow \
        brblack brblue brcyan brgreen brmagenta brred brwhite bryellow \
        # styles:
        bold italic underline dim background reverse \
        # apple colors make a nice rainbow progression (look good too)
        apple_red apple_orange apple_yellow apple_green apple_mint apple_teal \
        apple_cyan apple_blue apple_indigo apple_purple apple_pink apple_brown \
        apple_gray apple_white \
        # troubleshoot
        print-colors \
        -- $argv
    or return
    if set -q _flag_print_colors
        # TODO I like this bold/yellow for headers!
        # TODO track indent in this logging framework or with another set of funcs?
        log_ --yellow --bold "terminal color scheme:"
        for c in black blue cyan green magenta red white yellow
            # FYI side by side makes it easier to see bright difference! it is subtle, so yes this is mapping to my iTerm2 colors (or win term)
            echo (set_color $c) "  $c "(set_color "br$c") "  br$c"(set_color normal)
        end


        log_blankline
        log_ --yellow --bold "apple colors:"
        for a in apple_red apple_orange apple_yellow apple_green apple_mint apple_teal apple_cyan apple_blue apple_indigo apple_purple apple_pink apple_brown apple_gray apple_white
            log_ --$a "  $a"
        end
        return
    end

    set -l style
    set -l color ""

    for c in (set_color --print-colors)
        if set -q _flag_$c
            set color $c
            # last color wins
        end
    end

    for s in bold italic underline dim background reverse
        if set -q _flag_$s
            set style $style "--$s"
        end
    end

    # apple colors
    # https://developer.apple.com/design/human-interface-guidelines/color#iOS-iPadOS-system-colors
    # https://developer.apple.com/design/human-interface-guidelines/color#macOS-system-colors
    # ok I am going to try accessible dark b/c its a bit less vibrant, but I still really like default light palette
    #   PRN try default dark palette
    #   PRN could add toggle for which subpallete to use! (would be nice to compare the colors in a table... in my copious free time)
    # FYI hex values are converted from RGB/int (apple.com site above) using chatgpt (it used python to convert so s/b good)
    # using macOS colors below (FYI iOS differences are marked if the color differs)
    if set -q _flag_apple_red
        # set color FF3B30 # default light
        # set color FF6961 # accessible dark
        set color FF453A # default dark
    end
    if set -q _flag_apple_orange
        # set color FF9500 # default light
        # set color FFB340 # accessible dark
        set color ff9f0a # default dark
    end
    if set -q _flag_apple_yellow
        # set color FFCC00 # default light
        # set color FFD426 # accessible dark
        set color ffd60a # default dark
    end
    if set -q _flag_apple_green
        # set color 28CD41 # default light
        # set color 31DE4B # accessible dark
        set color 32d74b # default dark
        # iOS: 34C759
    end
    if set -q _flag_apple_mint
        # set color 00C7BE # default light
        # set color 66D4CF # accessible dark
        set color 66d4cf # default dark
    end
    if set -q _flag_apple_teal
        # set color 59ADC4 # default light
        # set color 5DE6FF # accessible dark
        set color 6ac4dc # default dark
        # iOS: 30B0C7
    end
    if set -q _flag_apple_cyan
        # set color 55BEF0 # default light
        # set color 70D7FF # accessible dark
        set color 5ac8f5 # default dark
        # iOS: 32ADE6
    end
    if set -q _flag_apple_blue
        # set color 007AFF # default light
        # set color 409CFF # accessible dark
        set color 0a84ff # default dark
    end
    if set -q _flag_apple_indigo
        # set color 5856D6 # default light
        # set color 7D7AFF # accessible dark
        set color 5e5ce6 # default dark
    end
    if set -q _flag_apple_purple
        # set color AF52DE # default light
        # set color DA8FFF # accessible dark
        set color bf5af2 # default dark
    end
    if set -q _flag_apple_pink
        # set color FF2D55 # default light
        # set color FF6482 # accessible dark
        set color ff375f # default dark
    end
    if set -q _flag_apple_brown
        # set color A2845E # default light
        # set color B59469 # accessible dark
        set color ac8e68 # default dark
    end
    if set -q _flag_apple_gray
        # set color 8E8E93 # default light
        # set color 98989D # accessible dark
        set color 98989d # default dark
        # iOS: doesn't have gray
    end
    # PRN add grayscale colors: https://developer.apple.com/design/human-interface-guidelines/color#iOS-iPadOS-system-gray-colors
    if set -q _flag_apple_white
        # not a real white in the linked palette, I chose a light gray as a white since I was a genious in using magenta for white in my terminal color scheme :)... I should put that back... lol
        set color F2F2F7 # default light systemGray6
        # not using accessible dark cuz its dark gray
    end

    set -l message $argv

    echo (eval "set_color $style $color")$message(set_color normal)
end

# * completions
# - https://fishshell.com/docs/current/completions.html
# - https://fishshell.com/docs/current/cmds/complete.html
#
for c in (set_color --print-colors)
    complete -c log_ -l $c -d "set_color $c"
end
for s in bold italic underline dim background reverse
    complete -c log_ -l $s -d "set_color --$s"
end
for a in apple_red apple_orange apple_yellow apple_green apple_mint apple_teal apple_cyan apple_blue apple_indigo apple_purple apple_pink apple_brown apple_gray apple_white
    complete -c log_ -l $a
end
complete -c log_ -l print-colors -d "print all colors"
