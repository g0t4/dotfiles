
# PRN gattr helper:
# abbr gattr gitattributes_for
# function gitattributes_for
#     zsh -ic "gitattributes_for $argv"
# end

abbr gi gitignores_for
function gitignores_for
    zsh -ic "gitignores_for $argv"
end

abbr gia append_gitignores_for
function append_gitignores_for --wraps gitignores_for # --wraps => use completions from gi
    zsh -ic "append_gitignores_for $argv"
end

abbr gii gitignore_init
function gitignore_init
    zsh -ic "gitignore_init $argv"
end

abbr gic commit_gitignores_for
function commit_gitignores_for --wraps gitignores_for
    zsh -ic "commit_gitignores_for $argv"
end
