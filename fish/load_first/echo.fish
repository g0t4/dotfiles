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
        apple_gray \
        -- $argv
    or return

    set -l style
    set -l color ""

    for c in (set_color --print-colors)
        if set -q _flag_$c
            set color $c
            # last color wins
        end
    end
    # FYI brX don't appear brighter
    #   TODO do I need to initialize colors in fish shell? (looks like maybe just brights aren't set to iterm2 bright settings?)

    for s in bold italic underline dim background reverse
        if set -q _flag_$s
            set style $style "--$s"
        end
    end

    # apple colors
    # https://developer.apple.com/design/human-interface-guidelines/color#iOS-iPadOS-system-colors
    # https://developer.apple.com/design/human-interface-guidelines/color#macOS-system-colors
    # using macOS colors below (FYI iOS differences are marked if the color differs)
    if set -q _flag_apple_red
        set color FF3B30
    end
    if set -q _flag_apple_orange
        set color FF9500
    end
    if set -q _flag_apple_yellow
        set color FFCC00
    end
    if set -q _flag_apple_green
        set color 28CD41
        # iOS: 34C759
    end
    if set -q _flag_apple_mint
        set color 00C7BE
    end
    if set -q _flag_apple_teal
        set color 59ADC4
        # iOS: 30B0C7
    end
    if set -q _flag_apple_cyan
        set color 55BEF0
        # iOS: 32ADE6
    end
    if set -q _flag_apple_blue
        set color 007AFF
    end
    if set -q _flag_apple_indigo
        set color 5856D6
    end
    if set -q _flag_apple_purple
        set color AF52DE
    end
    if set -q _flag_apple_pink
        set color FF2D55
    end
    if set -q _flag_apple_brown
        set color A2845E
    end
    if set -q _flag_apple_gray
        set color 8E8E93
        # iOS: doesn't have gray
    end

    set -l message $argv

    echo (eval "set_color $style $color") $message (set_color normal)
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
for a in apple_red apple_orange apple_yellow apple_green apple_mint apple_teal apple_cyan apple_blue apple_indigo apple_purple apple_pink apple_brown apple_gray
    complete -c log_ -l $a
end
