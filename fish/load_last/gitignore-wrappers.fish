function gi
    zsh -ic "gi $argv"
end

# --wraps => use completions from gi
function gic --wraps gi
    zsh -ic "gic $argv"
end

function gia --wraps gi
    zsh -ic "gia $argv"
end
