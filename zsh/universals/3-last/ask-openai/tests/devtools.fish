#!/opt/homebrew/bin/fish

# STDIN==clipboard

set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
set -l _single_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/devtools.py"
#gdate "+%M:%S.%3N"

# echo "ask_service: " $ask_service

set response ( \
            echo "qs #idfoo" | \
            $_python3 $_single_py $ask_service 2>&1 \
        )

echo -e $response
#gdate "+%M:%S.%3N"
