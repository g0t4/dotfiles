abbr gi gitignores_for
function gitignores_for
    zsh -ic "gitignores_for $argv"
end

# --wraps => use completions from gi
abbr gic commit_gitignores_for
function commit_gitignores_for --wraps gitignores_for
    zsh -ic "commit_gitignores_for $argv"
end

abbr gia append_gitignores_for
function append_gitignores_for --wraps gitignores_for
    zsh -ic "append_gitignores_for $argv"
end
