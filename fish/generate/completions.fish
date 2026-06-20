#!/usr/bin/env fish

set argcomplete_commands \
    ansible-config \
    ansible-console \
    ansible-doc \
    ansible-galaxy \
    ansible-inventory \
    ansible-lint \
    ansible-playbook \
    ansible-pull \
    ansible-test \
    ansible-vault
# TODO any other tools that use argcomplete that I can add to this list?
#   not just applicable to ansible

for cmd in $argcomplete_commands
    register-python-argcomplete --shell fish $cmd > $WES_DOTFILES/fish/completions/$cmd.fish
end
