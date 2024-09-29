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

# if not command -q bass
#   echo "installing bass"
#   fisher install edc/bass
# end

if not command -q osc

    echo "installing osc"
    if not command -q go
        set go_version 1.23.1
        wget https://go.dev/dl/go$go_version.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go$go_version.linux-amd64.tar.gz
        log_ --red LOGOUT/LOGIN to refresh PATH and then run install.fish again to complete osc install
    else
        # osc needs 1.21+ and toolchain 1.23
        go install -v github.com/theimpostor/osc@latest # 1.19 in bookworm :(
    end

end
