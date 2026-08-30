#!/usr/bin/env xonsh

# * ansible
uv tool install \
    --with requests,tomli-w,docker \
    --with-executables-from ansible-core,ansible-lint,argcomplete,requests \
    ansible
# * pipx:
# pipx install --include-deps ansible # --include-deps is for ansible-core to install ansible-* executables
# pipx inject --include-apps ansible ansible-lint argcomplete
# pipx inject ansible requests tomli-w docker # etc

uv tool install huggingface-hub
uv tool install jina-cli
uv tool install rich-cli
uv tool install icdiff
uv tool install xonsh-lsp

# * previous pipx installs (not using AFAICT right now):
# uv tool install py-spy
# uv tool install pyrefly # PRN if switch
# uv tool install ty
# uv tool install cmakelang
