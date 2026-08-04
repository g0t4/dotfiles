# ansible
pipx install --include-deps ansible
# --include-deps is for ansible-core to install ansible-* executables

# further executables:
pipx inject --include-apps ansible ansible-lint argcomplete

# libraries only:
pipx inject --include-apps ansible requests
# tomli-w

pipx install huggingface-hub
