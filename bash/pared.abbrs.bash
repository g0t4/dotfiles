#!/usr/bin/env bash

original_file="$WES_DOTFILES/bash/.generated.aliases.bash"
pared_file="$WES_DOTFILES/bash/.generated.paredabbrs.bash"

cmd=sed
if [[ "$OSTYPE" == *darwin* ]]; then
    # gnu sed for this script
    cmd=gsed
    echo using gsed on mac
fi

cp "$original_file" "$pared_file"

# optin_filters=(
#     "'code"
#     "abbr -a -- common"
#     "'chmod "
#     "'cp "
#     'abbr -a -- curl_'
# )
# for f in "${filters[@]}"; do
#     sed -n "/${f}/p" "$file"
# done

deletes=(
    "'docker "
    "'hub-tool "
    "kubectl\b"
    "minikube\b"
    "k3d\b"
    "ansible-"
    "expand_zsh_equals"
    "skopeo\b"
    "helm\b"
    "'consul "
    "'packer "
    "vagrant\b"
    "terraform"
    "string split"
    "'ssh "
    "ollama"
    "mitmproxy"
    "llama-server"
    "'launchctl "
    "'dotnet "
    "'dotnet_shell"
    "'diff_dotnet"
    "'dotnet_version"
    "'cargo "
    "'brew "
)
# # * preview
# for f in "${deletes[@]}"; do
#     sed -n "/${f}/p" "$file"
# done

# * delete lines from pared file
for f in "${deletes[@]}"; do
    "$cmd" -i "/${f}/d" "$pared_file"
done

echo
echo
echo FINAL SIZE:
fish -c "wordcount '$pared_file'"
