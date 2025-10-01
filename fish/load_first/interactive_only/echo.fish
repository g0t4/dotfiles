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


