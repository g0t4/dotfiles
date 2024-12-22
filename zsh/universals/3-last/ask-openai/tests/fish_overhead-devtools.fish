#!/opt/homebrew/bin/fish

# STDIN==clipboard
# TEST WITH:
#    make sure set ask_use_* to match groq below or w/e you use below
#       FYI, --ollama is fastest b/c no security key lookup
#    hyperfine ./tests/fish_overhead-devtools.fish
#    first, comment out generate in suggest.py so we only count overhead before/after API call
#    the compare it to python directly:
#    hyperfine -- 'echo foo | python3 devtools.py --groq'



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
