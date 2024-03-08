abbr vea 'source .venv*/bin/activate.fish' # override zsh version's /activate

# add function so this can be embedded in other abbr expansions
function vea --wraps=source
    source .venv*/bin/activate.fish
end
