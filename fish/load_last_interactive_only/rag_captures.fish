# @fish-lsp-disable 4004

abbr --set-cursor nat "notes_about_trace '%'"
abbr --set-cursor notes_about_trace "notes_about_trace '%'"
function notes_about_trace
    echo $argv >README.md
    git add README.md
    git commit -m "$argv"
end

function love_fim
    notes_about_trace "FIM ❤️"
end

function love_rewrites
    notes_about_trace "Rewrites ❤️"
end

function love_agents
    notes_about_trace "Agents ❤️"
end

function love_shell
    notes_about_trace "Shell completions ❤️"
end

abbr -- nreadme "nvim README.md -c ':tabonly'" # FYI -c runs after first file + config loaded, necessary for tabonly to work here (close all other tabs)
# TODO setup fields in the NOTES.yml? copy from a template or prepopulate it?
#   TODO I could setup neovim helper to do the prepopulate (on-demand or automatically)
abbr -- nNOTES "nvim NOTES.yml -c ':tabonly'"

