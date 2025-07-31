#!/usr/bin/env bash

original_file="$WES_DOTFILES/bash/.generated.aliases.bash"
pared_file="$WES_DOTFILES/bash/.generated.paredabbrs.bash"

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
    "'kubectl "
    "'minikube "
    "'k3d "
    "'ansible- "
    "'skopeo "
    "'helm "
    "'consul "
    "'packer "
    "'vagrant "
    "'terraform "
    "'string split "
    "'ssh "
    "'ollama "
    "'mitmproxy "
    "'llama-server "
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
    gsed -i "/${f}/d" "$pared_file"
done

echo
echo
echo FINAL SIZE:
wordcount "$pared_file"
