#!/usr/bin/env fish

# install fisher
# https://github.com/jorgebucaran/fisher
# PRN version fish_plugins (which fisher mentions as a way to share plugins, but it shows that as if fisher is already installed locally so lets do that w/o fish_plugins)
# if fisher function not avail then install fisher
if not functions -q fisher
    echo "installing fisher"
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
end

# install z
if not functions -q __z
    echo "installing z"
    fisher install jethrokuan/z
end

# fishtape
if not fisher list | grep -q jorgebucaran/fishtape
    echo "installing fishtape"
    fisher install jorgebucaran/fishtape
end

if not test -e ~/.config/fish/completions/gcloud.fish
    # clone repo, or update it
    wcl https://github.com/lgathy/google-cloud-sdk-fish-completion
    set repo_dir $HOME/repos/github/lgathy/google-cloud-sdk-fish-completion
    #cp -r functions ~/.config/fish/
    #cp -r completions ~/.config/fish/
    cp -r $repo_dir/functions ~/.config/fish/
    cp -r $repo_dir/completions ~/.config/fish/
end

# FYI didn't work for gcloud bash completion scripts...
# if not command -q bass
#   echo "installing bass"
#   fisher install edc/bass
# end

if not command -q osc

    echo "installing osc"
    if not command -q go
        set go_version 1.23.1
        # arm64/amd64
        set go_arch $(uname -m)
        if test $go_arch = aarch64
            set go_arch arm64
        else if test $go_arch = x86_64
            set go_arch amd64
        end
        set go_file go$go_version.linux-$go_arch.tar.gz
        wget https://go.dev/dl/$go_file
        sudo tar -C /usr/local -xzf $go_file
        log_ --red LOGOUT/LOGIN to refresh PATH and then run install.fish again to complete osc install
    else
        # TODO FIX => not working for bookworm12, compile fails on install
        # osc needs 1.21+ and toolchain 1.23
        go install -v github.com/theimpostor/osc@latest # 1.19 in bookworm :(
    end

end
